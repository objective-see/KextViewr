//
//  File.h
//  KextViewr
//
//  Created by Patrick Wardle on 2/19/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//


#import <Foundation/Foundation.h>

//signers
enum Collection{BootCollection, SystemCollection, AuxiliaryCollection};


@interface Kext : NSObject
{
    
}

/* PROPERTIES */

//name
@property(retain, nonatomic)NSString* name;

//path
@property(retain, nonatomic)NSString* path;

//bundle
@property(nonatomic, retain)NSBundle* bundle;

//address
@property(nonatomic, retain)NSString* address;

//size
@property(nonatomic, retain)NSString* size;

//code signing icon
@property(nonatomic, retain)NSImage* csIcon;

//architecture
@property(nonatomic, retain)NSString* architecture;

//collection (type)
@property NSUInteger collection;

//collection name
@property(nonatomic, retain)NSString* collectionName;


/* METHODS */

//init
-(id)init:(NSArray *)info collection:(NSUInteger)collection;

//get name
-(NSString*)getName;

//convert self to JSON string
-(NSString*)toJSON;

@end
