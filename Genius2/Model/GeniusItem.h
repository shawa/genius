//
//  GeniusItem.h
//  Genius2
//
//  Created by John R Chang on 2005-09-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Cocoa/Cocoa.h>


extern NSString * GeniusItemAtomAKey;
extern NSString * GeniusItemAtomBKey;

extern NSString * GeniusItemIsEnabledKey;
extern NSString * GeniusItemMyGroupKey;
extern NSString * GeniusItemMyTypeKey;
extern NSString * GeniusItemMyNotesKey;
extern NSString * GeniusItemMyRatingKey;
extern NSString * GeniusItemLastTestedDateKey;
extern NSString * GeniusItemLastModifiedDateKey;


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

- (float) grade;
- (NSString *) displayGrade;
- (NSImage *) gradeIcon;

@end


@interface GeniusItem (TextImportExport)

- (NSString *) tabularText;
+ (NSString *) tabularTextFromItems:(NSArray *)items;

@end
