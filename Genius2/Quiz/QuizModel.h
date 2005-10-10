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
	NSArray * _associations;

	unsigned int _requestedCount;
	float _requestedMinScore;
}

- (id) initWithDocument:(GeniusDocument *)document;

- (void) setCount:(unsigned int)count;
- (void) setMinimumScore:(float)score;

- (GeniusAssociationEnumerator *) associationEnumerator;

@end
