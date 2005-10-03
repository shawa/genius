//
//  GeniusAssociation.h
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class GeniusItem;

@interface GeniusAssociation :  NSManagedObject  
{
	NSArray * _dataPoints;
}

- (void) reset;

@end
