//
//  GeniusAtom.h
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


extern NSString * GeniusAtomStringKey;
extern NSString * GeniusAtomRTFDDataKey;


/*
	An atom models one or more representations of a memorizable unit of information
*/
@interface GeniusAtom :  NSManagedObject <NSCopying>
{
}

+ (NSDictionary *) defaultTextAttributes;
- (BOOL) usesDefaultTextAttributes;		// used by GeniusDocument.nib
- (void) clearTextAttributes;

- (void) setRtfdData:(NSData *)rtfdData;

@end


// Exported only for GeniusItem
extern NSString * GeniusAtomKeyKey;
extern NSString * GeniusAtomModifiedDateKey;
