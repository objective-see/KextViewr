//
//  NSApplicationKeyEvents.m
//  KextViewr
//
//  Created by Patrick Wardle on 7/11/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "AppDelegate.h"
#import "NSApplicationKeyEvents.h"

@implementation NSApplicationKeyEvents

//to enable copy/paste etc even though we don't have an 'Edit' menu
// details: http://stackoverflow.com/questions/970707/cocoa-keyboard-shortcuts-in-dialog-without-an-edit-menu
-(void)sendEvent:(NSEvent *)event
{
    //only care about key down + command
    if( (NSEventTypeKeyDown != event.type) ||
        (NSEventModifierFlagCommand != (event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask)) )
    {
        //bail
        goto bail;
    }
    
    //+c (copy)
    if(YES == [[event charactersIgnoringModifiers] isEqualToString:@"c"])
    {
        //copy
        if(YES == [self sendAction:@selector(copy:) to:nil from:self])
        {
            return;
        }
    }
            
    //+v (paste)
    else if ([[event charactersIgnoringModifiers] isEqualToString:@"v"])
    {
        //paste
        if(YES == [self sendAction:@selector(paste:) to:nil from:self])
        {
            return;
        }
    }
            
    //+x (cut)
    else if ([[event charactersIgnoringModifiers] isEqualToString:@"x"])
    {
        //cut
        if(YES == [self sendAction:@selector(cut:) to:nil from:self])
        {
            return;
        }
    }
            
    //+a (select all)
    else if([[event charactersIgnoringModifiers] isEqualToString:@"a"])
    {
        //select
        if(YES == [self sendAction:@selector(selectAll:) to:nil from:self])
        {
            return;
        }
    }
    
    //+h (hide window)
    else if([[event charactersIgnoringModifiers] isEqualToString:@"h"])
    {
        //hide
        if(YES == [self sendAction:@selector(hide:) to:nil from:self])
        {
            return;
        }
    }
    
    //+m (minimize window)
    else if([[event charactersIgnoringModifiers] isEqualToString:@"m"])
    {
        //minimize
        [NSApplication.sharedApplication.keyWindow miniaturize:nil];
        return;
    }
    
    //+w (close window)
    else if([[event charactersIgnoringModifiers] isEqualToString:@"w"])
    {
        //close
        [NSApplication.sharedApplication.keyWindow close];
        return;
    }
    
    //+f
    else if([[event charactersIgnoringModifiers] isEqualToString:@"f"])
    {
        //iterate over all toolbar items
        // ...find search field, and select
        for(NSToolbarItem* item in NSApplication.sharedApplication.keyWindow.toolbar.items)
        {
            //not search field? skip
            if(0x1 != item.tag) continue;
            
            //and make it first responder
            [NSApplication.sharedApplication.keyWindow makeFirstResponder:item.view];
            
            //done
            return;
        }
    }
    
    //+r (refresh)
    else if([[event charactersIgnoringModifiers] isEqualToString:@"r"])
    {
        //refresh
        [((AppDelegate*)NSApplication.sharedApplication.delegate) refreshKexts:nil];
    }

bail:

    //super
    [super sendEvent:event];
    
    return;
}

@end
