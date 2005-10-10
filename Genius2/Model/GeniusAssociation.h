//
//  GeniusAssociation.h
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class GeniusItem;

/*
	A directed association between two atoms, with score-keeping data.
	Like an axon between two neurons.
*/

@interface GeniusAssociation :  NSManagedObject  
{
	NSArray * _dataPoints;
}

- (void) reset;

@end
