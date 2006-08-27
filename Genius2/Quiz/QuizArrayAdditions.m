//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "QuizArrayAdditions.h"


@implementation NSArray (QuizArrayAdditions)

static int RandomSortFunction(id object1, id object2, void * context)
{
    BOOL x = random() & 0x1;
    return (x ? NSOrderedAscending : NSOrderedDescending);
}

- (NSArray *) _arrayByRandomizing
{
    return [self sortedArrayUsingFunction:RandomSortFunction context:nil];
}

@end
