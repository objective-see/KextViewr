//
//  CategoryRow.m
//  KextViewr
//
//  Created by Patrick Wardle on 4/4/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "KKRow.h"
#import "utilities.h"

@implementation KKRow

//custom row selection
-(void)drawSelectionInRect:(NSRect)dirtyRect
{
    //selection rect
    NSRect selectionRect = {0};
    
    //selection path
    NSBezierPath *selectionPath = nil;
    
    //highlight selected rows
    if(self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone)
    {
        //make selection rect
        selectionRect = NSInsetRect(self.bounds, 2.5, 2.5);
        
        //dark mode highlight
        if(YES == isDarkMode())
        {
            //set stroke
            [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setStroke];
            
            //set fill
            [[NSColor colorWithCalibratedWhite:.50 alpha:1.0] setFill];
        }
        //light mode highlight
        else
        {
            //set stroke
            [[NSColor colorWithCalibratedWhite:.65 alpha:1.0] setStroke];
            
            //set fill
            [[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
        }
        
        //create selection path
        // ...with rounded corners
        selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:5 yRadius:5];
        
        //fill
        [selectionPath fill];
        
        //stroke
        [selectionPath stroke];
    }
    
    return;
}
@end
