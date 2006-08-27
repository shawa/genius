//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

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
