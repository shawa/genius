//
//  GeniusAtom.h
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>


extern NSString * GeniusAtomStringKey;
extern NSString * GeniusAtomRTFDDataKey;


/*
	An atom models one or more representations of a memorizable unit of information
*/
@interface GeniusAtom :  NSManagedObject <NSCopying>
{
}

+ (NSSet *)userModifiableKeySet;

+ (NSDictionary *) defaultTextAttributes;
- (BOOL) usesDefaultTextAttributes;		// used by GeniusDocument.nib
- (void) clearTextAttributes;

- (void) setStringRTFDData:(NSData *)rtfdData;
- (NSData *) stringRTFDData;	// falls back to string

@end


// Exported only for GeniusItem
extern NSString * GeniusAtomStringRTDDataKey;
extern NSString * GeniusAtomDirtyKey;
