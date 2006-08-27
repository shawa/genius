//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

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

	NSDate * _quizUntilDate;	
}

- (id) initWithDocument:(GeniusDocument *)document;

- (void) runQuiz;

@end
