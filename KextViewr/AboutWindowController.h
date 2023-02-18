//
//  PrefsWindowController.h
//  DHS
//
//  Created by Patrick Wardle on 2/6/15.
//  Copyright (c) 2015 Objective-See, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//support us button tag
#define BUTTON_SUPPORT_US 100

//more info button tag
#define BUTTON_MORE_INFO 101

@interface AboutWindowController : NSWindowController <NSWindowDelegate>
{
    
}

/* PROPERTIES */

//version label/string
@property (weak) IBOutlet NSTextField *versionLabel;

//patrons
@property (unsafe_unretained) IBOutlet NSTextView *patrons;

/* METHODS */

//automatically invoked when user clicks any of the buttons
// perform actions, such as loading patreon or products URL
-(IBAction)buttonHandler:(id)sender;

@end
