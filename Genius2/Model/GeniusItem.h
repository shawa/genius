//
//  GeniusItem.h
//  Genius2
//
//  Created by John R Chang on 2005-09-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface GeniusItem :  NSManagedObject  
{
	NSString * _displayGrade;
}

+ (NSArray *) allAtomKeys;

- (void) touchLastModifiedDate;
- (void) touchLastTestedDate;

- (NSString *) displayGrade;

- (void) resetAssociations;

- (void) flushCache;

@end
