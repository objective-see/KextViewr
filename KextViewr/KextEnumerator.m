//
//  KextEnumerator.m
//  
//
//  Created by Patrick Wardle on 5/2/15.
//
//

#import <libproc.h>
#import <sys/proc_info.h>

#import "Kext.h"
#import "consts.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "KextEnumerator.h"

#import <syslog.h>
#import <signal.h>
#import <unistd.h>

@implementation KextEnumerator

@synthesize kexts;

//init
-(id)init
{
    //init super
    self = [super init];
    if(nil != self)
    {
        //init kexts dictionary/list
        kexts = [[OrderedDictionary alloc] init];
    }
    
    return self;
}


//enumerate all kexts
// calls back into app delegate to update table
-(void)enumerateKexts
{
    //results from 'kextstat' cmd
    NSString* output = nil;
    
    //base args
    NSArray* baseArgs = @[@"showloaded", @"--show-kernel", @"--list-only", @"--arch-info", @"-V", @"release", @"--collection"];
    
    //sync & reset
    @synchronized(self.kexts)
    {
        //reset
        [self.kexts removeAllObjects];
    }
    
    //get each kext collection
    for (enum Collection collection = BootCollection; collection <= AuxiliaryCollection; collection++)
    {
        //collection
        NSString* collectionName = 0;
        
        //boot?
        switch(collection)
        {
            case BootCollection:
                collectionName = @"boot";
                break;
                
            case SystemCollection:
                collectionName = @"sys";
                break;
                
            case AuxiliaryCollection:
                collectionName = @"aux";
                break;
        }
        
        //exec 'kmutil' to get loaded kexts
        // has the entitlement to enumerate kexts
        output = [[NSString alloc] initWithData:execTask(KM_UTIL, [baseArgs arrayByAddingObject:collectionName]) encoding:NSUTF8StringEncoding];
        if(nil == output)
        {
            //next
            continue;
        }
        
        //parse
        [self parse:output collection:collection];
    }
    
    //reload kext table
    // ensures all kexts are displayed
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        //reload
        [(AppDelegate*)NSApplication.sharedApplication.delegate reloadKextTable];
        
        //renable refresh button
        ((AppDelegate*)NSApplication.sharedApplication.delegate).refreshButton.enabled = YES;
        
        
    });
    
    return;
}

//parse output
// ...and init kext objects for each kext
-(void)parse:(NSString*)output collection:(NSUInteger)collection
{
    //iterate over all kexts
    // instantiate an object for each
    for(NSString* line in [output componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]])
    {
        //kext object
        Kext* kext = nil;
        
        //kext components
        NSArray* kextComponents = nil;
        
        //sanity check
        if(0 == line.length)
        {
            //skip
            continue;
        }

        //split on white spaces into array
        kextComponents = [[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
        
        //sanity check
        if(kextComponents.count < 6)
        {
            //err msg
            NSLog(@"OBJECTIVE-SEE ERROR: %@ -> %@, could not be parsed", line, kextComponents);
            
            //skip
            continue;
        }
    
        //create kext
        kext = [[Kext alloc] init:kextComponents collection:collection];
        if(nil == kext)
        {
            //skip
            continue;
        }
        
        //save it
        // key is kext name
        [self.kexts addObject:kext forKey:kext.name atStart:NO];
        
        //reload table every 5 kexts
        if(0 == self.kexts.count % 5)
        {
            //on main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                //reload kext table
                [((AppDelegate*)[[NSApplication sharedApplication] delegate]) reloadKextTable];
                
            });
        }
    
    }//all kexts
    
    
    return;
}

@end
