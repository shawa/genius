//
//  NSArrayGeniusAdditions.h
//  Genius
//
//  Created by John R Chang on Sat Oct 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


extern int RandomSortFunction(id object1, id object2, void * context);

@interface NSArray (NSArrayGeniusAdditions)
- (NSArray *) _arrayByRandomizing;
- (NSArray *) _arrayNotMatchingObjectsUsingSelector:(SEL)selector;
@end
