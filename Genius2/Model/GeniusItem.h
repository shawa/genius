//
//  GeniusItem.h
//  Genius2
//
//  Created by John R Chang on 2005-09-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Cocoa/Cocoa.h>


// In table column order
extern NSString * GeniusItemIsEnabledKey;
extern NSString * GeniusItemAtomAKey;
extern NSString * GeniusItemAtomBKey;
extern NSString * GeniusItemMyGroupKey;
extern NSString * GeniusItemMyTypeKey;
extern NSString * GeniusItemMyRatingKey;
extern NSString * GeniusItemDisplayGradeKey;
extern NSString * GeniusItemLastTestedDateKey;
extern NSString * GeniusItemLastModifiedDateKey;

extern NSString * GeniusItemMyNotesKey;


@class GeniusAssociation;

@interface GeniusItem :  NSManagedObject
{
	GeniusAssociation * _associationAB;
	GeniusAssociation * _associationBA;
}

- (BOOL) usesDefaultTextAttributes;
- (void) clearTextAttributes;

- (void) swapAtoms;

@end


@interface GeniusItem (ScoreKeeping)

- (GeniusAssociation *) associationAB;
- (GeniusAssociation *) associationBA;

- (void) resetAssociations;
- (BOOL) isAssociationsReset;

- (float) grade;
- (NSString *) displayGrade;
- (NSImage *) gradeIcon;

@end


@interface GeniusItem (TextImportExport)

- (NSString *) tabularText;
+ (NSString *) tabularTextFromItems:(NSArray *)items;

@end
