//
//  GeniusAssociation.h
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "GeniusAtom.h"


extern NSString * GeniusAssociationLastResultDateKey;
extern NSString * GeniusAssociationDueDateKey;
extern NSString * GeniusAssociationPredictedScoreKey;


/*
	A directed association between two atoms, with score-keeping data.
	Like an axon between two neurons.
*/
@interface GeniusAssociation :  NSManagedObject  
{
	NSArray * _resultDicts;
}

- (GeniusAtom *) sourceAtom;
- (GeniusAtom *) targetAtom;

- (BOOL) lastResultValue;
- (unsigned int) resultCount;

- (void) addResult:(BOOL)value;

- (void) reset;
- (BOOL) isReset;

@end


// exported only for GeniusItem
extern NSString * GeniusAssociationSourceAtomKeyKey;
extern NSString * GeniusAssociationTargetAtomKeyKey;

// exported only for GeniusV1FileImporter
extern NSString * GeniusAssociationResultDictsKey;
extern NSString * GeniusAssociationResultDictDateKey;
extern NSString * GeniusAssociationResultDictValueKey;
