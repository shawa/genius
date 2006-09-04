/*
	Genius
	Copyright (C) 2003-2006 John R Chang

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.	

	http://www.gnu.org/licenses/gpl.txt
*/

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
