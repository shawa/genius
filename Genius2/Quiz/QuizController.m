//
//  QuizController.m
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QuizController.h"

#import "GeniusAtom.h"
#import "GeniusAssociationEnumerator.h"
#import "QuizOptionsController.h"

#import "NSStringSimiliarity.h"
#import "VisualStringDiff.h"

#import "GeniusPreferences.h"

#import "QuizBackdropWindow.h"


const NSTimeInterval kQuizBackdropAnimationEaseInTimeInterval = 0.3;
const NSTimeInterval kQuizBackdropAnimationEaseOutTimeInterval = 0.2;

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


- (id) _initWithAssociationEnumerator:(GeniusAssociationEnumerator *)associationEnumerator
{
	self = [super initWithWindowNibName:@"Quiz"];
	
	_associationEnumerator = [associationEnumerator retain];
	
	_stateInfo = [NSMutableDictionary new];
	_maxCount = [[_associationEnumerator allObjects] count];
	[self _updateProgress];
	
    _newSound = [[NSSound soundNamed:@"Blow"] retain];
    _rightSound = [[NSSound soundNamed:@"Hero"] retain];
    _wrongSound = [[NSSound soundNamed:@"Basso"] retain];

	_quizUntilDate = nil;

	return self;
}

- (id) initWithDocument:(GeniusDocument *)document
{
	QuizModel * model = [[[QuizModel alloc] initWithDocument:document] autorelease];

	// Put up error sheet
	if ([model hasValidItems] == NO)
	{
		NSString * messageString = NSLocalizedString(@"There is nothing to study.", nil);
		NSString * informativeString = NSLocalizedString(@"Make sure the items you want to study are filled in and enabled, or add more items.", nil);

		NSAlert * alert = [NSAlert alertWithMessageText:messageString defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:informativeString];
		[alert beginSheetModalForWindow:[document mainWindow] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
		return nil;
	}

	// Put up modal options dialog
	QuizOptionsController * oc = [[QuizOptionsController alloc] init];
	int result = [oc runModal];
	[oc release];
	if (result == NSRunAbortedResponse)
		return nil;

	// Setup quiz options
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	int requestedNumItems = [ud integerForKey:GeniusPreferencesQuizNumItemsKey];
	if (requestedNumItems > 0)
		[model setCount:requestedNumItems];

	int fixedTimeMinutes = [ud integerForKey:GeniusPreferencesQuizFixedTimeMinKey];
	if (fixedTimeMinutes > 0)
		_quizUntilDate = [NSDate dateWithTimeIntervalSinceNow:(60 * fixedTimeMinutes)];

	float reviewLearnFloat = [ud floatForKey:GeniusPreferencesQuizReviewLearnFloatKey];
	[model setReviewLearnFloat:reviewLearnFloat];

	
	GeniusAssociationEnumerator * associationEnumerator = [model associationEnumerator];
	return [self _initWithAssociationEnumerator:associationEnumerator];
}

- (void) dealloc
{
	[_stateInfo release];
	[_associationEnumerator release];

    [_newSound release];
    [_rightSound release];
    [_wrongSound release];
	
	[_quizUntilDate release];
	
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
	[[self window] makeFirstResponder:inputField];
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
	[[self window] makeFirstResponder:inputField];
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
	// Hide other document windows
	NSEnumerator * documentEnumerator = [[NSApp orderedDocuments] objectEnumerator];
	NSDocument * document;
	while ((document = [documentEnumerator nextObject]))
	{
		NSEnumerator * windowControllerEnumerator = [[document windowControllers] objectEnumerator];
		NSWindowController * windowController;
		while ((windowController = [windowControllerEnumerator nextObject]))
			[[windowController window] orderOut:nil];
	}
	
	// Put up backdrop window
	_screenWindow = nil;
	NSAnimation * animation = nil;
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
	if ([ud boolForKey:GeniusPreferencesQuizUseFullScreenKey])
	{
		_screenWindow = [QuizBackdropWindow new];

		animation = [[NSAnimation alloc] initWithDuration:kQuizBackdropAnimationEaseInTimeInterval animationCurve:NSAnimationEaseIn];
		[animation setDelegate:self];
		[animation addProgressMark:0.025];
		[_screenWindow setAlphaValue:0.0];
		[_screenWindow orderFront:self];

		[animation startAnimation];
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

			[_associationEnumerator neutral];
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

		if ([(NSDate *)[NSDate date] compare:_quizUntilDate] == NSOrderedDescending)
			break;
	}

    [self close];
	
	// Take down backdrop window
	if (_screenWindow)
	{
		[animation setAnimationCurve:NSAnimationEaseOut];
		[animation setDuration:kQuizBackdropAnimationEaseOutTimeInterval];
		[animation startAnimation];
		[_screenWindow close];
		[animation release];
	}

	// Show other document windows
	documentEnumerator = [[NSApp orderedDocuments] objectEnumerator];
	while ((document = [documentEnumerator nextObject]))
	{
		NSArray * windowControllers = [document windowControllers];
		[windowControllers makeObjectsPerformSelector:@selector(showWindow:) withObject:nil];
	}
}


- (IBAction) next:(id)sender
{
    [NSApp stopModal];	
}

- (IBAction) checkInput:(id)sender
{
    [NSApp stopModal];	
}

- (IBAction) right:(id)sender
{
    // End editing (from -[NSWindow endEditingFor:] documentation)
	NSWindow * window = [self window];
    BOOL succeed = [window makeFirstResponder:window];
    if (!succeed)
        [window endEditingFor:nil];

    [_associationEnumerator right];
    [NSApp stopModal];
}

- (IBAction) wrong:(id)sender
{
    // End editing (from -[NSWindow endEditingFor:] documentation)
	NSWindow * window = [self window];
    BOOL succeed = [window makeFirstResponder:window];
    if (!succeed)
        [window endEditingFor:nil];

    [_associationEnumerator wrong];
    [NSApp stopModal];
}

- (IBAction) skip:(id)sender
{
    // End editing (from -[NSWindow endEditingFor:] documentation)
	NSWindow * window = [self window];
    BOOL succeed = [window makeFirstResponder:window];
    if (!succeed)
        [window endEditingFor:nil];
}

@end


@implementation QuizController (NSAnimationDelegate)

- (void)animation:(NSAnimation*)animation didReachProgressMark:(NSAnimationProgress)progress
{
	float alpha = [animation currentValue] * 0.5;
	[_screenWindow setAlphaValue:alpha];
	[animation addProgressMark:0.1];
}

@end


@implementation QuizController (NSWindowDelegate)

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
	NSWindow * window = [self window];
    BOOL succeed = [window makeFirstResponder:window];
    if (!succeed)
        [window endEditingFor:nil];

    return YES;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [NSApp abortModal];
}

@end
