//
//  NSArrayGeniusAdditions.m
//  Genius
//
//  Created by John R Chang on Sat Oct 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSArrayGeniusAdditions.h"


@implementation NSArray (NSArrayGeniusAdditions)
int RandomSortFunction(id object1, id object2, void * context)
{
    BOOL x = random() & 0x1;
    return (x ? NSOrderedAscending : NSOrderedDescending);
}

- (NSArray *) _arrayByRandomizing
{
    return [self sortedArrayUsingFunction:RandomSortFunction context:nil];
}

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
