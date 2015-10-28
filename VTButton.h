//
//  vtButton.h
//  KextViewr
//
//  Created by Patrick Wardle on 3/26/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "Kext.h"
#import <Cocoa/Cocoa.h>

//#import "ItemTableController.h"

@class KextTableController;

@interface VTButton : NSButton
{
    
}

//properties

//parent object
@property(assign)KextTableController *delegate;

//Kext object
@property(nonatomic, retain)Kext* kext;

//button's row index

//flag indicating press
@property BOOL mouseDown;

//flag indicating exit
@property BOOL mouseExit;



@end
