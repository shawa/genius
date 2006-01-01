//
//  GeniusAssociation.h
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


//extern NSString * GeniusAssociationPredictedScoreKey;
extern NSString * GeniusAssociationDueDateKey;
extern NSString * GeniusAssociationDataPointArrayDataKey;


@class GeniusAtom;

@interface GeniusAssociation :  NSManagedObject

// for QuizController
- (GeniusAtom *) sourceAtom;
- (GeniusAtom *) targetAtom;

@end


@class GeniusAssociationDataPoint;

@interface GeniusAssociation (Results)

- (void) addResult:(BOOL)value;

- (float) predictedScore;

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
