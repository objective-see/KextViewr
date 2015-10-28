//
//  InfoWindowController.m
//  KextViewr
//
//  Created by Patrick Wardle on 2/21/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "Consts.h"
#import "Utilities.h"
#import "InfoWindowController.h"

@interface InfoWindowController ()

@end

@implementation InfoWindowController

@synthesize kext;

//automatically invoked when window is loaded
// ->set to white
-(void)windowDidLoad
{
    //super
    [super windowDidLoad];
    
    //make white
    [self.window setBackgroundColor: NSColor.whiteColor];
    
    return;
}

//init method
// ->save kext and load nib
-(id)initWithKext:(id)selectedKext
{
    self = [super init];
    if(nil != self)
    {
        //load nib
        self.windowController = [[InfoWindowController alloc] initWithWindowNibName:@"InfoWindow"];
        
        //save item
        self.windowController.kext = selectedKext;
    }
        
    return self;
}

//automatically called when nib is loaded
// ->save self into iVar, and center window
-(void)awakeFromNib
{
    //configure UI
    [self configure];
    
    //center
    [self.window center];
}

//configure window
// ->add item's attributes (name, path, etc.)
-(void)configure
{
    //date formatter
    NSDateFormatter *dateFormatter = nil;
    
    //alloc date formatter
    dateFormatter = [[NSDateFormatter alloc] init];
    
    //set format
    [dateFormatter setDateFormat:@"MM-dd-yyyy HH:mm"];
    
    //set icon
    self.icon.image = self.kext.icon;
        
    //set name
    [self.name setStringValue:[self valueForStringItem:self.kext.name default:@"unknown"]];
    
    //flagged items
    // ->make name red!
    if( (nil != self.kext.vtInfo) &&
        (0 != [self.kext.vtInfo[VT_RESULTS_POSITIVES] unsignedIntegerValue]) )
    {
        //red
        self.name.textColor = [NSColor redColor];
    }
    
    //set path
    [self.path setStringValue:[self valueForStringItem:self.kext.path default:@"unknown"]];
    
    //set hash
    [self.hashes setStringValue:[NSString stringWithFormat:@"%@ / %@", self.kext.hashes[KEY_HASH_MD5], self.kext.hashes[KEY_HASH_SHA1]]];
    
    //set size
    [self.size setStringValue:[NSString stringWithFormat:@"%@ (%llu bytes)", [NSByteCountFormatter stringFromByteCount:self.kext.attributes.fileSize countStyle:NSByteCountFormatterCountStyleFile], self.kext.attributes.fileSize]];
    
    //set date
    [self.date setStringValue:[NSString stringWithFormat:@"%@ (created) / %@ (modified)", [dateFormatter stringFromDate:self.kext.attributes.fileCreationDate], [dateFormatter stringFromDate:self.kext.attributes.fileModificationDate]]];
    
    //set signing info
    [self.sign setStringValue:[self valueForStringItem:[self.kext formatSigningInfo] default:@"not signed"]];
    
    return;
}

                
//check if something is nil
// ->if so, return the default
-(NSString*)valueForStringItem:(NSString*)item default:(NSString*)defaultValue
{
    //return value
    NSString* value = nil;
    
    //check if item is nil/blank
    if( (nil != item) &&
        (item.length != 0))
    {
        //just set to item
        value = item;
    }
    else
    {
        //set to default
        value = defaultValue;
    }
    
    return value;
}

//automatically invoked when user clicks 'close'
// ->just close window
-(IBAction)closeWindow:(id)sender
{
    //close
    [self.window close];
}
@end
