//
//  Filter.h
//  KextViewer
//
//  Created by Patrick Wardle on 2/21/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "Kext.h"


#import <Foundation/Foundation.h>

@interface Filter : NSObject
{
    
}

/* METHODS */

//determine if search string is #keyword
-(BOOL)isKeyword:(NSString*)searchString;

//check if a kext fulfills a keyword
-(BOOL)kextFulfillsKeyword:(NSString*)keyword kext:(Kext*)kext;

//keyword filter '#apple'
// ->determine if kext is signed by apple
-(BOOL)isApple:(Kext*)item;

//filter kexts
// ->name/path/#keyword
-(void)filterKexts:(NSString*)filterText items:(NSMutableDictionary*)items results:(NSMutableArray*)results;


/* PROPERTIES */

//filter keywords
@property(nonatomic, retain)NSMutableArray* filterKeywords;

@end
