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

#import "NSArrayGeniusAdditions.h"


//! Utility methods for creating randomized subsets of an array.
@implementation NSArray(NSArrayGeniusAdditions)

//! randomly returns NSOrderedAscending or NSOrderedDescending
int RandomSortFunction(id object1, id object2, void * context)
{
    BOOL x = random() & 0x1;
    return (x ? NSOrderedAscending : NSOrderedDescending);
}

//! Returns a randomized version of the original array.
- (NSArray *) _arrayByRandomizing
{
    return [self sortedArrayUsingFunction:RandomSortFunction context:nil];
}

//! Returns an array which includes items return value from @a selector.
/*!
    @todo Replace this with filteredArrayUsingPredicate:
*/
- (NSArray *) _arrayNotMatchingObjectsUsingSelector:(SEL)selector
{
    NSEnumerator * objectEnumerator = [self objectEnumerator];
    NSObject * object;
    NSMutableArray * matchingObjects = [NSMutableArray array];
    while ((object = [objectEnumerator nextObject]))
    {
        id result = [object performSelector:selector withObject:nil];
        if (result == nil)
            [matchingObjects addObject:object];
    }
    return matchingObjects;
}

@end
