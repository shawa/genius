//
//  GeniusAssociationEnumerator.m
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAssociationEnumerator.h"


@implementation GeniusAssociationEnumerator

- (id) initWithAssociations:(NSArray *)associations
{
	self = [super init];
	_allAssociations = [associations retain];
	_remainingAssociations = [[NSMutableArray alloc] initWithArray:_allAssociations];
	return self;
}

- (void) dealloc
{
	[_remainingAssociations release];
	[_allAssociations release];
	[super dealloc];
}

- (NSArray *)allObjects
{
	return _remainingAssociations;
}

@end
