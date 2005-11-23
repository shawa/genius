//
//  QuizController.h
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "QuizModel.h"


@class GeniusDocument;
@class QuizBackdropWindow;

@interface QuizController : NSWindowController {
	IBOutlet id stateController;
	IBOutlet id sourceTextView;
	IBOutlet id targetTextView;
	IBOutlet id sourceAtomController;
	IBOutlet id targetAtomController;
	IBOutlet id inputField;
	IBOutlet id noButton;
	IBOutlet id yesButton;

	GeniusAssociationEnumerator * _associationEnumerator;
	NSMutableDictionary * _stateInfo;
	unsigned int _maxCount;
	QuizBackdropWindow * _screenWindow;
	
    NSSound * _newSound;
    NSSound * _rightSound;
    NSSound * _wrongSound;
}

- (id) initWithDocument:(GeniusDocument *)document;

- (void) runQuiz;

@end
