//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

#import "GeniusAssociation.h"


@interface GeniusAssociationEnumerator : NSEnumerator {
	NSArray * _allAssociations;
	NSMutableArray * _remainingAssociations;
	NSMutableArray * _scheduledAssociations;
	GeniusAssociation * _currentAssociation;
}

- (id) initWithAssociations:(NSArray *)associations;

- (NSArray *) allObjects;
- (id) nextObject;

- (void) neutral;
- (void) right;
- (void) wrong;

@end
