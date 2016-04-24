//
//  KextEnumerator.m
//  
//
//  Created by Patrick Wardle on 5/2/15.
//
//

#import <libproc.h>
#import <sys/proc_info.h>

#import "Kext.h"
#import "Consts.h"
#import "Utilities.h"
#import "AppDelegate.h"
#import "KextEnumerator.h"

#import <syslog.h>
#import <signal.h>
#import <unistd.h>

@implementation KextEnumerator

@synthesize kexts;

//init
-(id)init
{
    //init super
    self = [super init];
    if(nil != self)
    {
        //init kexts dictionary/list
        kexts = [[OrderedDictionary alloc] init];
    }
    
    return self;
}


//enumerate all kexts, generate signing info/VT info, etc
// ->calls back into app delegate to update table
-(void)enumerateKexts
{
    //results from 'kextstat' cmd
    NSString* results = nil;
    
    //kext components
    NSArray* kextComponents = nil;
    
    //kext name
    NSString* kextName = nil;
    
    //kext object
    Kext* kext = nil;
    
    //virus total object
    VirusTotal* virusTotalObj = nil;
    
    //init virus total object
    virusTotalObj = [[VirusTotal alloc] init];
    
    //sync & reset
    @synchronized(self.kexts)
    {
        //reset
        [self.kexts removeAllObjects];
    }
    
    //exec 'kextstat' to get loaded kexts
    results = [[NSString alloc] initWithData:execTask(KEXTSTAT, @[@"-l"]) encoding:NSUTF8StringEncoding];
    
    //sanity check
    if(nil == results)
    {
        //bail
        goto bail;
    }
    
    //iterate over all kexts
    // ->format: Index Refs Address Size Wired Name (Version) <Linked Against>
    for(NSString* line in [results componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]])
    {
        //reset
        kextName = nil;
        
        //sanity check
        // ->skip blank lines
        if(0 == line.length)
        {
            //skip
            continue;
        }

        //split on white spaces into array
        kextComponents = [[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
        
        //sanity check
        if(kextComponents.count < 6)
        {
            //err msg
            NSLog(@"OBJECTIVE-SEE ERROR: %@ -> %@, could not be parsed", line, kextComponents);
            
            //skip
            continue;
        }
    
        //name
        // ->should be sixth item
        kextName = kextComponents[5];
        
        //sanity check
        if(nil == kextName)
        {
            //skip
            continue;
        }
        
        //create kext
        kext = [[Kext alloc] initWithName:kextName];
        
        //sanity check
        if(nil == kext)
        {
            //skip
            continue;
        }
        
        //save it
        // ->key is name
        //   should work, cuz trying to load different kext w/ same bundle id: 'different version/uuid already loaded'
        [self.kexts addObject:kext forKey:kext.name atStart:NO];
        
        //reload every 5 kexts
        if(0 == self.kexts.count % 5)
        {
            //reload kext table
            [((AppDelegate*)[[NSApplication sharedApplication] delegate]) reloadKextTable];
        }
    
    }//all kexts
   
    //do one more reload of kext table
    // ->ensures all kexts are displayed
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) reloadKextTable];
    
    //generate hashes
    for(Kext* kext in self.kexts.allValues)
    {
        //generate/save
        kext.hashes = hashFile(kext.path);
    }
    
    //query VT
    // ->25x at a time
    [virusTotalObj queryVT:self.kexts.allValues];

//bail
bail:
    
    return;
}

@end
