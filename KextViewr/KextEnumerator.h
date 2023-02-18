//
//  KextEnumerator.h
//  
//
//  Created by Patrick Wardle on 5/2/15.
//
//

#import "3rdParty/OrderedDictionary.h"

#import <Foundation/Foundation.h>


@interface KextEnumerator : NSObject
{
    
}

/* PROPERTIES */

//all kext objects
@property(nonatomic, retain)OrderedDictionary* kexts;

/* METHODS */

//enumerate all kext
// calls back into app delegate to update table
-(void)enumerateKexts;

@end
