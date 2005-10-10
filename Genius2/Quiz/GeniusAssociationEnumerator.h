//
//  GeniusAssociationEnumerator.h
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GeniusAssociationEnumerator : NSEnumerator {
	NSArray * _allAssociations;
	NSMutableArray * _remainingAssociations;
}

- (id) initWithAssociations:(NSArray *)associations;

@end
