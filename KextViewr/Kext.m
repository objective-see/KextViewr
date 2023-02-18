//
//  File.m
//  KextViewr
//
//  Created by Patrick Wardle on 2/19/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "Kext.h"
#import "consts.h"
#import "utilities.h"
#import "AppDelegate.h"

#import <syslog.h>
#import <IOKit/Kext/KextManager.h>

@implementation Kext

@synthesize name;
@synthesize path;
@synthesize bundle;

//init method
-(id)init:(NSArray *)info collection:(NSUInteger)collection
{
    //bundle ID
    NSString* bundleID = nil;
    
    //bundle url
    CFURLRef bundleURL = nil;
    
    //super
    self = [super init];
    if(self)
    {
        //bundle id
        bundleID = info[6];
        
        //get url to bundle
        bundleURL = KextManagerCreateURLForBundleIdentifier(NULL, (__bridge CFStringRef)bundleID);
        if(nil == bundleURL)
        {
            //err msg
            syslog(LOG_ERR, "OBJECTIVE-SEE ERROR: could find bundle URL for %s", bundleID.UTF8String);
                
            //unset object
            self = nil;
            
            //bail
            goto bail;
        }
        
        //load bundle
        self.bundle = [NSBundle bundleWithURL:(__bridge NSURL * _Nonnull)(bundleURL)];
        if(nil == self.bundle)
        {
            //err msg
            syslog(LOG_ERR, "OBJECTIVE-SEE ERROR: could not load bundle for %s", bundleID.UTF8String);
            
            //unset object
            self = nil;
            
            //bail
            goto bail;
        }
    
        //extract bundle path
        self.path = self.bundle.bundlePath;
        if(nil == self.path)
        {
            //err msg
            syslog(LOG_ERR, "OBJECTIVE-SEE ERROR: could not get path for %s", self.bundle.description.UTF8String);
            
            //unset object
            self = nil;
            
            //bail
            goto bail;
        }
        
        //get name
        self.name = [self getName];
        
        //addr
        self.address = info[2];
        
        //size
        self.size = info[3];
        
        //arch
        self.architecture = info[5];
        
        //unknown? default to system
        if(YES == [self.architecture hasPrefix:@"????"])
        {
            //set to native
            self.architecture = getNativeArch();
        }
        
        //collection
        self.collection = collection;
        
        //collection name
        switch(self.collection)
        {
            //boot
            case BootCollection:
                self.collectionName = @"Boot";
                break;
            
            //system
            case SystemCollection:
                self.collectionName = @"System";
                break;
                
            //auxiliary
            case AuxiliaryCollection:
                self.collectionName = @"Auxiliary";
                break;
                
            default:
                self.collectionName = @"Unknown";
                break;
        }
        
        //cs icon
        switch(self.collection)
        {
            case BootCollection:
            case SystemCollection:
            {
                self.csIcon = [NSImage imageNamed:@"signedAppleIcon"];
                break;
            }
                
            case AuxiliaryCollection:
            {
                self.csIcon = [NSImage imageNamed:@"signed"];
                break;
            }
                
            default:
                self.csIcon = [NSImage imageNamed:@"unknown"];
                break;
        }
        
    }
    
//bail
bail:

    //release bundle URL
    if(nil != bundleURL)
    {
        //release
        CFRelease((CFStringRef)bundleURL);
    }
    
    return self;
}



//get kext's name
// either from 'CFBundleName', 'CFBundleExecutable', or path
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
    
    //when still nil
    // ->derive from path
    if(nil == kextName)
    {
        //save
        // ->but just file name
        kextName = [[self.path lastPathComponent] stringByDeletingPathExtension];
    }
    
    return kextName;
}

//convert self to JSON string
-(NSString*)toJSON
{
    //init json
    return [NSString stringWithFormat:@"\"name\": \"%@\", \"path\": \"%@\", \"collection\": \"%@\", \"address\": \"%@\", \"size\": \"%@\", \"architecture\": \"%@\"", self.name, self.path, self.collectionName, self.address, self.size, self.architecture];
}


@end
