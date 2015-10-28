//
//  File.m
//  KextViewr
//
//  Created by Patrick Wardle on 2/19/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//


#import "Kext.h"
#import "Consts.h"
#import "Utilities.h"
#import "AppDelegate.h"

#import <IOKit/Kext/KextManager.h>

@implementation Kext

@synthesize icon;
@synthesize name;
@synthesize path;
@synthesize bundle;
@synthesize hashes;
@synthesize vtInfo;
@synthesize signingInfo;

//init method
-(id)initWithName:(NSString *)bundleID
{
    //bundle url
    CFURLRef bundleURL = nil;
    
    //super
    self = [super init];
    if(self)
    {
        //get url to bundle
        bundleURL = KextManagerCreateURLForBundleIdentifier(NULL, (__bridge CFStringRef)bundleID);
        
        //load bundle and extract name/path
        if(nil != bundleURL)
        {
            //load bundle
            self.bundle = [NSBundle bundleWithURL:(__bridge NSURL * _Nonnull)(bundleURL)];
        
            //extract name/path
            if(nil != self.bundle)
            {
                //get name
                self.name = [self getName];
                
                //extract path
                self.path = [self.bundle.executableURL path];
            }
        }
        
        //set signing info
        self.signingInfo = extractSigningInfo(self.path);

        //grab attributes
        self.attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
        
        //set icon
        self.icon = [self getIcon];
    }

    //release bundle URL
    if(nil != bundleURL)
    {
        //release
        CFRelease((CFStringRef)bundleURL);
    }
    
    return self;
}

//get kext's name
// ->either from 'CFBundleName', or file name (via: 'CFBundleExecutable')
-(NSString*)getName
{
    //name
    NSString* kextName = nil;
    
    //save name
    // ->first check 'CFBundleName'
    if(nil != self.bundle.infoDictionary[@"CFBundleName"])
    {
        //save
        kextName = self.bundle.infoDictionary[@"CFBundleName"];
    }
    
    //some info dictionaries don't have 'CFBundleName'
    // ->use 'CFBundleExecutable'
    if(nil == kextName)
    {
        //save
        // ->but just file name
        kextName = [[self.bundle.infoDictionary[@"CFBundleExecutable"] lastPathComponent] stringByDeletingPathExtension];
    }
    
    return kextName;
}

//get an icon for a process
// ->for apps, this will be app's icon, otherwise just a standard system one
-(NSImage*)getIcon
{
    //icon's file name
    NSString* iconFile = nil;
    
    //icon's path
    NSString* iconPath = nil;
    
    //icon's path extension
    NSString* iconExtension = nil;
    
    //icon
    NSImage* kextIcon = nil;
    
    //for app's
    // ->extract their icon
    if(nil != self.bundle)
    {
        //get file
        iconFile = self.bundle.infoDictionary[@"CFBundleIconFile"];
        
        //get path extension
        iconExtension = [iconFile pathExtension];
        
        //if its blank (i.e. not specified)
        // ->go with 'icns'
        if(YES == [iconExtension isEqualTo:@""])
        {
            //set type
            iconExtension = @"icns";
        }
        
        //set full path
        iconPath = [self.bundle pathForResource:[iconFile stringByDeletingPathExtension] ofType:iconExtension];
        
        //load it
        kextIcon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    }
    
    //process is not an app or couldn't get icon
    // ->try to get it via shared workspace
    if( (nil == self.bundle) ||
        (nil == kextIcon) )
    {
        //extract icon
        kextIcon = [[NSWorkspace sharedWorkspace] iconForFile:self.path];
    }
    
    //'iconForFileType' returns small icons
    // ->so set size to 64
    [kextIcon setSize:NSMakeSize(64, 64)];
    
    return kextIcon;
}

//format the signing info dictionary
-(NSString*)formatSigningInfo
{
    //pretty print
    NSMutableString* prettyPrint = nil;
    
    //sanity check
    if(nil == self.signingInfo)
    {
        //bail
        goto bail;
    }
    
    //switch on signing status
    switch([self.signingInfo[KEY_SIGNATURE_STATUS] integerValue])
    {
        //unsigned
        case errSecCSUnsigned:
        {
            //set string
            prettyPrint = [NSMutableString stringWithString:@"unsigned"];
            
            //brk
            break;
        }
            
        //errSecCSSignatureFailed
        case errSecCSSignatureFailed:
        {
            //set string
            prettyPrint = [NSMutableString stringWithString:@"invalid signature"];
            
            //brk
            break;
        }
            
        //happily signed
        case STATUS_SUCCESS:
        {
            //init
            prettyPrint = [NSMutableString string];//stringWithString:@"signed by:"];
            
            //add each signing auth
            for(NSString* signingAuthority in self.signingInfo[KEY_SIGNING_AUTHORITIES])
            {
                //append
                [prettyPrint appendString:[NSString stringWithFormat:@"%@, ", signingAuthority]];
            }
            
            //remove last comma & space
            if(YES == [prettyPrint hasSuffix:@", "])
            {
                //remove
                [prettyPrint deleteCharactersInRange:NSMakeRange([prettyPrint length]-2, 2)];
            }
            
            //brk
            break;
        }
            
        //unknown
        default:
            
            //set string
            prettyPrint = [NSMutableString stringWithFormat:@"unknown (status/error: %ld)", (long)[self.signingInfo[KEY_SIGNATURE_STATUS] integerValue]];
            
            //brk
            break;
    }
    
//bail
bail:
    
    return prettyPrint;
}

//set code signing image
// ->either signed, unsigned, or unknown
-(NSImage*)getCodeSigningIcon
{
    //signature image
    NSImage* codeSignIcon = nil;
    
    //set signature status icon
    if(nil != self.signingInfo)
    {
        //binary is signed by apple
        if(YES == [self.signingInfo[KEY_SIGNING_IS_APPLE] boolValue])
        {
            //set
            codeSignIcon = [NSImage imageNamed:@"signedAppleIcon"];
        }
        
        //binary is signed
        else if(STATUS_SUCCESS == [self.signingInfo[KEY_SIGNATURE_STATUS] integerValue])
        {
            //set
            codeSignIcon = [NSImage imageNamed:@"signed"];
        }
        
        //binary not signed
        else if(errSecCSUnsigned == [self.signingInfo[KEY_SIGNATURE_STATUS] integerValue])
        {
            //set
            codeSignIcon = [NSImage imageNamed:@"unsigned"];
        }
        
        //unknown
        else
        {
            //set
            codeSignIcon = [NSImage imageNamed:@"unknown"];
        }
    }
    //signing info is nil
    // ->just to unknown
    else
    {
        //set
        codeSignIcon = [NSImage imageNamed:@"unknown"];
    }
    
    return codeSignIcon;
}


//convert self to JSON string
-(NSString*)toJSON
{
    //json string
    NSString *json = nil;
    
    //json data
    // ->for intermediate conversions
    NSData *jsonData = nil;
    
    //hashes
    NSString* fileHashes = nil;
    
    //signing info
    NSString* fileSigs = nil;
    
    //VT detection ratio
    NSString* vtDetectionRatio = nil;
    
    //init file hash to default string
    // ->used when hashes are nil, or serialization fails
    fileHashes = @"\"unknown\"";
    
    //init file signature to default string
    // ->used when signatures are nil, or serialization fails
    fileSigs = @"\"unknown\"";
    
    //convert hashes to JSON
    if(nil != self.hashes)
    {
        //convert hash dictionary
        // ->wrap since we are serializing JSON
        @try
        {
            //convert
            jsonData = [NSJSONSerialization dataWithJSONObject:self.hashes options:kNilOptions error:NULL];
            if(nil != jsonData)
            {
                //convert data to string
                fileHashes = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        }
        //ignore exceptions
        // ->file hashes will just be 'unknown'
        @catch(NSException *exception)
        {
            ;
        }
    }
    
    //convert signing dictionary to JSON
    if(nil != self.signingInfo)
    {
        //convert signing dictionary
        // ->wrap since we are serializing JSON
        @try
        {
            //convert
            jsonData = [NSJSONSerialization dataWithJSONObject:self.signingInfo options:kNilOptions error:NULL];
            if(nil != jsonData)
            {
                //convert data to string
                fileSigs = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        }
        //ignore exceptions
        // ->file sigs will just be 'unknown'
        @catch(NSException *exception)
        {
            ;
        }
    }
    
    //init VT detection ratio
    vtDetectionRatio = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)[self.vtInfo[VT_RESULTS_POSITIVES] unsignedIntegerValue], (unsigned long)[self.vtInfo[VT_RESULTS_TOTAL] unsignedIntegerValue]];
    
    //init json
    json = [NSString stringWithFormat:@"\"name\": \"%@\", \"path\": \"%@\", \"hashes\": %@, \"signature(s)\": %@, \"VT detection\": \"%@\"", self.name, self.path, fileHashes, fileSigs, vtDetectionRatio];
    
    return json;
}


@end
