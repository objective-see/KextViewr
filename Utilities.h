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

//check if OS is supported
BOOL isSupportedOS();

//get OS's major or minor version
SInt32 getVersion(OSType selector);

//hash (sha1/md5) a file
NSDictionary* hashFile(NSString* filePath);

//get the signing info of a file
NSDictionary* extractSigningInfo(NSString* path);

//get app's version
// ->extracted from Info.plist
NSString* getAppVersion();

//determine if a file is signed by Apple proper
BOOL isApple(NSString* path);

//convert a textview to a clickable hyperlink
void makeTextViewHyperlink(NSTextField* textField, NSURL* url);

//set the color of an attributed string
NSMutableAttributedString* setStringColor(NSAttributedString* string, NSColor* color);

//exec a process and grab it's output
NSData* execTask(NSString* binaryPath, NSArray* arguments);

//wait until a window is non nil
// ->then make it modal
void makeModal(NSWindowController* windowController);

//check if computer has network connection
BOOL isNetworkConnected();

//set or unset button's highlight
void buttonAppearance(NSTableView* table, NSEvent* event, BOOL shouldReset);


#endif
