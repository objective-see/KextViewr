//
//  Utilities.m
//  DHS
//
//  Created by Patrick Wardle on 2/7/15.
//  Copyright (c) 2015 Objective-See. All rights reserved.
//

#import "consts.h"
#import "utilities.h"

#import <signal.h>
#import <unistd.h>
#import <syslog.h>
#import <libproc.h>
#import <sys/sysctl.h>
#import <Security/Security.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <SystemConfiguration/SystemConfiguration.h>

//get host architecture (as string)
NSString* getNativeArch(void)
{
    int mib[2] = {0};
    size_t length = 0;
    char* output = NULL;
    
    NSString* nativeArchitecture = nil;

    //init
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;

    //get buffer size
    sysctl(mib, 2, NULL, &length, NULL, 0);
    
    //alloc
    output = malloc(length);
    
    //(re)invoke to get native arch
    sysctl(mib, 2, output, &length, NULL, 0);
    
    //convert
    nativeArchitecture = [NSString stringWithUTF8String:output];
    
    //cleanup
    if(NULL != output)
    {
        //free
        free(output);
        output = NULL;
    }
    
    return nativeArchitecture;
}

//get app's version
NSString* getAppVersion(void)
{
    //read and return 'CFBundleVersion' from bundle
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}


//exec a process and grab it's output
NSData* execTask(NSString* binaryPath, NSArray* arguments)
{
    //task
    NSTask *task = nil;
    
    //output pipe
    NSPipe *outPipe = nil;
    
    //read handle
    NSFileHandle* readHandle = nil;
    
    //output
    NSMutableData *output = nil;
    
    //init task
    task = [NSTask new];
    
    //init output pipe
    outPipe = [NSPipe pipe];
    
    //init read handle
    readHandle = [outPipe fileHandleForReading];
    
    //init output buffer
    output = [NSMutableData data];
    
    //set task's path
    [task setLaunchPath:binaryPath];
    
    //set task's args
    [task setArguments:arguments];
    
    //set task's output
    [task setStandardOutput:outPipe];

    //wrap task launch
    @try {
        
        //launch
        [task launch];
    }
    @catch(NSException *exception)
    {
        //err msg
        //syslog(LOG_ERR, "OBJECTIVE-SEE ERROR: taskExec(%s) failed with %s", [binaryPath UTF8String], [[exception description] UTF8String]);
        
        //bail
        goto bail;
    }
    
    //read in output
    while(YES == [task isRunning])
    {
        //accumulate output
        [output appendData:[readHandle readDataToEndOfFile]];
    }
    
    //grab any left over data
    [output appendData:[readHandle readDataToEndOfFile]];
    
//bail
bail:
    
    return output;
}

//wait until a window is non nil
// ->then make it modal
void makeModal(NSWindowController* windowController)
{
    //wait up to 1 second window to be non-nil
    // ->then make modal
    for(int i=0; i<20; i++)
    {
        //can make it modal once we have a window
        if(nil != windowController.window)
        {
            //make modal on main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                //modal
                [[NSApplication sharedApplication] runModalForWindow:windowController.window];
        
            });
            
            //all done
            break;
        }
        
        //nap
        [NSThread sleepForTimeInterval:0.05f];

    }//until 1 second
    
    return;
}


//set or unset button's highlight
void buttonAppearance(NSTableView* table, NSEvent* event, BOOL shouldReset)
{
    //mouse point
    NSPoint mousePoint = {0};
    
    //row index
    NSUInteger rowIndex = -1;
    
    //current row
    NSTableCellView* currentRow = nil;
    
    //tag
    NSUInteger tag = 0;
    
    //button
    NSButton* button = nil;
    
    //image name
    NSString* imageName =  nil;
    
    //extract tag
    tag = [((NSDictionary*)event.userData)[@"tag"] unsignedIntegerValue];
    
    //restore button back to default (visual) state
    if(YES == shouldReset)
    {
        //set image name
        // ->'info'
        if(TABLE_ROW_INFO_BUTTON == tag)
        {
            //set
            imageName = @"info";
        }
        //set image name
        // ->'info'
        else if(TABLE_ROW_SHOW_BUTTON == tag)
        {
            //set
            imageName = @"show";
        }
    }
    //highlight button
    else
    {
        //set image name
        // ->'info'
        if(TABLE_ROW_INFO_BUTTON == tag)
        {
            //set
            imageName = @"infoOver";
        }
        //set image name
        // ->'info'
        else if(TABLE_ROW_SHOW_BUTTON == tag)
        {
            //set
            imageName = @"showOver";
        }
    }
    
    //grab mouse point
    mousePoint = [table convertPoint:[event locationInWindow] fromView:nil];
    
    //compute row indow
    rowIndex = [table rowAtPoint:mousePoint];
    
    //sanity check
    if(-1 == rowIndex)
    {
        //bail
        goto bail;
    }
    
    //get row that's about to be selected
    currentRow = [table viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
    
    //get button
    // ->tag id of button, passed in userData var
    button = [currentRow viewWithTag:[((NSDictionary*)event.userData)[@"tag"] unsignedIntegerValue]];
    
    //restore default button image
    // ->for 'info' and 'show' buttons
    if(nil != imageName)
    {
        //set image
        [button setImage:[NSImage imageNamed:imageName]];
    }
    
bail:
    
    return;
}

//check if (full) dark mode
BOOL isDarkMode(void)
{
    //flag
    BOOL darkMode = NO;
    
    //not mojave?
    // bail, since not true dark mode
    if(YES != [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 14, 0}])
    {
        //bail
        goto bail;
    }
    
    //not dark mode?
    if(YES != [[NSUserDefaults.standardUserDefaults stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"])
    {
        //bail
        goto bail;
    }
    
    //ok, mojave dark mode it is!
    darkMode = YES;
    
bail:
    
    return darkMode;
}
    

