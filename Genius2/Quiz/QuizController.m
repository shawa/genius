//
//  QuizController.m
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QuizController.h"

#import "NSStringSimiliarity.h"
#import "VisualStringDiff.h"

#import "GeniusPreferences.h"

#import "QuizFullScreenWindow.h"


enum {
	QuizNewAssociationState,
	QuizAnswerState,
	QuizPostAnswerState
};


@implementation QuizController

- (void) _updateProgress
{
	unsigned int remainingCount = [[_associationEnumerator allObjects] count];
	float progress = (_maxCount-remainingCount) / _maxCount;
	
	[_stateInfo setValue:[NSNumber numberWithFloat:progress] forKey:@"ProgressValue"];
}

- (void) _setState:(unsigned int)state
{
	[_stateInfo setValue:[NSNumber numberWithBool:(state == QuizNewAssociationState)] forKey:@"isNewAssociationState"];
	[_stateInfo setValue:[NSNumber numberWithBool:(state == QuizAnswerState)] forKey:@"isAnswerState"];
	[_stateInfo setValue:[NSNumber numberWithBool:(state == QuizPostAnswerState)] forKey:@"isPostAnswerState"];
}


- (id) initWithAssociationEnumerator:(GeniusAssociationEnumerator *)associationEnumerator
{
	self = [super initWithWindowNibName:@"Quiz"];
	
	_associationEnumerator = [associationEnumerator retain];
	
	_stateInfo = [NSMutableDictionary new];
	_maxCount = [[_associationEnumerator allObjects] count];
	[self _updateProgress];
	
    _newSound = [[NSSound soundNamed:@"Blow"] retain];
    _rightSound = [[NSSound soundNamed:@"Hero"] retain];
    _wrongSound = [[NSSound soundNamed:@"Basso"] retain];

	return self;
}

- (void) dealloc
{
    [_newSound release];
    [_rightSound release];
    [_wrongSound release];
	
	[_stateInfo release];
	[_associationEnumerator release];
	
	[super dealloc];
}


- (void)windowDidLoad
{
	[stateController setContent:_stateInfo];
	
	[sourceTextView setAlignment:NSCenterTextAlignment];
	[targetTextView setAlignment:NSCenterTextAlignment];
}


- (void) _showAssociationForNewAssociation:(GeniusAssociation *)association
{
	[self _setState:QuizNewAssociationState];

	[targetAtomController setContent:[association targetAtom]];	// show answer

	NSString * targetString = [[association targetAtom] valueForKey:GeniusAtomStringKey];
	[inputField setStringValue:targetString];

	[inputField setEnabled:YES];
	[inputField selectText:self];
	
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
	if ([ud boolForKey:GeniusPreferencesUseSoundEffectsKey])
	{
		[_newSound stop];
		[_newSound play];
	}
}

- (void) _showAssociationForAnswer:(GeniusAssociation *)association
{
	[self _setState:QuizAnswerState];

	[targetAtomController setContent:nil];						// hide answer

	[noButton setKeyEquivalent:@""];
	[yesButton setKeyEquivalent:@""];

	[inputField setStringValue:@""];

	[inputField setEnabled:YES];
	[inputField selectText:self];
}

- (BOOL) _handleAssociationForPostAnswer:(GeniusAssociation *)association
{
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	NSString * targetString = [[association targetAtom] valueForKey:GeniusAtomStringKey];
	NSString * inputString = [inputField stringValue];			

	float correctness;
	int matchingMode = [ud integerForKey:GeniusPreferencesQuizMatchingModeKey];
	switch (matchingMode)
	{
		case GeniusPreferencesQuizExactMatchingMode:
			correctness = (float)[targetString isEqualToString:inputString];
			break;
		case GeniusPreferencesQuizCaseInsensitiveMatchingMode:
			correctness = (float)([targetString localizedCaseInsensitiveCompare:inputString] == NSOrderedSame);
			break;
		case GeniusPreferencesQuizSimilarMatchingMode:
			correctness = [targetString isSimilarToString:inputString];
			break;
		default:
			NSAssert(NO, @"matchingMode");
	}
	//NSLog(@"%d -> %f", matchingMode, correctness);
	
	if (correctness == 1.0)
	{
		NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
		if ([ud boolForKey:GeniusPreferencesUseSoundEffectsKey])
			[_rightSound play];
			
		[_associationEnumerator right];
		return YES;
	}
	else
	{
		[self _setState:QuizPostAnswerState];

		[targetAtomController setContent:[association targetAtom]];	// show answer

		[inputField setEnabled:NO];

		if ([ud boolForKey:GeniusPreferencesQuizUseVisualErrorsKey])
		{
			// Get annotated diff string
			NSAttributedString * attrString = [VisualStringDiff attributedStringHighlightingDifferencesFromString:inputString toString:targetString];

			NSMutableAttributedString * mutAttrString = [attrString mutableCopy];
			NSMutableParagraphStyle * parStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			[parStyle setAlignment:NSCenterTextAlignment];
			[mutAttrString addAttribute:NSParagraphStyleAttributeName value:parStyle range:NSMakeRange(0, [attrString length])];
			[parStyle release];

			[inputField setAttributedStringValue:mutAttrString];
			[mutAttrString release];
		}
		
		if (correctness > 0.5)
		{
			// correct
			[yesButton setKeyEquivalent:@"\r"];
		
			if ([ud boolForKey:GeniusPreferencesUseSoundEffectsKey])
				[_rightSound play];    
		}
		else if (correctness == 0.0)
		{
			// incorrect
			[noButton setKeyEquivalent:@"\r"];

			if ([ud boolForKey:GeniusPreferencesUseSoundEffectsKey])
				[_wrongSound play];
		}
			
		// Wait for user to acknowledge answer
		int result = [NSApp runModalForWindow:[self window]];
		if (result == NSRunAbortedResponse)
			return NO;

		return YES;
	}
}


- (void) runQuiz
{
	QuizFullScreenWindow * screenWindow = nil;
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
	if ([ud boolForKey:GeniusPreferencesUseFullScreenKey])
	{
		[QuizFullScreenWindow new];
		[screenWindow orderFront:self];
	}

    [[self window] center];

	GeniusAssociation * association;
    while ((association = [_associationEnumerator nextObject]))
	{
		[sourceAtomController setContent:[association sourceAtom]];
		
		if ([association isReset])
		{
			[self _showAssociationForNewAssociation:association];

			// Wait for user to "Remember this item"
			int result = [NSApp runModalForWindow:[self window]];
			if (result == NSRunAbortedResponse)
				break;
		}
		else
		{
			[self _showAssociationForAnswer:association];

			// Wait for user to input answer
			int result = [NSApp runModalForWindow:[self window]];
			if (result == NSRunAbortedResponse)
				break;

			BOOL shouldContinue = [self _handleAssociationForPostAnswer:association];
			if (shouldContinue == NO)
				break;
		}

		[self _updateProgress];
	}

    [self close];
	
	[screenWindow close];
}


- (IBAction) next:(id)sender
{
	[_associationEnumerator neutral];
    [NSApp stopModal];
}

- (IBAction) checkInput:(id)sender
{
    [NSApp stopModal];	
}

- (IBAction) right:(id)sender
{
    // End editing (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_associationEnumerator right];
    [NSApp stopModal];
}

- (IBAction) wrong:(id)sender
{
    // End editing (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_associationEnumerator wrong];
    [NSApp stopModal];
}

- (IBAction) skip:(id)sender
{
    // End editing (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_associationEnumerator right];
}

@end


@implementation QuizController (WindowDelegate)

- (void)keyDown:(NSEvent *)theEvent
{
    NSString * characters = [theEvent characters];
    if ([characters isEqualToString:@"y"])
        [self right:self];
    else if ([characters isEqualToString:@"n"])
        [self wrong:self];
    else
        [super keyDown:theEvent];
}

- (BOOL)windowShouldClose:(id)sender
{
    // End editing (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    return YES;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [NSApp abortModal];
}

@end
