//
//  QuizArrayAdditions.m
//  Genius
//
//  Created by John R Chang on Sat Oct 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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
