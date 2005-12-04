//
//  QuizModel.h
//  Genius2
//
//  Created by John R Chang on 2005-10-09.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GeniusDocument.h"
#import "GeniusAssociationEnumerator.h"


@interface QuizModel : NSObject {
	GeniusDocument * _document;
	NSArray * _allActiveAssociations;

	unsigned int _requestedCount;
	float _requestedReviewLearnFloat;
	float _requestedMinScore;
}

- (id) initWithDocument:(GeniusDocument *)document;

- (BOOL) hasValidItems;	// preflight

- (void) setCount:(unsigned int)count;	// 0 means all
- (void) setReviewLearnFloat:(float)value;

- (GeniusAssociationEnumerator *) associationEnumerator;	// does the selection here

@end
