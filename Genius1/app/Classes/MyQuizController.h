/* MyQuizController */

#import <Cocoa/Cocoa.h>
#import "GeniusItem.h"
#import "GeniusPair.h"
#import "GeniusAssociationEnumerator.h"

@interface MyQuizController : NSWindowController
{
    IBOutlet id associationController;
    IBOutlet id cueTextView;
    IBOutlet id answerTextView;
    IBOutlet id getRightView;
    IBOutlet id entryField;
    IBOutlet id yesButton;
    IBOutlet id noButton;
    IBOutlet id newAssociationView;
    IBOutlet id progressIndicator;
    IBOutlet id studyTimeField;

    GeniusAssociationEnumerator * _enumerator;
    GeniusAssociation * _currentAssociation;
    NSTimeInterval * _cumulativeTimePtr;
    
    NSSound * _newSound;
    NSSound * _rightSound;
    NSSound * _wrongSound;

    GeniusItem * _visibleCueItem;       // used by key-value binding
    GeniusItem * _visibleAnswerItem;    // used by key-value binding
    NSFont * _cueItemFont;              // used by key-value binding
    NSFont * _answerItemFont;           // used by key-value binding
    NSColor * _answerTextColor;         // used by key-value binding
}

- (void) runQuiz:(GeniusAssociationEnumerator *)enumerator cumulativeTime:(NSTimeInterval *)cumulativeTimePtr;

- (GeniusItem *) visibleAnswerItem;

- (IBAction)handleEntry:(id)sender;
- (IBAction)getRightYes:(id)sender;
- (IBAction)getRightNo:(id)sender;
- (IBAction)getRightSkip:(id)sender;

@end
