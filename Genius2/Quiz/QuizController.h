//
//  QuizController.h
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GeniusAssociationEnumerator.h"


@interface QuizController : NSObject {
	GeniusAssociationEnumerator * _associationEnumerator;

	NSWindowController * _windowController;

    NSSound * _newSound;
    NSSound * _rightSound;
    NSSound * _wrongSound;
}

- (id) initWithAssociationEnumerator:(GeniusAssociationEnumerator *)associationEnumerator;

- (void) runQuiz;

@end
