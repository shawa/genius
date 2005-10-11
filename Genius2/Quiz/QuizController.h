//
//  QuizController.h
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GeniusAssociationEnumerator.h"


@interface QuizController : NSWindowController {
	IBOutlet id stateController;
	IBOutlet id sourceAtomController;
	IBOutlet id targetAtomController;
	IBOutlet id inputField;
	IBOutlet id noButton;
	IBOutlet id yesButton;

	GeniusAssociationEnumerator * _associationEnumerator;
	NSMutableDictionary * _stateInfo;
	unsigned int _maxCount;
	
    NSSound * _newSound;
    NSSound * _rightSound;
    NSSound * _wrongSound;
}

- (id) initWithAssociationEnumerator:(GeniusAssociationEnumerator *)associationEnumerator;

- (void) runQuiz;

@end
