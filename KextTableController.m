//
//  ItemTableController.m
//  KextViewr
//
//  Created by Patrick Wardle on 2/18/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//
#import "Kext.h"
#import "Consts.h"
#import "VTButton.h"


#import "Utilities.h"
#import "AppDelegate.h"
#import "KextTableController.h"
#import "InfoWindowController.h"

#import "KKRow.h"
#import "kkRowCell.h"

#import <AppKit/AppKit.h>

@implementation KextTableController

@synthesize itemView;
@synthesize isFiltered;
@synthesize tableItems;
@synthesize selectedRow;
@synthesize isBottomPane;
@synthesize filteredItems;
@synthesize ignoreSelection;
@synthesize vtWindowController;
@synthesize infoWindowController;

@synthesize didInit;

-(void)awakeFromNib
{
    //single time init
    if(YES != self.didInit)
    {
        //init selected row
        self.selectedRow = 0;
        
        //alloc array for filtered items
        filteredItems = [NSMutableArray array];
        
        //set flag
        self.didInit = YES;
    }
    
    return;
}

//table delegate
// ->return number of rows, which is just number of items in the currently selected plugin
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    //rows
    NSUInteger rows = 0;
    
    //kexts
    OrderedDictionary* kexts = nil;
    
    //when not filtered
    // ->use all kexts
    if(YES != isFiltered)
    {
        //get kexts
        kexts = ((AppDelegate*)[[NSApplication sharedApplication] delegate]).kextEnumerator.kexts;
    
        //set count
        rows = kexts.count;
    }
    //when filtered
    // ->use filtered kexts
    else
    {
        //set count
        rows = self.filteredItems.count;
    }

    return rows;
    
}


//table delegate method
// ->return cell for row
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //kexts
    OrderedDictionary* kexts = nil;
    
    //item obj
    // ->contains data for view
    id item = nil;
    
    //row view
    NSView* rowView = nil;
    
    //when not filtered
    // ->use kexts
    if(YES != isFiltered)
    {
        //grab kexts
        kexts = ((AppDelegate*)[[NSApplication sharedApplication] delegate]).kextEnumerator.kexts;
        
        //sanity check
        // ->make sure there is table item for row
        if(kexts.count <= row)
        {
            //bail
            goto bail;
        }
        
        //get kext object
        // ->by index to get key, then by key
        item = kexts[[kexts keyAtIndex:row]];
    }
    
    //when filtered
    // ->use filtered items
    else
    {
        //sanity check
        // ->make sure there is table item for row
        if(self.filteredItems.count <= row)
        {
            //bail
            goto bail;
        }

        //get kext object
        item = self.filteredItems[row];
    }
    
    //create custom item view
    if(nil != item)
    {
        //create
        rowView = [self createRow:tableView kext:item];
    }
    
    return rowView;
    
    
//bail
bail:
    
    return nil;
}


//create/config row view
-(NSTableCellView*)createRow:(NSTableView*)tableView kext:(Kext*)kext
{
    //row cell
    NSTableCellView *rowCell = nil;
    
    //create cell
    rowCell = [tableView makeViewWithIdentifier:@"KextCell" owner:self];
    if(nil == rowCell)
    {
        //bail
        goto bail;
    }
    
    //brand new cells need tracking areas
    // ->determine if new, by checking default (.xib/IB) value
    if(YES == [rowCell.textField.stringValue isEqualToString:@"Kext Name"])
    {
        //add tracking area
        // ->'vt' button
        [self addTrackingArea:rowCell subViewTag:TABLE_ROW_VT_BUTTON];
        
        //add tracking area
        // ->'info' button
        [self addTrackingArea:rowCell subViewTag:TABLE_ROW_INFO_BUTTON];
        
        //add tracking area
        // ->'show' button
        [self addTrackingArea:rowCell subViewTag:TABLE_ROW_SHOW_BUTTON];
    }
    
    //set code signing icon
    ((NSImageView*)[rowCell viewWithTag:TABLE_ROW_SIGNATURE_ICON]).image = [kext getCodeSigningIcon];
    
    //default
    // ->(re)set main textfield's color to black
    rowCell.textField.textColor = [NSColor blackColor];
    
    //set main text
    // ->name
    [rowCell.textField setStringValue:[NSString stringWithFormat:@"%@ (%@)", kext.name, kext.bundle.bundleIdentifier]];
    
    //set path
    [[rowCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG] setStringValue:kext.path];
    
    //config VT button
    [self configVTButton:rowCell kext:kext];
    
    //set kext
    // ->allows lookup later...
    ((kkRowCell*)rowCell).item = kext;
    
//bail
bail:
    
    return rowCell;

}

//add a tracking area to a view within the item view
-(void)addTrackingArea:(NSTableCellView*)rowCell subViewTag:(NSUInteger)subviewTag
{
    //tracking area
    NSTrackingArea* trackingArea = nil;
    
    //alloc/init tracking area
    trackingArea = [[NSTrackingArea alloc] initWithRect:[[rowCell viewWithTag:subviewTag] bounds] options:(NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:@{@"tag":[NSNumber numberWithUnsignedInteger:subviewTag]}];
    
    //add tracking area to subview
    [[rowCell viewWithTag:subviewTag] addTrackingArea:trackingArea];
    
    return;
}


//configure the VT button
// ->also set's binary name to red if known malware
-(void)configVTButton:(NSTableCellView *)itemCell kext:(Kext*)kext
{
    //virus total button
    // ->for File objects only...
    VTButton* vtButton;
    
    //paragraph style
    NSMutableParagraphStyle *paragraphStyle = nil;
    
    //attribute dictionary
    NSMutableDictionary *stringAttributes = nil;
    
    //VT detection ratio as string
    NSString* vtDetectionRatio = nil;
    
    //grab virus total button
    vtButton = [itemCell viewWithTag:TABLE_ROW_VT_BUTTON];
    
    //configure/show VT info
    // ->only if 'disable' preference not set
    //if(YES != ((AppDelegate*)[[NSApplication sharedApplication] delegate]).prefsWindowController.disableVTQueries)
    //{
    //set button delegate
    vtButton.delegate = self;
    
    //save file obj
    vtButton.kext = kext;
    
    //check if have vt results
    if(nil != kext.vtInfo)
    {
        //set font
        [vtButton setFont:[NSFont fontWithName:@"Menlo-Bold" size:12]];
        
        //enable
        vtButton.enabled = YES;
        
        //got VT results
        // ->check 'permalink' to determine if file is known to VT
        //   then, show ratio and set to red if file is flagged
        if(nil != kext.vtInfo[VT_RESULTS_URL])
        {
            //alloc paragraph style
            paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            
            //center the text
            [paragraphStyle setAlignment:NSCenterTextAlignment];
            
            //alloc attributes dictionary
            stringAttributes = [NSMutableDictionary dictionary];
            
            //set underlined attribute
            stringAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
            
            //set alignment (center)
            stringAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
            
            //set font
            stringAttributes[NSFontAttributeName] = [NSFont fontWithName:@"Menlo-Bold" size:12];
            
            //compute detection ratio
            vtDetectionRatio = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)[kext.vtInfo[VT_RESULTS_POSITIVES] unsignedIntegerValue], (unsigned long)[kext.vtInfo[VT_RESULTS_TOTAL] unsignedIntegerValue]];
            
            //known 'good' files (0 positivies)
            if(0 == [kext.vtInfo[VT_RESULTS_POSITIVES] unsignedIntegerValue])
            {
                //(re)set title black
                itemCell.textField.textColor = [NSColor blackColor];
                
                //set color (black)
                stringAttributes[NSForegroundColorAttributeName] = [NSColor blackColor];
                
                //set string (vt ratio), with attributes
                [vtButton setAttributedTitle:[[NSAttributedString alloc] initWithString:vtDetectionRatio attributes:stringAttributes]];
                
                //set color (gray)
                stringAttributes[NSForegroundColorAttributeName] = [NSColor grayColor];
                
                //set selected text color
                [vtButton setAttributedAlternateTitle:[[NSAttributedString alloc] initWithString:vtDetectionRatio attributes:stringAttributes]];
            }
            //files flagged by VT
            // ->set name and detection to red
            else
            {
                //set title red
                itemCell.textField.textColor = [NSColor redColor];
                
                //set color (red)
                stringAttributes[NSForegroundColorAttributeName] = [NSColor redColor];
                
                //set string (vt ratio), with attributes
                [vtButton setAttributedTitle:[[NSAttributedString alloc] initWithString:vtDetectionRatio attributes:stringAttributes]];
                
                //set selected text color
                [vtButton setAttributedAlternateTitle:[[NSAttributedString alloc] initWithString:vtDetectionRatio attributes:stringAttributes]];
                
            }
            
            //enable
            [vtButton setEnabled:YES];
        }
        
        //file is not known
        // ->reset title to '?'
        else
        {
            //set title
            [vtButton setTitle:@"?"];
        }
    }
    
    //no VT results (e.g. unknown file)
    else
    {
        //set font
        [vtButton setFont:[NSFont fontWithName:@"Menlo-Bold" size:8]];
        
        //set title
        [vtButton setTitle:@"▪ ▪ ▪"];
        
        //disable
        vtButton.enabled = NO;
    }
    
    //show virus total button
    vtButton.hidden = NO;
    
    //show virus total label
    //[[itemCell viewWithTag:TABLE_ROW_VT_BUTTON+1] setHidden:NO];
    
    //}//show VT info (pref not disabled)
    
    /*
     //hide VT info
     else
     {
     //hide virus total button
     vtButton.hidden = YES;
     
     //hide virus total button label
     [[itemCell viewWithTag:TABLE_ROW_VT_BUTTON+1] setHidden:YES];
     }
     */
    
    return;
}

//automatically invoked
// ->create custom (sub-classed) NSTableRowView
-(NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    //row view
    KKRow* rowView = nil;
    
    //row ID
    static NSString* const kRowIdentifier = @"TableRowView";
    
    //try grab existing row view
    rowView = [tableView makeViewWithIdentifier:kRowIdentifier owner:self];
    
    //make new if needed
    if(nil == rowView)
    {
        //create new
        // ->size doesn't matter
        rowView = [[KKRow alloc] initWithFrame:NSZeroRect];
        
        //set row ID
        rowView.identifier = kRowIdentifier;
    }
    
    return rowView;
}


//automatically invoked when mouse entered
// ->highlight button
-(void)mouseEntered:(NSEvent*)theEvent
{
    //mouse entered
    // ->highlight (visual) state
    buttonAppearance(self.itemView, theEvent, NO);
    
    return;
}

//automatically invoked when mouse exits
// ->unhighlight/reset button
-(void)mouseExited:(NSEvent*)theEvent
{
    //mouse exited
    // ->so reset button to original (visual) state
    buttonAppearance(self.itemView, theEvent, YES);
    
    return;
}

//scroll back up to top of table
-(void)scrollToTop
{
    //scroll if more than 1 row
    if([self.itemView numberOfRows] > 0)
    {
        //top
        [self.itemView scrollRowToVisible:0];
    }
}

//reload table
-(void)reloadTable
{
    //reload table
    [self.itemView reloadData];
    
    //scroll to top
    [self scrollToTop];
    
    return;
}

//custom reload
// ->ensures selected row remains selected
-(void)refresh
{
    //kexts
    OrderedDictionary* kexts = nil;
    
    //selected kext
    Kext* selectedKext = nil;
    
    //filter string
    NSString* filterString = nil;
    
    //kext index after reload
    NSUInteger kextIndex = 0;
    
    //grab kexts
    kexts = ((AppDelegate*)[[NSApplication sharedApplication] delegate]).kextEnumerator.kexts;
    
    //make sure filter is updated
    if(YES == self.isFiltered)
    {
        //extract filter
        filterString = ((AppDelegate*)[[NSApplication sharedApplication] delegate]).filterKextsBox.stringValue;
        
        //sync
        @synchronized(self.filteredItems)
        {
            //filter
            [((AppDelegate*)[[NSApplication sharedApplication] delegate]).filterObj filterKexts:filterString items:kexts results:self.filteredItems];
        }
    }
    
    //get kext
    selectedKext = [self kextForRow:nil];
    
    //ignore selection change though
    self.ignoreSelection = YES;

    //always reload
    [self.itemView reloadData];
    
    //don't ignore selection
    self.ignoreSelection = NO;
    
    //when an item was selected
    // ->get its index and make sure that's still selected
    if(nil != selectedKext)
    {
        //get kext's index
        kextIndex = [kexts indexOfKey:selectedKext.name];
        
        //(re)select kext's row
        if(NSNotFound != kextIndex)
        {
            //begin updates
            [self.itemView beginUpdates];
            
            //(re)select
            [self.itemView selectRowIndexes:[NSIndexSet indexSetWithIndex:kextIndex] byExtendingSelection:NO];
            
            //end updates
            [self.itemView endUpdates];
        }
    }
    
    return;
}

//grab a kext at a row
-(Kext*)kextForRow:(id)sender
{
    //index of row
    NSInteger kextRow = 0;
    
    //selected row cell
    NSTableCellView* rowView = nil;
    
    //kexts
    OrderedDictionary* kexts = nil;
    
    //kext
    Kext* kext = nil;
    
    //grab kexts
    kexts = ((AppDelegate*)[[NSApplication sharedApplication] delegate]).kextEnumerator.kexts;
    
    //use sender if provided
    if(nil != sender)
    {
        //grab row
        kextRow = [self.itemView rowForView:sender];
    }
    //otherwise use selected row
    else
    {
        //grab row
        kextRow = [self.itemView selectedRow];
    }
    
    //sanity check(s)
    // ->make sure row is decent
    if( (-1 == kextRow) ||
        ((YES != self.isFiltered) && (kexts.count < kextRow)) ||
        ((YES == self.isFiltered) && (self.filteredItems.count < kextRow)) )
    {
        //bail
        goto bail;
    }
    
    //get row that's about to be selected
    rowView = [self.itemView viewAtColumn:0 row:kextRow makeIfNecessary:YES];
    
    //extract kext
    kext = ((kkRowCell*)rowView).item;
    
//bail
bail:
    
    return kext;
}

//automatically invoked when user clicks the 'show in finder' icon
// ->open Finder to show kext
-(IBAction)showInFinder:(id)sender
{
    //kext
    Kext* kext = nil;
    
    //file open error alert
    NSAlert* errorAlert = nil;
    
    //get kext
    kext = [self kextForRow:sender];
    
    //open item in Finder
    // ->error alert shown if file open fails
    if(YES != [[NSWorkspace sharedWorkspace] selectFile:kext.path inFileViewerRootedAtPath:@""])
    {
        //alloc/init alert
        errorAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"ERROR: failed to open %@", kext.path] defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"errno value: %d", errno];
        
        //show it
        [errorAlert runModal];
    }
    
    return;
}

//automatically invoked when user clicks the 'info' icon
// ->create/configure/display info window for kext
-(IBAction)showInfo:(id)sender
{
    //kext
    Kext* kext =  nil;
    
    //get kext
    kext = [self kextForRow:sender];
    
    //generate hashes the first time
    if(nil == kext.hashes[KEY_HASH_MD5])
    {
        //generate/save
        kext.hashes = hashFile(kext.path);
    }

    //alloc/init info window
    infoWindowController = [[InfoWindowController alloc] initWithKext:kext];
    
    //show it
    [self.infoWindowController.windowController showWindow:self];
    
    return;
}

//invoked when the user clicks 'virus total' icon
// ->launch browser and browse to virus total's page
-(void)showVTInfo:(id)sender
{
    //kext
    Kext* kext =  nil;
    
    //get kext
    kext = [self kextForRow:sender];

    //bail on nil items
    if(nil == kext)
    {
        //bail
        goto bail;
    }
    
    //alloc/init info window
    vtWindowController = [[VTInfoWindowController alloc] initWithItem:kext];
    
    //show it
    [self.vtWindowController.windowController showWindow:self];
    
    
//bail
bail:
    
    return;
}

@end
