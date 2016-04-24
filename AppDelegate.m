//
//  AppDelegate.m
//  KextViewr
//

#import "Consts.h"
#import "Exception.h"
#import "Utilities.h"
#import "AppDelegate.h"
#import "KextTableController.h"

@implementation AppDelegate

@synthesize filterObj;
@synthesize startTime;
@synthesize saveButton;
@synthesize isConnected;
@synthesize kextEnumerator;
@synthesize kextEnumThread;
@synthesize commandHandling;
@synthesize completePosting;
@synthesize kextFilterView;
@synthesize kextTableController;
@synthesize aboutWindowController;

//center window
// ->also make front
-(void)awakeFromNib
{
    //center
    [self.window center];
    
    //make it key window
    [self.window makeKeyAndOrderFront:self];
    
    //make window front
    [NSApp activateIgnoringOtherApps:YES];
    
    return;
}

//automatically invoked by OS
// ->main entry point
-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    //first thing...
    // ->install exception handlers!
    installExceptionHandlers();
    
    //init filter obj
    filterObj = [[Filter alloc] init];
    
    //alloc/init custom search field for items
    kextFilterView = [[CustomTextField alloc] init];
    
    //set owner
    self.kextFilterView.owner = self;
    
    //set field editor for items
    [self.kextFilterView setFieldEditor:YES];
    
    //center
    [self.window center];
    
    //no need to have a first responder
    [self.window makeFirstResponder:nil];
    
    //check that OS is supported
    if(YES != isSupportedOS())
    {
        //show alert
        [self showUnsupportedAlert];
        
        //exit
        exit(0);
    }
    
    //register for hotkey presses
    [self registerKeypressHandler];
    
    //go!
    // ->setup tracking areas and begin thread that enumerates kexts
    [self go];
    
    //set delegate
    // ->ensures our 'windowWillClose' method, which has logic to fully exit app
    self.window.delegate = self;
    
    return;
}

//register handler for hot keys
-(void)registerKeypressHandler
{
    //event
    NSEvent * (^keypressHandler)(NSEvent *);
    
    //keypress handler
    keypressHandler = ^NSEvent * (NSEvent * theEvent){
        
        return [self handleKeypress:theEvent];
        
    };

    //register for key-down events
    [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:keypressHandler];
    
    return;
}

//invoked for any (but only) key-down events
-(NSEvent*)handleKeypress:(NSEvent*)event
{
    //flag indicating event was handled
    BOOL wasHandled = NO;
    
    //only care about 'cmd' + something
    if(NSCommandKeyMask != (event.modifierFlags & NSCommandKeyMask))
    {
        //bail
        goto bail;
    }
    
    //handle key-code
    // refresh (cmd+r)
    // save (cmd+s)
    // close window (cmd+w)
    switch ([event keyCode])
    {
        //'r' (refresh)
        case KEYCODE_R:
            
            //refresh
            [self refreshKexts:nil];
            
            //set flag
            wasHandled = YES;
            
            break;
        
        //'s' (save)
        case KEYCODE_S:
            
            //save
            [self saveResults:nil];
            
            //set flag
            wasHandled = YES;
            
            break;
            
        //'w' (close window)
        case KEYCODE_W:
            
            //close
            // ->if not main window
            if(self.window != [[NSApplication sharedApplication] keyWindow])
            {
                //close window
                [[[NSApplication sharedApplication] keyWindow] close];
                
                //set flag
                wasHandled = YES;
            }
            
            break;
            
            
        default:
            break;
    }

//bail
bail:
    
    //nil out event if it was handled
    if(YES == wasHandled)
    {
        event = nil;
    }
    
    //return the event, a new event, or, to stop
    // the event from being dispatched, nil
    return event;
}

//complete a few inits
// ->then invoke helper method to start enum'ing kexts (in bg thread)
-(void)go
{
    //init mouse-over areas
    [self initTrackingAreas];
    
    //go!
    [self enumKexts];
        
    return;
}

//begin kext enumeration
-(void)enumKexts
{
    //alloc kext enumerator
    if(nil == self.kextEnumerator)
    {
        //alloc
        kextEnumerator = [[KextEnumerator alloc] init];
    }
    
    //cancel (previous) enumerator thread
    if(nil != self.kextEnumThread)
    {
        //cancel
        [self.kextEnumThread cancel];
    }
    
    //alloc enumerator thread
    self.kextEnumThread = [[NSThread alloc] initWithTarget:self.kextEnumerator selector:@selector(enumerateKexts) object:nil];
    
    //kick off thread to enum kext
    // ->will update table as results come in
    [self.kextEnumThread start];
    
    return;
}

//smartly reload a specific row in table
// ->arg determines pane (top/bottom) and for bottom pane, the active view the item belongs to
-(void)reloadRow:(Kext*)item;
{
    //table view
    __block NSTableView* tableView = nil;
    
    //row
    __block NSUInteger row = 0;
    
    //run everything on main thread
    // ->ensures table view isn't changed out from under us....
    dispatch_async(dispatch_get_main_queue(), ^{
    
    //top table view
    tableView = [((id)self.kextTableController) itemView];
        
    //no filtering
    // ->grab row from all kexts
    if(YES != self.kextTableController.isFiltered)
    {
        //get row
        row = [self.kextEnumerator.kexts indexOfKey:item.name];
    }
    //filtering
    // ->grab row from filtered kexts
    else
    {
        //get row
        row = [self.kextTableController.filteredItems indexOfObject:item];
    }
    
    //sanity check
    if(NSNotFound == row)
    {
        //bail
        goto bail;
    }
    
    //begin updates
    [tableView beginUpdates];
    
    //reload row
    [tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:(row)] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    
    //end updates
    [tableView endUpdates];
        
//bail
bail:
        ;
        
    }); //dispatch on main thread
    
    return;
}

//display alert about OS not being supported
-(void)showUnsupportedAlert
{
    //alert box
    NSAlert* fullScanAlert = nil;
    
    //alloc/init alert
    fullScanAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"OS X %@ is not supported", [[NSProcessInfo processInfo] operatingSystemVersionString]] defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"sorry for the inconvenience!"];
    
    //and show it
    [fullScanAlert runModal];
    
    return;
}

//init tracking areas for buttons
// ->provide mouse over effects
-(void)initTrackingAreas
{
    //tracking area for buttons
    NSTrackingArea* trackingArea = nil;
    
    //init tracking area
    // ->for 'refresh' button
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self.refreshButton bounds] options:(NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:@{@"tag":[NSNumber numberWithUnsignedInteger:self.refreshButton.tag]}];
    
    //add tracking area to pref button
    [self.refreshButton addTrackingArea:trackingArea];
    
    //init tracking area
    // ->for save button
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self.saveButton bounds] options:(NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:@{@"tag":[NSNumber numberWithUnsignedInteger:self.saveButton.tag]}];
    
    //add tracking area to search button
    [self.saveButton addTrackingArea:trackingArea];
    
    //init tracking area
    // ->for logo button
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self.logoButton bounds] options:(NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:@{@"tag":[NSNumber numberWithUnsignedInteger:self.logoButton.tag]}];
    
    //add tracking area to logo button
    [self.logoButton addTrackingArea:trackingArea];

    return;
}

//automatically invoked when user clicks logo
// ->load objective-see's html page
-(IBAction)logoButtonHandler:(id)sender
{
    //open URL
    // ->invokes user's default browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://objective-see.com"]];
    
    return;
}

//reload kext table
// invoke custom refresh method on main thread
-(void)reloadKextTable
{
    //refresh on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //refresh
        [(id)self.kextTableController refresh];
        
    });

    return;
}

//automatically invoked when window is closing
// ->terminate app
-(void)windowWillClose:(NSNotification *)notification
{
    //exit
    [NSApp terminate:self];
    
    return;
}

//automatically invoked when mouse entered
-(void)mouseEntered:(NSEvent*)theEvent
{
    //mouse entered
    // ->highlight (visual) state
    [self buttonAppearance:theEvent shouldReset:NO];
    
    return;
}

//automatically invoked when mouse exits
-(void)mouseExited:(NSEvent*)theEvent
{
    //mouse exited
    // ->so reset button to original (visual) state
    [self buttonAppearance:theEvent shouldReset:YES];
    
    return;
}

//set or unset button's highlight
-(void)buttonAppearance:(NSEvent*)theEvent shouldReset:(BOOL)shouldReset
{
    //tag
    NSUInteger tag = 0;
    
    //image name
    NSString* imageName =  nil;
    
    //button
    NSButton* button = nil;
    
    //extract tag
    tag = [((NSDictionary*)theEvent.userData)[@"tag"] unsignedIntegerValue];
    
    //restore button back to default (visual) state
    if(YES == shouldReset)
    {
        //set original refresh image
        if(REFRESH_BUTTON_TAG == tag)
        {
            //set
            imageName = @"refreshIcon";
        }
        
        //set original save image
        else if(SAVE_BUTTON_TAG == tag)
        {
            //set
            imageName = @"saveIcon";
        }
        
        //set original logo image
        else if(LOGO_BUTTON_TAG == tag)
        {
            //set
            imageName = @"logoApple";
        }
    }
    //highlight button
    else
    {
        //set original refresh image
        if(REFRESH_BUTTON_TAG == tag)
        {
            //set
            imageName = @"refreshIconOver";
        }
        //set mouse over 'save' image
        else if(SAVE_BUTTON_TAG == tag)
        {
            //set
            imageName = @"saveIconOver";
        }
        //set mouse over logo image
        else if(LOGO_BUTTON_TAG == tag)
        {
            //set
            imageName = @"logoAppleOver";
        }
    }
    
    //set image
    
    //grab button
    button = [[[self window] contentView] viewWithTag:tag];
    if(YES != [button isKindOfClass:[NSButton class]])
    {
        //wtf
        goto bail;
    }
    
    //when enabled
    // ->set image
    if(YES == [button isEnabled])
    {
        //set
        [button setImage:[NSImage imageNamed:imageName]];
    }
    
//bail
bail:
    
    return;    
}

//invoked when user clicks 'save' icon
// ->show popup that allows user to save results
-(IBAction)saveResults:(id)sender
{
    //save panel
    NSSavePanel *panel = nil;
    
    //save results popup
    __block NSAlert* saveResultPopup = nil;
    
    //output
    // ->json of all kexts
    __block NSMutableString* output = nil;
    
    //error
    __block NSError* error = nil;
    
    //create panel
    panel = [NSSavePanel savePanel];
    
    //suggest file name
    [panel setNameFieldStringValue:@"kexts.json"];
    
    //show panel
    // ->completion handler will invoked when user clicks 'ok'
    [panel beginWithCompletionHandler:^(NSInteger result)
    {
        //only need to handle 'ok'
        if(NSFileHandlingPanelOKButton == result)
        {
            //alloc output JSON
            output = [NSMutableString string];
            
            //start JSON
            [output appendString:@"{\"kexts:\":["];
            
            //sync
            @synchronized(self.kextEnumerator.kexts)
            {
                
            //get kexts
            for(NSString* name in self.kextEnumerator.kexts)
            {
                //append kext JSON
                [output appendFormat:@"{%@},", [self.kextEnumerator.kexts[name] toJSON]];
            }
            
            }//sync
                
            //remove last ','
            if(YES == [output hasSuffix:@","])
            {
                //remove
                [output deleteCharactersInRange:NSMakeRange([output length]-1, 1)];
            }
            
            //terminate list/output
            [output appendString:@"]}"];
        
            //save JSON to disk
            // ->on error will show err msg in popup
            if(YES != [output writeToURL:[panel URL] atomically:NO encoding:NSUTF8StringEncoding error:&error])
            {
                //err msg
                syslog(LOG_ERR, "OBJECTIVE-SEE ERROR: saving output to %s failed with %s", [[panel URL] fileSystemRepresentation], [[error description] UTF8String]);
                
                //init popup w/ error msg
                saveResultPopup = [NSAlert alertWithMessageText:@"ERROR: failed to save output" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"details: %@", error];
                
            }
            //happy
            // ->set result msg
            else
            {
                //init popup w/ msg
                saveResultPopup = [NSAlert alertWithMessageText:@"Succesfully saved output" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"file: %@", [[panel URL] path]];
            }
            
            //show popup
            [saveResultPopup runModal];
        }
        
    }];
    
    return;
}



#pragma mark Menu Handler(s) #pragma mark -

//automatically invoked when user clicks 'About/Info'
// ->show about window
-(IBAction)about:(id)sender
{
    //alloc/init settings window
    if(nil == self.aboutWindowController)
    {
        //alloc/init
        aboutWindowController = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindow"];
    }
    
    //center window
    [[self.aboutWindowController window] center];
    
    //show it
    [self.aboutWindowController showWindow:self];

    return;
}

//automatically invoked when user enters text in filter search boxes
// ->filter kexts
-(void)controlTextDidChange:(NSNotification *)aNotification
{
    //search text
    NSTextView* search = nil;
    
    //extract search (text) view
    search = aNotification.userInfo[@"NSFieldEditor"];
    
    //sanity check
    if(nil == search)
    {
        //bail
        goto bail;
    }
    
    //prevent calling "complete" too often
    if( (YES != self.completePosting) &&
        (YES != self.commandHandling) )
    {
        //set flag
        self.completePosting = YES;
        
        //invoke complete
        [aNotification.userInfo[@"NSFieldEditor"] complete:nil];
        
        //unset flag
        self.completePosting = NO;
    }

    //when text is reset
    // ->just reset flag
    if(0 == search.string.length)
    {
        //set flag
        self.kextTableController.isFiltered = NO;
        
        //check 'show os kexts' box
        self.showOSKexts.state = STATE_ON;
    }
    //filter kexts
    else
    {
        //'#' indicates a keyword search
        // ->this is handled by customized auto-complete logic, so ignore
        if(YES == [search.string hasPrefix:@"#"])
        {
            //ignore
            goto bail;
        }
        
        //sync
        @synchronized(self.kextTableController.filteredItems)
        {
            //normal filter
            [self.filterObj filterKexts:search.string items:self.kextEnumerator.kexts results:self.kextTableController.filteredItems];
        }
            
        //set flag
        self.kextTableController.isFiltered = YES;
    }
    
    //finalize filtering/search
    // ->updates UI, etc
    [self finalizeFiltration];
    
//bail
bail:

    
    return;
}

//code to complete filtering/search
// ->reload table/scroll to top etc
-(void)finalizeFiltration
{
    //always reload table
    [self.kextTableController.itemView reloadData];
    
    //scroll to top
    [self.kextTableController scrollToTop];
    
    return;
}

//action for 'refresh' button/cmd+r hotkey
// ->run kextload to refresh/reload all kexts
-(IBAction)refreshKexts:(id)sender
{
    //unset filter flag
    self.kextTableController.isFiltered = NO;
    
    //sync
    @synchronized(self.kextTableController.filteredItems)
    {
        //remove all filtered items
        [self.kextTableController.filteredItems removeAllObjects];
    }
    
    //reset filter box
    self.filterKextsBox.stringValue = @"";
    
    //reset 'show os kexts' button
    self.showOSKexts.state = STATE_ON;
    
    //scroll to top
    [self.kextTableController scrollToTop];

    //select top row
    [self.kextTableController.itemView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    
    //get kexts
    // ->background thread will enum kexts, update table, etc
    [self enumKexts];
    
    return;
}

//delegate method, automatically called
// ->generate list of matches to return for drop-down
-(NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
    //matches
    NSMutableArray *matches = nil;
    
    //range options
    NSUInteger rangeOptions = {0};
    
    //init array for matches
    matches = [[NSMutableArray alloc] init];
    
    //init range options
    rangeOptions = NSAnchoredSearch | NSCaseInsensitiveSearch;
    
    //ignore all text's views that aren't kext filter view
    if(textView != self.kextFilterView)
    {
        //bail
        goto bail;
    }
    
    //check all filters
    for(NSString* filter in self.filterObj.filterKeywords)
    {
        //check if found
        // ->add to match when found
        if([filter rangeOfString:textView.string options:rangeOptions range:NSMakeRange(0, filter.length)].location != NSNotFound)
        {
            //add
            [matches addObject:filter];
        }
    }
    
    //sort matches
    [matches sortUsingComparator:^(NSString *a, NSString *b)
    {
        //sort
        return [a localizedStandardCompare:b];
    }];
    
//bail
bail:
    
    return matches;
}

//delegate method, automatically invoked
// ->handle invocations for text view
-(BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    //flag
    BOOL didPerformRequestedSelectorOnTextView = NO;
    
    //invocation
    NSInvocation *textViewInvocationForSelector = nil;
    
    //check if text view can handle selector
    if(YES != [textView respondsToSelector:commandSelector])
    {
        //bail
        goto bail;
    }
    
    //set iVar flag
    self.commandHandling = YES;
    
    //init invocation
    textViewInvocationForSelector = [NSInvocation invocationWithMethodSignature:[textView methodSignatureForSelector:commandSelector]];
    
    //set target
    [textViewInvocationForSelector setTarget:textView];
    
    //set selector
    [textViewInvocationForSelector setSelector:commandSelector];
    
    //invoke selector
    [textViewInvocationForSelector invoke];
    
    //unset iVar
    self.commandHandling = NO;
    
    //indicate that selector was performed
    didPerformRequestedSelectorOnTextView = YES;
    
    
//bail
bail:
    
    return didPerformRequestedSelectorOnTextView;
}
 
 
//callback for custom search fields
// ->handle auto-complete filterings
-(void)filterAutoComplete:(NSTextView*)textView
{
    //filter string
    NSString* filterString = nil;
    
    //extract filter
    filterString = textView.textStorage.string;
    
    //sync
    @synchronized(self.kextTableController.filteredItems)
    {
        //filter
        [self.filterObj filterKexts:filterString items:self.kextEnumerator.kexts results:self.kextTableController.filteredItems];
    }
    
    //set flag
    self.kextTableController.isFiltered = YES;
        
    //finalize filtering
    [self finalizeFiltration];
    
    //when filter is '#apple'
    // ->make sure 'show os kexts' is checked
    if(YES == [textView.textStorage.string isEqualToString:@"#apple"])
    {
        //check
        self.showOSKexts.state = STATE_ON;
    }
    
    //when filter is '#nonapple'
    // ->make sure 'show os kexts' is unchecked
    else if(YES == [textView.textStorage.string isEqualToString:@"#nonapple"])
    {
        //uncheck
        self.showOSKexts.state = STATE_OFF;
    }
    
    return;
}


//include or exclude OS kexts
-(IBAction)toggleOSFilter:(id)sender
{
    //when off
    // ->hide OS kexts
    if(STATE_OFF == ((NSButton*)sender).state)
    {
        //set kext filter
        [self.filterKextsBox setStringValue:@"#nonapple"];
        
        //filter out
        [self filterAppleKexts];
    }
    //reset filter
    else
    {
        //reset kext filter
        [self.filterKextsBox setStringValue:@""];
        
        //not filtered
        self.kextTableController.isFiltered = NO;
        
        //finalize non-filter
        [self finalizeFiltration];
    }
    
    return;
}

//filter for excluding OS kexts checkbox
-(void)filterAppleKexts
{
    //sync
    @synchronized(self.kextTableController.filteredItems)
    {
        //filter
        // ->logically same as '#nonapple'
        [self.filterObj filterKexts:@"#nonapple" items:self.kextEnumerator.kexts results:self.kextTableController.filteredItems];
    }
    
    //set flag
    self.kextTableController.isFiltered = YES;
    
    //finalize filtering
    [self finalizeFiltration];
    
    return;
}

//automatically invoked
// ->set all NSSearchFields to be instances of our custom NSTextView
-(id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
    //field editor
    id fieldEditor = nil;
    
    //ignore non-NSSearchField classes
    if(YES != [client isKindOfClass:[NSSearchField class]])
    {
        //ingnore
        goto bail;
    }
    
    //set kext's filter search field
    if(client == self.filterKextsBox)
    {
        //assign for return
        fieldEditor = self.kextFilterView;
    }
    
//bail
bail:
    
    return fieldEditor;
}



@end
