//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

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

+ (NSArray *) keyPathOrderForTextRepresentation;

- (NSString *) tabularText;
+ (NSString *) tabularTextFromItems:(NSArray *)items;

+ (NSArray *) itemsFromTabularText:(NSString *)string order:(NSArray *)keyPaths;
- (id) initWithTabularText:(NSString *)line order:(NSArray *)keyPaths;

@end


// for GeniusDocument
extern NSString * GeniusItemScoreHasChangedNotification;
