/*
	Genius
	Copyright (C) 2003-2006 John R Chang

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.	

	http://www.gnu.org/licenses/gpl.txt
*/

#import <Cocoa/Cocoa.h>

@class GeniusItem;
@class GeniusPair;
@class GeniusAssociationEnumerator;
@class GeniusAssociation;

//! Standard NSWindowController subclass for managing a user quiz.
@interface MyQuizController : NSWindowController
{
    IBOutlet NSObjectController *associationController;  //!< NSObjectController for #_currentAssociation.
    IBOutlet NSTextView *cueTextView;                    //!< Displays the cue item of #_currentAssociation.

    IBOutlet NSTabView *evaluationTabView;               //!< swap view for the review / learn controls
    IBOutlet NSTextView *answerTextView;                 //!< Displays the answer item of #_currentAssociation.

    IBOutlet NSTextField *entryField;                    //!< Text area for typing in the answer in learning mode.
    IBOutlet NSButton *yesButton;                        //!< Confirms correct answer.
    IBOutlet NSButton *noButton;                         //!< Confirms incorrect answer.
    IBOutlet NSLevelIndicator *progressIndicator;        //!< Little bar at top of quiz window showing progress.

    GeniusAssociationEnumerator * _enumerator;           //!< Contains GeniusAssociation objects for this quiz.
    GeniusAssociation * _currentAssociation;             //!< Currently displayed GeniusAssociation.
    
    NSSound * _newSound;                //!< Played as new items are presented
    NSSound * _rightSound;              //!< Played as correct answers are entered.
    NSSound * _wrongSound;              //!< Played for incorrect answers.
	NSWindow * _screenWindow;           //!< Semitransparent black backdrop window.

    GeniusItem * _visibleCueItem;       //!< Currently displayed cueItem from _currentAssociation
    GeniusItem * _visibleAnswerItem;    //!< Currently displayed answerItem from _currentAssociation
    NSFont * _cueItemFont;              //!< Currently used font for displaying cueItem.
    NSFont * _answerItemFont;           //!< Currently used font for displaying answerItem.
    NSColor * _answerTextColor;         //!< Currently used color for displaying answerItem.
}

- (void) runQuiz:(GeniusAssociationEnumerator *)enumerator;

- (GeniusItem *) visibleAnswerItem;

- (IBAction)handleEntry:(id)sender;
- (IBAction)getRightYes:(id)sender;
- (IBAction)getRightNo:(id)sender;
- (IBAction)getRightSkip:(id)sender;

@end
