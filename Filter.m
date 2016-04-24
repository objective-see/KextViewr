//
//  Filter.m
//  KextViewr
//
//  Created by Patrick Wardle on 2/21/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//
#import "Kext.h"
#import "Consts.h"
#import "Filter.h"
#import "Utilities.h"


//binary filter keywords
NSString * const BINARY_KEYWORDS[] = {@"#apple", @"#nonapple", @"#signed", @"#unsigned", @"#flagged"};

@implementation Filter

@synthesize filterKeywords;

//init
-(id)init
{
    //init super
    self = [super init];
    if(nil != self)
    {
        //alloc binary filter keywords
        filterKeywords = [NSMutableArray array];

        //init binary filters
        for(NSUInteger i=0; i < sizeof(BINARY_KEYWORDS)/sizeof(BINARY_KEYWORDS[0]); i++)
        {
            //add
            [self.filterKeywords addObject:BINARY_KEYWORDS[i]];
        }
    }
    
    return self;
}

//determine if search string is #keyword
-(BOOL)isKeyword:(NSString*)searchString
{
    //for now just check in binary keywords
    return [self.filterKeywords containsObject:searchString];
}

//filter kexts
// ->name, path, & bundle id
-(void)filterKexts:(NSString*)filterText items:(NSMutableDictionary*)items results:(NSMutableArray*)results
{
    //kext
    Kext* kext = nil;
    
    //flag for keyword filter
    BOOL isKeyword = NO;
    
    //first reset filter'd items
    [results removeAllObjects];
    
    //set keyword flag
    // ->note: already checked its a full/matching keyword
    isKeyword = [filterText hasPrefix:@"#"];
    
    //sync
    @synchronized(items)
    {

    //iterate over all kexts
    for(NSString* key in items)
    {
        //extract kext
        kext = items[key];
        
        //handle keyword filtering
        if( (YES == isKeyword) &&
            (YES == [self kextFulfillsKeyword:filterText kext:kext]) )
        {
            //add
            [results addObject:kext];

        }//keywords
       
        //no keyword search
        else
        {
            //check path first
            // ->mostly likely to match
            if( (nil != kext.path) &&
                (NSNotFound != [kext.path rangeOfString:filterText options:NSCaseInsensitiveSearch].location) )
            {
                //save match
                [results addObject:kext];
                
                //next
                continue;
            }
            
            //check name
            if( (nil != kext.name) &&
                (NSNotFound != [kext.name rangeOfString:filterText options:NSCaseInsensitiveSearch].location) )
            {
                //save match
                [results addObject:kext];
                
                //next
                continue;
            }
            
            //check bundle id
            if( (nil != kext.bundle.bundleIdentifier) &&
                (NSNotFound != [kext.bundle.bundleIdentifier rangeOfString:filterText options:NSCaseInsensitiveSearch].location) )
            {
                //save match
                [results addObject:kext];
                
                //next
                continue;
            }
            
        }

    }//all kexts
    
    }//sync
        
    return;
}

//check if a binary fulfills a keyword
-(BOOL)kextFulfillsKeyword:(NSString*)keyword kext:(Kext*)kext
{
    //flag
    BOOL fulfills = NO;
    
    //handle '#apple'
    // ->signed by apple
    if( (YES == [keyword isEqualToString:@"#apple"]) &&
        (YES == [self isApple:kext]) )
    {
        //happy
        fulfills = YES;
        
        //bail
        goto bail;
    }
    
    //handle '#nonapple'
    // ->not signed by apple
    else if( (YES == [keyword isEqualToString:@"#nonapple"]) &&
             (YES != [self isApple:kext]) )
    {
        //happy
        fulfills = YES;
        
        //bail
        goto bail;
    }
    
    //handle '#signed'
    // ->signed
    else if( (YES == [keyword isEqualToString:@"#signed"]) &&
             (YES == [self isSigned:kext]) )
    {
        //happy
        fulfills = YES;
        
        //bail
        goto bail;
    }
    
    //handle '#unsigned'
    // ->not signed
    else if( (YES == [keyword isEqualToString:@"#unsigned"]) &&
             (YES != [self isSigned:kext]) )
    {
        //happy
        fulfills = YES;
        
        //bail
        goto bail;
    }
    
    //handle '#flagged'
    // ->flagged by VT
    else if( (YES == [keyword isEqualToString:@"#flagged"]) &&
             (YES == [self isFlagged:kext]) )
    {
        //happy
        fulfills = YES;
        
        //bail
        goto bail;
    }
    
//bail
bail:
    
    return fulfills;
}


//keyword filter '#apple' (and indirectly #nonapple)
// ->determine if binary is signed by apple
-(BOOL)isApple:(Kext*)item
{
    //flag
    BOOL isApple = NO;
    
    //check
    // ->just look at signing info
    if(YES == [item.signingInfo[KEY_SIGNING_IS_APPLE] boolValue])
    {
        //set flag
        isApple = YES;
    }
    
    return isApple;
}

//keyword filter '#signed' (and indirectly #unsigned)
// ->determine if binary is signed
-(BOOL)isSigned:(Kext*)item
{
    //flag
    BOOL isSigned = NO;
    
    //check
    // ->just look at signing info
    if(STATUS_SUCCESS == [item.signingInfo[KEY_SIGNATURE_STATUS] integerValue])
    {
        //set flag
        isSigned = YES;
    }
    
    return isSigned;
}

//keyword filter '#flagged'
// ->determine if binary is flagged by VT
-(BOOL)isFlagged:(Kext*)item
{
    //flag
    BOOL isFlagged = NO;
    
    //check
    // ->note: assumes that VT query has already completed...
    if( (nil != item.vtInfo) &&
        (0 != [item.vtInfo[VT_RESULTS_POSITIVES] unsignedIntegerValue]) )
    {
        //set flag
        isFlagged = YES;
    }
    
    return isFlagged;
}


@end
