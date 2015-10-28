//
//  VirusTotal.m
//  KnockKnock
//
//  Created by Patrick Wardle on 3/8/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "Kext.h"
#import "Consts.h"
#import "VirusTotal.h"
#import "AppDelegate.h"

@implementation VirusTotal

//thread function
// ->runs in the background to get virus total info for all kexts (25x at a time)
-(void)queryVT:(NSArray*)kexts
{
    //item data
    NSMutableDictionary* itemData = nil;
    
    //items
    NSMutableArray* items = nil;
    
    //VT query URL
    NSURL* queryURL = nil;
    
    //results
    NSDictionary* results = nil;
    
    //alloc list for items
    items = [NSMutableArray array];
    
    //init query URL
    queryURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", VT_QUERY_URL, VT_API_KEY]];
    
    //iterate over all hashes
    // ->create item dictionary (JSON), and add it to list
    for(Kext* kext in kexts)
    {
        //alloc item data
        itemData = [NSMutableDictionary dictionary];
        
        //bail if thread was cancelled
        // ->i.e. user pressed rescan
        if(YES == [[NSThread currentThread] isCancelled])
        {
            //bail
            goto bail;
        }
        
        //auto start location
        itemData[@"autostart_location"] = [[kext.bundle.bundlePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        
        //set item name
        itemData[@"autostart_entry"] = kext.name;
        
        //set item path
        itemData[@"image_path"] = kext.path;
        
        //set hash
        itemData[@"hash"] = kext.hashes[KEY_HASH_SHA1];
        
        //set creation times
        itemData[@"creation_datetime"] = [kext.attributes.fileCreationDate description];
        
        //add item info to list
        [items addObject:itemData];
        
        //less then 25 items
        // ->just keep collecting items
        if(VT_MAX_QUERY_COUNT != items.count)
        {
            //next
            continue;
        }
        
        //make query to VT
        results = [self postRequest:queryURL parameters:items];
        if(nil != results)
        {
            //process results
            [self processResults:kexts results:results];
        }
        
        //remove all items
        // ->since they've been processed
        [items removeAllObjects];
    }
    
    //process any remaining items
    if(0 != items.count)
    {
        //query virus total
        results = [self postRequest:queryURL parameters:items];
        if(nil != results)
        {
            //process results
            [self processResults:kexts results:results];
        }
    }
    
    
//bail
bail:
    
    return;
}

//get VT info for a single item
// ->will then callback into AppDelegate to reload item in UI
-(void)getInfoForItem:(Kext*)kext scanID:(NSString*)scanID
{
    //VT query URL
    NSURL* queryURL = nil;
    
    //results
    NSDictionary* results = nil;
    
    //init query URL
    queryURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?apikey=%@&resource=%@", VT_REQUERY_URL, VT_API_KEY, scanID]];
    
    //make queries until response is recieved
    while(YES)
    {
        //make query to VT
        results = [self postRequest:queryURL parameters:nil];
        
        //check if scan is complete
        if( (nil != results) &&
            (1 == [results[VT_RESULTS_RESPONSE] integerValue]) )
        {
            //save result
            kext.vtInfo = results;
            
            //reload row
            [((AppDelegate*)[[NSApplication sharedApplication] delegate]) reloadRow:kext];
            
            //exit loop
            break;
        }
        
        //nap
        [NSThread sleepForTimeInterval:60.0f];
    }
    
    return;
}

//make the (POST)query to VT
-(NSDictionary*)postRequest:(NSURL*)url parameters:(id)params
{
    //results
    NSDictionary* results = nil;
    
    //request
    NSMutableURLRequest *request = nil;
    
    //post data
    // ->JSON'd items
    NSData* postData = nil;
    
    //error var
    NSError* error = nil;
    
    //data from VT
    NSData* vtData = nil;
    
    //response (HTTP) from VT
    NSURLResponse* httpResponse = nil;

    //alloc/init request
    request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    //set user agent
    [request setValue:VT_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    
    //serialize JSON
    if(nil != params)
    {
        //convert items to JSON'd data for POST request
        // ->wrap since we are serializing JSON
        @try
        {
            //convert items
            postData = [NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:nil];
            if(nil == postData)
            {
                //err msg
                NSLog(@"OBJECTIVE-SEE ERROR: failed to convert request %@ to JSON", postData);
                
                //bail
                goto bail;
            }
            
        }
        //bail on exceptions
        @catch(NSException *exception)
        {
            //bail
            goto bail;
        }
        
        //set content type
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        //set content length
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postData length]] forHTTPHeaderField:@"Content-length"];
        
        //add POST data
        [request setHTTPBody:postData];
    }
    
    //set method type
    [request setHTTPMethod:@"POST"];
    
    //send request
    // ->synchronous, so will block
    vtData = [NSURLConnection sendSynchronousRequest:request returningResponse:&httpResponse error:&error];
    
    //sanity check(s)
    if( (nil == vtData) ||
        (nil != error) ||
        (200 != (long)[(NSHTTPURLResponse *)httpResponse statusCode]) )
    {
        //err msg
        NSLog(@"OBJECTIVE-SEE ERROR: failed to query VirusTotal (%@, %@)", error, httpResponse);
        
        //bail
        goto bail;
    }
    
    //serialize response into NSData obj
    // ->wrap since we are serializing JSON
    @try
    {
        //serialized
        results = [NSJSONSerialization JSONObjectWithData:vtData options:kNilOptions error:nil];
    }
    //bail on any exceptions
    @catch (NSException *exception)
    {
        //err msg
        NSLog(@"OBJECTIVE-SEE ERROR: converting response %@ to JSON threw %@", vtData, exception);
        
        //bail
        goto bail;
    }
    
    //sanity check
    if(nil == results)
    {
        //err msg
        NSLog(@"OBJECTIVE-SEE ERROR: failed to convert response %@ to JSON", vtData);
        
        //bail
        goto bail;
    }
    
//bail
bail:
    
    return results;
}

//submit a file to VT
-(NSDictionary*)submit:(Kext*)kext
{
    //results
    NSDictionary* results = nil;
    
    //submit URL
    NSURL* submitURL = nil;
    
    //request
    NSMutableURLRequest *request = nil;
    
    //body of request
    NSMutableData* body = nil;
    
    //file data
    NSData* fileContents = nil;
    
    //error var
    NSError* error = nil;
    
    //data from Vt
    NSData* vtData = nil;
    
    //response (HTTP) from VT
    NSURLResponse* httpResponse = nil;

    //init submit URL
    submitURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?apikey=%@&resource=%@", VT_SUBMIT_URL, VT_API_KEY, kext.hashes[KEY_HASH_MD5]]];
    
    //init request
    request = [[NSMutableURLRequest alloc] initWithURL:submitURL];
    
    //set boundary string
    NSString *boundary = @"qqqq___knockknock___qqqq";
    
    //set HTTP method (POST)
    [request setHTTPMethod:@"POST"];
    
    //set the HTTP header 'Content-type' to the boundary
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField: @"Content-Type"];
    
    //set HTTP header, 'User-Agent'
    [request setValue:VT_USER_AGENT forHTTPHeaderField:@"User-Agent"];

    //init body
    body = [NSMutableData data];
    
    //load file into memory
    fileContents = [NSData dataWithContentsOfFile:kext.path];
    
    //sanity check
    if(nil == fileContents)
    {
        //err msg
        NSLog(@"OBJECTIVE-SEE ERROR: failed to load %@ into memory for submission", kext.path);
        
        //bail
        goto bail;
    }
        
    //append boundary
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //append 'Content-Disposition' file name, etc
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", kext.name] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //append 'Content-Type'
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    //append file's contents
    [body appendData:fileContents];
    
    //append '\r\n'
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //append final boundary
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //set body
    [request setHTTPBody:body];
    
    //set content length
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-length"];

    //send request
    // ->synchronous, so will block
    vtData = [NSURLConnection sendSynchronousRequest:request returningResponse:&httpResponse error:&error];
    
    //sanity check(s)
    if( (nil == vtData) ||
        (nil != error) ||
        (200 != (long)[(NSHTTPURLResponse *)httpResponse statusCode]) )
    {
        //err msg
        NSLog(@"OBJECTIVE-SEE ERROR: failed to query VirusTotal (%@, %@)", error, httpResponse);
        
        //bail
        goto bail;
    }
    
    //serialize response into NSData obj
    // ->wrap since we are serializing JSON
    @try
    {
        //serialize
        results = [NSJSONSerialization JSONObjectWithData:vtData options:kNilOptions error:nil];
    }
    //bail on any exceptions
    @catch (NSException *exception)
    {
        //err msg
        NSLog(@"OBJECTIVE-SEE ERROR: converting response %@ to JSON threw %@", vtData, exception);
        
        //bail
        goto bail;
    }
    
    //sanity check
    if(nil == results)
    {
        //err msg
        NSLog(@"OBJECTIVE-SEE ERROR: failed to convert response %@ to JSON", vtData);
        
        //bail
        goto bail;
    }
    
//bail
bail:
    
    return results;
}

//submit a rescan request
-(NSDictionary*)reScan:(Kext*)fileObj
{
    //result data
    NSDictionary* result = nil;
    
    //scan url
    NSURL* reScanURL = nil;
    
    //init scan url
    reScanURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?apikey=%@&resource=%@", VT_RESCAN_URL, VT_API_KEY, fileObj.hashes[KEY_HASH_MD5]]];
    
    //make request to VT
    result = [self postRequest:reScanURL parameters:nil];
    if(nil == result)
    {
        //err msg
        NSLog(@"OBJECTIVE-SEE ERROR: failed to re-scan %@", fileObj.name);
        
        //bail
        goto bail;
    }

//bail
bail:
    
    return result;
}

//process results
// ->save VT info into each Kext obj
-(void)processResults:(NSArray*)items results:(NSDictionary*)results
{
    //process all results
    // ->save VT result dictionary into File obj
    for(NSDictionary* result in results[VT_RESULTS])
    {
        //sync
        // ->since array will be reset if user clicks 'refresh'
        @synchronized(items)
        {

        //find all items that match
        // ->might be dupes, which is fine
        for(Kext* item in items)
        {
            //for matches, save vt info
            if(YES == [result[@"hash"] isEqualToString:item.hashes[KEY_HASH_SHA1]])
            {
                //save
                item.vtInfo = result;
                
                //reload row
                [((AppDelegate*)[[NSApplication sharedApplication] delegate]) reloadRow:item];
        
            }
        }
            
        }//sync
    }
    
    return;
}

@end
