//
//  ItemTableController.m
//  KextViewr
//
//  Created by Patrick Wardle on 2/18/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//
#import "Kext.h"
#import "consts.h"

#import "utilities.h"
#import "AppDelegate.h"
#import "KextTableController.h"

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

-(void)awakeFromNib
{
    //once
    static dispatch_once_t once = 0;
    
    dispatch_once (&once, ^{
        
        //init selected row
        self.selectedRow = 0;
        
        //alloc array for filtered items
        self.filteredItems = [NSMutableArray array];
        
        //pre-req for color of overlay
        self.overlay.wantsLayer = YES;
        
        //round overlay's corners
        self.overlay.layer.cornerRadius = 20.0;
        
        //mask overlay
        self.overlay.layer.masksToBounds = YES;
        
        //set overlay's view color to gray
        self.overlay.layer.backgroundColor = NSColor.lightGrayColor.CGColor;
        
        //show/activate
        [self showOverlay];
        
        //table resizing settings
        [self.itemView sizeLastColumnToFit];
    
    });
    
    return;
}

//show overlay
-(void)showOverlay
{
    //(re)set alpha
    self.overlay.alphaValue = 1.0f;
    
    //show overlay
    self.overlay.hidden = NO;
    
    //show activity indicator
    self.activityIndicator.hidden = NO;
    
    //start activity indicator
    [self.activityIndicator startAnimation:nil];
    
    return;
    
}

//hide overlay
-(void)hideOverlay
{
    //begin grouping
    [NSAnimationContext beginGrouping];
    
    //set duration
    [[NSAnimationContext currentContext] setDuration:1.0];
    
    //fade out
    [[self.overlay animator] setAlphaValue:0.0];
    
    //end grouping
    [NSAnimationContext endGrouping];
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
        rowView = [self createRow:tableView column:tableColumn kext:item];
    }
    
    return rowView;
    
    
bail:
    
    return nil;
}


//create/config row view
-(NSTableCellView*)createRow:(NSTableView*)tableView column:(NSTableColumn*)column kext:(Kext*)kext
{
    //row cell
    NSTableCellView* cell = nil;
    
    //create detailed cell
    if(column == tableView.tableColumns[0])
    {
        //init
        cell = [tableView makeViewWithIdentifier:@"kextCell" owner:self];
        
        //set code signing icon
        ((NSImageView*)[cell viewWithTag:TABLE_ROW_SIGNATURE_ICON]).image = kext.csIcon;
        
        //set main text (name)
        cell.textField.stringValue = [NSString stringWithFormat:@"%@ (%@)", kext.name, kext.bundle.bundleIdentifier];
        
        //set path
        [[cell viewWithTag:TABLE_ROW_SUB_TEXT_TAG] setStringValue:kext.path];
        
        //set kext
        // allows lookup later...
        ((kkRowCell*)cell).item = kext;
    }
    else
    {
        //init
        cell = [tableView makeViewWithIdentifier:@"simpleCell" owner:self];
        
        //TODO: nil check!
        
        //collection
        if(column == tableView.tableColumns[1])
        {
            //set
            ((NSTableCellView*)cell).textField.stringValue = kext.collectionName;
        }
        
        //address
        if(column == tableView.tableColumns[2])
        {
            //kernel proper? (addr: 0)
            if(YES == [kext.address isEqualToString:@"0"])
            {
                ((NSTableCellView*)cell).textField.stringValue = @"0 (Kernel)";
            }
            else
            {
                ((NSTableCellView*)cell).textField.stringValue = kext.address;
            }
        }
        
        //size
        else if(column == tableView.tableColumns[3])
        {
            //kernel proper? (size: 0)
            if(YES == [kext.size isEqualToString:@"0"])
            {
                ((NSTableCellView*)cell).textField.stringValue = @"0 (Kernel)";
            }
            else
            {
                ((NSTableCellView*)cell).textField.stringValue = kext.size;
            }
            
        }
        
        //architecture
        else if(column == tableView.tableColumns[4])
        {
            ((NSTableCellView*)cell).textField.stringValue = kext.architecture;
        }
        
    }

    return cell;
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
// ensures selected row remains selected
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
    // get its index and make sure that's still selected
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


@end
