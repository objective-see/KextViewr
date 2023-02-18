//
//  ItemTableController.h
//  KextViewr
//
//  Created by Patrick Wardle on 2/18/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "Kext.h"
#import "3rdParty/OrderedDictionary.h"



#import <Foundation/Foundation.h>

@interface KextTableController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    
}

//overlay
@property (weak) IBOutlet NSView *overlay;
@property (weak) IBOutlet NSProgressIndicator *activityIndicator;

//flag for ignoring automated row selections
@property BOOL ignoreSelection;

//flag for filtering
@property BOOL isFiltered;

//all table items
@property(nonatomic, retain)NSMutableArray* tableItems;

//filtered table items
@property(nonatomic, retain)NSMutableArray* filteredItems;

//category table view
@property(weak) IBOutlet NSTableView *itemView;


//currently selected row
// can help determine if newly selected row is really new
@property NSUInteger selectedRow;

//flag to differentiate between top/bottom view
@property BOOL isBottomPane;

/* METHODS */

//reload table
-(void)reloadTable;

//show overlay
-(void)showOverlay;

//hide overlay
-(void)hideOverlay;

//custom reload
// ->ensures selected row remains selected
-(void)refresh;

//grab a kext at a row
-(Kext*)kextForRow:(id)sender;

//scroll back up to top of table
-(void)scrollToTop;



@end
