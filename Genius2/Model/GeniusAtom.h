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
@interface GeniusAtom :  NSManagedObject  
{
//	BOOL _isImageOnly;
}

+ (NSDictionary *) defaultTextAttributes;
- (BOOL) usesDefaultTextAttributes;		// used by GeniusDocument.nib
- (void) clearTextAttributes;

/*- (void) setUsesRTFDData:(BOOL)flag;	// converts string <-> rtfdData

- (void) setString:(NSString *)string;	// also sets rtfdData to nil
- (void) setRtfdData:(NSData *)rtfdData;	// also sets string to plain text form
*/

- (void) setRtfdData:(NSData *)rtfdData;

@end
