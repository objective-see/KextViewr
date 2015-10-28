//
//  VTInfoWindow.h
//  KextViewr
//
//  Created by Patrick Wardle on 3/29/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

@class Kext;
@class HyperlinkTextField;

#import <Cocoa/Cocoa.h>

@interface VTInfoWindowController : NSWindowController
{
    
}

/* PROPERTIES */

//window controller
@property(nonatomic, strong)VTInfoWindowController *windowController;

//kext object
@property(nonatomic, retain)Kext* kext;


//properties in window
@property (weak) IBOutlet NSTextField *unknownFile;

@property (weak) IBOutlet NSTextField *fileNameLabel;
@property (weak) IBOutlet HyperlinkTextField *fileName;

@property (weak) IBOutlet NSTextField *detectionRatioLabel;
@property (weak) IBOutlet NSTextField *detectionRatio;

@property (weak) IBOutlet NSTextField *analysisURLLabel;
@property (weak) IBOutlet NSTextField *analysisURL;

@property (weak) IBOutlet NSButton *closeButton;

@property (weak) IBOutlet NSButton *submitButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSView *overlayView;
@property (weak) IBOutlet NSTextField *statusMsg;

/* METHODS */

//init method
// ->save item and load nib
-(id)initWithItem:(Kext*)binary;

//'submit' button handler
-(IBAction)vtButtonHandler:(id)sender;

//'close' button handler
-(IBAction)closeButtonHandler:(id)sender;


@end
