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

#import "MyQuizController.h"
#include <unistd.h> // getpid
#import "GeniusWelcomePanel.h"
#import "NSString+Similiarity.h"
#import "GeniusStringDiff.h"
#import "GeniusPreferencesController.h"


const NSTimeInterval kQuizBackdropAnimationEaseInTimeInterval = 0.3;
const NSTimeInterval kQuizBackdropAnimationEaseOutTimeInterval = 0.2;

@implementation MyQuizController

//! Standard NSWindowController initialization.
/*!
    @todo move this setup into an init method which calls initWithWindowNibName:
*/
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];

    _cumulativeTimePtr = nil;

    _newSound = [[NSSound soundNamed:@"Blow"] retain];
    _rightSound = [[NSSound soundNamed:@"Hero"] retain];
    _wrongSound = [[NSSound soundNamed:@"Basso"] retain];

    _visibleCueItem = nil;
    _visibleAnswerItem = nil;
    _cueItemFont = nil;
    _answerItemFont = nil;
    _answerTextColor = nil;
        
    [self window];  // load window

    return self;
}

//! Release sound and fonts.  Deallocate memory.
/*! @see #initWithWindowNibName: */
- (void) dealloc
{
    [_newSound release];
    [_rightSound release];
    [_wrongSound release];

    [_cueItemFont release];
    [_answerItemFont release];

    [super dealloc];
}


//! _visibleCueItem setter.
/*!
    Single line items are large size and centered-justified.
    Multiple line items are small size and left-justified.
    Nil items are grey color; non-nil items are black color.
*/
- (void) _setVisibleCueItem:(GeniusItem *)item
{
    BOOL useLargeSize = YES;
    if (item)
    {
        NSArray * lines = [[item stringValue] componentsSeparatedByString:@"\n"];
        useLargeSize = ([lines count] <= 1);
    }
    float fontSize = (useLargeSize ? 18.0 : 13.0);
    NSFont * font = [NSFont boldSystemFontOfSize:fontSize];
    [self setValue:font forKey:@"cueItemFont"];
    
    //[self setValue:[NSColor blackColor] forKey:@"visibleAnswerTextColor"];

    _visibleCueItem = item;

    NSTextAlignment alignment = (useLargeSize ? NSCenterTextAlignment : NSLeftTextAlignment);
    [cueTextView setAlignment:alignment];
}

//! _visibleAnswerItem setter.
/*!
    Single line items are large size and centered-justified.
    Multiple line items are small size and left-justified.
    Nil items are grey color; non-nil items are black color.
 */
- (void) _setVisibleAnswerItem:(GeniusItem *)item
{
    BOOL useLargeSize = YES;
    if (item)
    {
        NSArray * lines = [[item stringValue] componentsSeparatedByString:@"\n"];
        useLargeSize = ([lines count] <= 1);
    }
    float fontSize = (useLargeSize ? 18.0 : 13.0);
    NSFont * font = [NSFont systemFontOfSize:fontSize];
    [self setValue:font forKey:@"answerItemFont"];
    
    if (item)
        [self setValue:[NSColor blackColor] forKey:@"answerTextColor"];
    else
        [self setValue:[NSColor grayColor] forKey:@"answerTextColor"];

    _visibleAnswerItem = item;

    NSTextAlignment alignment = (useLargeSize ? NSCenterTextAlignment : NSLeftTextAlignment);
    [answerTextView setAlignment:alignment];
}

//! Updates the #studyTimeField to display the running time of the quiz.
/*!
    This method and its associated studyTimeField may be dead code.  Aside from studyTimeField doesn't show up in code or nib files.
    And the only call to this method shows up in a comment in #runQuiz:cumulativeTime:.
     @todo Check where studyTimeField is ever set.
*/
- (void) _handleStudyTimer:(NSTimer *)timer
{
    if (_cumulativeTimePtr)
    {
        (*_cumulativeTimePtr)++;
        
        NSString * string = [NSString stringWithFormat:@"%.0lf", *_cumulativeTimePtr];
        [studyTimeField setStringValue:string];
    }
}

//! Runs a quiz session for the provided @a enumerator.
/*!
    Optionally presents a user tips panel with advice about how to work on memorization.  Depending on user preferences
    A screen window is displayed to reduce distractions.  Other document views are hidden while running this quiz. New
    GeniusAssociation instances which have no GeniusAssociation#scoreNumber are presented in review mode. 
*/
- (void) runQuiz:(GeniusAssociationEnumerator *)enumerator cumulativeTime:(NSTimeInterval *)cumulativeTimePtr
{
    // Show "Take a moment to slow down..." panel
    BOOL result = [[GeniusWelcomePanel sharedWelcomePanel] runModal];
    if (result == NO)
        return;

    if (cumulativeTimePtr)
        _cumulativeTimePtr = cumulativeTimePtr;
    /*NSTimer * studyTimer = [[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(_handleStudyTimer:) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:studyTimer forMode:NSModalPanelRunLoopMode];*/


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


    _enumerator = [enumerator retain];
    
    int n = [_enumerator remainingCount];
    [progressIndicator setMaxValue:n];
    
    while ((_currentAssociation = [_enumerator nextAssociation]))
    {
        int result;
        
        [associationController setContent:_currentAssociation];

        GeniusItem * cueItem = [_currentAssociation cueItem];
        [self _setVisibleCueItem:cueItem];
        
        GeniusItem * answerItem = [_currentAssociation answerItem];
        [self _setVisibleAnswerItem:nil];

        [cueTextView setNeedsDisplay:YES];
        [answerTextView setNeedsDisplay:YES];


		NSString * targetString = [answerItem stringValue];
		if (targetString == nil)
			continue;

        // Prepare window for questioning
        BOOL isFirstTime = ([_currentAssociation scoreNumber] == nil);
        if (isFirstTime)
        {
            // Prepare window for reviewing
            [self _setVisibleAnswerItem:answerItem];   // show the answer for review

            [getRightView setHidden:YES];
            [newAssociationView setHidden:NO];

            [entryField setEnabled:YES];
            [entryField setStringValue:targetString];
            [entryField selectText:self];
            
			[_newSound stop];
			if ([ud boolForKey:GeniusPreferencesUseSoundEffectsKey])
				[_newSound play];
        }
        else
        {
            [self _setVisibleAnswerItem:nil];       // hide the answer

            [entryField setStringValue:@""];
            [entryField setEnabled:YES];
            [getRightView setHidden:YES];
            [yesButton setKeyEquivalent:@""];
            [noButton setKeyEquivalent:@""];

            [newAssociationView setHidden:YES];
            
            [entryField selectText:self];
            
            // Block for answering
             result = [NSApp runModalForWindow:[self window]];
            if (result == NSRunAbortedResponse)
                break;
     
            // Prepare window for reviewing
            [self _setVisibleAnswerItem:answerItem];   // show the answer for review
            
            [entryField setEnabled:NO];
            [getRightView setHidden:NO];


			NSString * inputString = [entryField stringValue];
			
			float correctness = 0.0;
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
			
            #if DEBUG
                NSLog(@"correctness = %f", correctness);
            #endif
            if (correctness == 1.0)
			{
				if ([ud boolForKey:GeniusPreferencesUseSoundEffectsKey])
					[_rightSound play];    
				[_enumerator associationRight:_currentAssociation];
				
				goto skip_review;
			}

			if ([ud boolForKey:GeniusPreferencesQuizUseVisualErrorsKey])
			{
				// Get annotated diff string
				NSAttributedString * attrString = [GeniusStringDiff attributedStringHighlightingDifferencesFromString:inputString toString:targetString];

				NSMutableAttributedString * mutAttrString = [attrString mutableCopy];
				NSMutableParagraphStyle * parStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
				[parStyle setAlignment:NSCenterTextAlignment];
				[mutAttrString addAttribute:NSParagraphStyleAttributeName value:parStyle range:NSMakeRange(0, [attrString length])];
				[parStyle release];

				[entryField setAttributedStringValue:mutAttrString];
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
            else
            {
                // partial credit
            }
        }
                
        // Block for reviewing
        result = [NSApp runModalForWindow:[self window]];
        if (result == NSRunAbortedResponse)
            break;

        // Handle OK
        if (isFirstTime)
            [_enumerator associationWrong:_currentAssociation];

skip_review:
        [progressIndicator setDoubleValue:(n-[_enumerator remainingCount])];
    }
    
    [_enumerator release];

/*    [studyTimer invalidate];
    [studyTimer release];*/
    
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

//! #_visibleCueItem getter
- (GeniusItem *) visibleAnswerItem
{
    return _visibleAnswerItem;
}

//! The user entered text in #entryField or hit the okay button during review.
- (IBAction)handleEntry:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [NSApp stopModal];
}

//! The user answered correctly.
- (IBAction)getRightYes:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_enumerator associationRight:_currentAssociation];
    
    [NSApp stopModal];
}

//! The user answered incorrectly.
- (IBAction)getRightNo:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_enumerator associationWrong:_currentAssociation];

    [NSApp stopModal];
}

//! The user skipped the GeniusAssociation.
- (IBAction)getRightSkip:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_enumerator associationSkip:_currentAssociation];

    [NSApp stopModal];
}

//! Handle keyboard driven input.
/*!
    @todo What about handling skip with a key equivalent?
    @todo What about handling ending with a press of esc.
*/
- (void)keyDown:(NSEvent *)theEvent
{
    NSString * characters = [theEvent characters];
    if ([characters isEqualToString:@"y"])
        [self getRightYes:self];
    else if ([characters isEqualToString:@"n"])
        [self getRightNo:self];
    else
        [super keyDown:theEvent];
}

//! The user can elect to end quiz by closing the window.
- (BOOL)windowShouldClose:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];
    return YES;
}

//! The user elected to close the quiz window.
- (void)windowWillClose:(NSNotification *)aNotification
{
    [NSApp abortModal];
}

@end


//! Support for animated fade in and out of QuizBackdropWindow
/*!
    @todo Fix this so the fade in effect works.
*/
@implementation MyQuizController(NSAnimationDelegate)

//! Handles fade in and out of QuizBackdropWindow.
/*!
    We're set up in runQuiz:cumulativeTime: as the delegate of an NSAnimation.  We use the progress
    of the animation to determine the current alpha transparency of the QuizBackdropWindow.
*/
- (void)animation:(NSAnimation*)animation didReachProgressMark:(NSAnimationProgress)progress
{
    NSLog(@"got to herer");
	float alpha = [animation currentValue] * 0.5;
	[_screenWindow setAlphaValue:alpha];
    //! @bug This just adds another progress mark at the same place. Which means the fade in effect is actually lost.
	[animation addProgressMark:0.1]; 
}

@end
