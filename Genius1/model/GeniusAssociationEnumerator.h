//
//  GeniusAssociationEnumerator.h
//  Genius
//
//  Created by John R Chang on Sat Oct 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeniusPair.h"


@interface GeniusAssociationEnumerator : NSObject {
    NSMutableArray * _inputAssociations;
    
    unsigned int _count;
    int _minimumScore;
    float _m_value;

    // Transient state
    int _maximumScore;
    
    NSMutableArray * _scheduledAssociations;
    BOOL _hasPerformedChooseAssociations;
}

- (id) initWithAssociations:(NSArray *)associations;

// This stuff doesn't really belong in this class
- (void) setCount:(unsigned int)count;
- (void) setMinimumScore:(int)score;
- (void) setProbabilityCenter:(float)value;
- (void) performChooseAssociations;

- (int) remainingCount;

- (GeniusAssociation *) nextAssociation;

- (void) associationRight:(GeniusAssociation *)association;
- (void) associationWrong:(GeniusAssociation *)association;
- (void) associationSkip:(GeniusAssociation *)association;

@end
