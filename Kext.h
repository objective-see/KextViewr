//
//  File.h
//  KextViewr
//
//  Created by Patrick Wardle on 2/19/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface Kext : NSObject
{
    
}

/* PROPERTIES */

//name
@property(retain, nonatomic)NSString* name;

//path
@property(retain, nonatomic)NSString* path;

//file attributes
@property(nonatomic, retain)NSDictionary* attributes;

//bundle
@property(nonatomic, retain)NSBundle* bundle;

//icon
@property(nonatomic, retain)NSImage* icon;

//hashes (md5, sha1)
@property(nonatomic, retain)NSDictionary* hashes;

//signing info
@property(nonatomic, retain)NSDictionary* signingInfo;

//dictionary returned by VT
@property (nonatomic, retain)NSDictionary* vtInfo;


/* METHODS */

//init method
-(id)initWithName:(NSString*)name;

//get kexts name
// ->either from bundle or path's last component
-(NSString*)getName;

//set code signing image
// ->either signed, unsigned, or unknown
-(NSImage*)getCodeSigningIcon;

//format the signing info dictionary
-(NSString*)formatSigningInfo;

//convert self to JSON string
-(NSString*)toJSON;



@end
