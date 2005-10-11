//
//  GeniusAssociationEnumerator.h
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GeniusAssociation.h"


@interface GeniusAssociationEnumerator : NSEnumerator {
	NSArray * _allAssociations;
	NSMutableArray * _remainingAssociations;
	NSMutableArray * _scheduledAssociations;
	GeniusAssociation * _currentAssociation;
}

- (id) initWithAssociations:(NSArray *)associations;

- (NSArray *) allObjects;
- (id) nextObject;

- (void) neutral;
- (void) right;
- (void) wrong;

@end
