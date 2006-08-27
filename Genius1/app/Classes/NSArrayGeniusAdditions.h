//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Foundation/Foundation.h>


extern int RandomSortFunction(id object1, id object2, void * context);

@interface NSArray (NSArrayGeniusAdditions)
- (NSArray *) _arrayByRandomizing;
- (NSArray *) _arrayNotMatchingObjectsUsingSelector:(SEL)selector;
@end
