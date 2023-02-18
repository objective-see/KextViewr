//
//  Utilities.h
//  DHS
//
//  Created by Patrick Wardle on 2/7/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#ifndef DHS_Utilities_h
#define DHS_Utilities_h

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/* METHODS */

//get host architecture (as string)
NSString* getNativeArch(void);

//get app's version
// ->extracted from Info.plist
NSString* getAppVersion(void);

//determine if a file is signed by Apple proper
BOOL isApple(NSString* path);

//exec a process and grab it's output
NSData* execTask(NSString* binaryPath, NSArray* arguments);

//wait until a window is non nil
// ->then make it modal
void makeModal(NSWindowController* windowController);

//check if (full) dark mode
BOOL isDarkMode(void);

#endif
