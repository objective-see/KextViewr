//
//  AppDelegate.h
//  KextViewr
//
//  Created by Patrick Wardle
//  Copyright (c) 2015 Objective-See. All rights reserved.
//
#import "Filter.h"
#import "VirusTotal.h"
#import "KextEnumerator.h"
#import "CustomTextField.h"
#import "KextTableController.h"
#import "AboutWindowController.h"

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>
{

}

//start time
@property NSTimeInterval startTime;

//connection flag
@property BOOL isConnected;

//'filter kext' search box
// ->top pane
@property (weak) IBOutlet NSSearchField *filterKextsBox;

//kext enumerator object
@property(nonatomic, retain)KextEnumerator* kextEnumerator;

//kext table controller object
@property (weak) IBOutlet KextTableController *kextTableController;

//button to toggle on/off showing OS kexts
@property (weak) IBOutlet NSButton *showOSKexts;

//main window
@property (assign) IBOutlet NSWindow *window;

//logo button
@property (weak) IBOutlet NSButton *logoButton;

//filter object
@property(nonatomic, retain)Filter* filterObj;

//about window controller
@property(nonatomic, retain)AboutWindowController* aboutWindowController;

//refresh button
@property (weak) IBOutlet NSButton *refreshButton;

//save button
@property (weak) IBOutlet NSButton *saveButton;

//flag for filter field (autocomplete)
@property BOOL completePosting;

//flag for filter field (autocomplete)
@property BOOL commandHandling;

//custom search field for kexts
@property(nonatomic, retain)CustomTextField* kextFilterView;

//enumerator thread
@property(nonatomic, retain)NSThread *kextEnumThread;

/* METHODS */

//complete a few inits
// ->then invoke helper method to start enum'ing kexts (in bg thread)
-(void)go;

//init tracking areas for buttons
// ->provide mouse over effects
-(void)initTrackingAreas;

//action for 'refresh' button
// ->query OS to refresh/reload all kexts
-(IBAction)refreshKexts:(id)sender;

//button handler for logo
-(IBAction)logoButtonHandler:(id)sender;

//action for 'about' in menu/logo in UI
-(IBAction)about:(id)sender;

//reload (to re-draw) a specific row in table
-(void)reloadRow:(id)item;

//reload kext table
-(void)reloadKextTable;

//filter for excluding OS kexts checkbox
-(void)filterAppleKexts;

//save button handler
-(IBAction)saveResults:(id)sender;

//callback for custom search fields
// ->handle auto-complete filterings
-(void)filterAutoComplete:(NSTextView*)textField;

//code to complete filtering/search
// ->reload table/scroll to top etc
-(void)finalizeFiltration;

@end
