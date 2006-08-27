//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <CoreData/CoreData.h>


extern NSString * GeniusAssociationDueDateKey;
extern NSString * GeniusAssociationDataPointArrayDataKey;

extern NSString * GeniusAssociationPredictedValueKey;


@class GeniusAtom;

@interface GeniusAssociation :  NSManagedObject

// for QuizController
- (GeniusAtom *) sourceAtom;
- (GeniusAtom *) targetAtom;

@end


@class GeniusAssociationDataPoint;

@interface GeniusAssociation (Results)

// used by inspector nib
- (NSArray *) dataPoints;
- (void) setDataPoints:(NSArray *)dataPoints;

// used by document nib
- (unsigned int) correctCount;
- (void) setCorrectCount:(NSNumber *)countNumber;


- (void) addResult:(BOOL)value;

- (float) predictedValue;

// XXX: used only by GeniusAssociationEnumerator
- (unsigned int) resultCount;
- (GeniusAssociationDataPoint *) lastDataPoint;

- (void) reset;
- (BOOL) isReset;

@end


// for GeniusItem
extern NSString * GeniusAssociationParentItemKey;
extern NSString * GeniusAssociationSourceAtomKey;
extern NSString * GeniusAssociationTargetAtomKey;

// for GeniusV1FileImporter
extern NSString * GeniusAssociationHandicapKey;
