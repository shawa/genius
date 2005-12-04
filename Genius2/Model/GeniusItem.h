//
//  GeniusItem.h
//  Genius2
//
//  Created by John R Chang on 2005-09-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "GeniusAtom.h"


extern NSString * GeniusItemIsEnabledKey;
extern NSString * GeniusItemMyGroupKey;
extern NSString * GeniusItemMyTypeKey;
extern NSString * GeniusItemMyNotesKey;
extern NSString * GeniusItemMyRatingKey;
extern NSString * GeniusItemLastTestedDateKey;
extern NSString * GeniusItemLastModifiedDateKey;


@interface GeniusItem :  NSManagedObject <NSCopying>
{
	GeniusAtom * _atomA, * _atomB;
	NSString * _displayGrade;
}

+ (NSArray *) allAtomKeys;

- (GeniusAtom *) atomA;
- (GeniusAtom *) atomB;

- (void) touchLastModifiedDate;
- (void) touchLastTestedDate;

- (NSString *) displayGrade;

- (void) swapAtoms;

- (BOOL) usesDefaultTextAttributes;
- (void) clearTextAttributes;

- (void) resetAssociations;

- (void) flushCache;

@end


@interface GeniusItem (TextImportExport)

- (NSString *) tabularText;
+ (NSString *) tabularTextFromItems:(NSArray *)items;

@end


// exported only for GeniusV1FileImporter
extern NSString * GeniusItemAssociationsKey;
extern NSString * GeniusItemAssociationABKey;
extern NSString * GeniusItemAssociationBAKey;
