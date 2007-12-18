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
#import "GeniusWelcomePanel.h"
#import "NSString+Similiarity.h"
#import "GeniusStringDiff.h"
#import "GeniusPreferencesController.h"
#import "GeniusAssociationEnumerator.h"
#import "GeniusPair.h"
#import "GeniusAssociation.h"

const NSTimeInterval kQuizBackdropAnimationEaseInTimeInterval = 0.3;
const NSTimeInterval kQuizBackdropAnimationEaseOutTimeInterval = 0.2;

@implementation MyQuizController

//! Standard NSWindowController initialization.
- (id) init {
    self = [super initWithWindowNibName:@"Quiz"];
    if (self != nil) {
        _newSound = [[NSSound soundNamed:@"Blow"] retain];
        _rightSound = [[NSSound soundNamed:@"Hero"] retain];
        _wrongSound = [[NSSound soundNamed:@"Basso"] retain];
        
        _visibleCueItem = nil;
        _visibleAnswerItem = nil;
        _cueItemFont = nil;
        _answerItemFont = nil;
        _answerTextColor = nil;
    }
    return self;
}

//! Release sound and fonts.  Deallocate memory.
/*! @see #init */
- (void) dealloc
{
    [_newSound release];
    [_rightSound release];
    [_wrongSound release];

    [_cueItemFont release];
    [_answerItemFont release];

    [_enumerator release];
    [_screenWindow release];
    
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

//! _screenWindow getter.
- (NSWindow*) screenWindow
{
    if( ! _screenWindow)
    {
        NSRect screenRect = [[NSScreen mainScreen] frame];
        _screenWindow = [[NSWindow alloc] initWithContentRect:screenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        [_screenWindow setLevel:(NSModalPanelWindowLevel-1)];
        [_screenWindow setBackgroundColor:[NSColor blackColor]];
        [_screenWindow setAlphaValue:0.5];
        [_screenWindow setOpaque:NO];
        [_screenWindow setHasShadow:NO];
        [_screenWindow setIgnoresMouseEvents:YES];
        [_screenWindow setReleasedWhenClosed:NO];
    }
    return _screenWindow;
}

//! _enumerator setter.
- (void) setEnumerator: (GeniusAssociationEnumerator*) anEnumerator
{
    [anEnumerator retain];
    [_enumerator release];
    _enumerator = anEnumerator;
}

//! _enumerator getter.
- (GeniusAssociationEnumerator*) enumerator
{
    return _enumerator;
}

//! Puts up optional screening window and takes down other app windows.
/*! After this is run all app windows are hidden and an optional screening window is faded into place. */
- (void) quizSetup 
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
	
	// Fade in screen window with cool effect.
	if ([[NSUserDefaults standardUserDefaults] boolForKey:GeniusPreferencesQuizUseFullScreenKey])
	{
        NSAnimation * animation = nil;        
		animation = [[NSAnimation alloc] initWithDuration:kQuizBackdropAnimationEaseInTimeInterval animationCurve:NSAnimationEaseIn];
		[animation setDelegate:self];
		[animation addProgressMark:0.025];
		[[self screenWindow] setAlphaValue:0.0];
		[[self screenWindow] orderFront:self];
        
		[animation startAnimation];
		[animation release];
	}
    
    // Initialize progress indicator
    [progressIndicator setMaxValue:[[self enumerator] remainingCount]];
}

//! Takes down optional screening window and puts up other app windows.
- (void) quizTeardown
{    
	// Take down backdrop window
	if ([self screenWindow])
	{
        NSAnimation * animation = nil;
		animation = [[NSAnimation alloc] initWithDuration:kQuizBackdropAnimationEaseInTimeInterval animationCurve:NSAnimationEaseIn];

		[animation setAnimationCurve:NSAnimationEaseOut];
		[animation setDuration:kQuizBackdropAnimationEaseOutTimeInterval];
		[animation startAnimation];
		[animation release];

		[[self screenWindow] close];
	}
    
	// Show other document windows
	NSEnumerator * documentEnumerator = [[NSApp orderedDocuments] objectEnumerator];
    NSDocument * document;
	while ((document = [documentEnumerator nextObject]))
	{
		NSArray * windowControllers = [document windowControllers];
		[windowControllers makeObjectsPerformSelector:@selector(showWindow:) withObject:nil];
	}
    
    [NSApp stopModal];
}

//! presents a single Genius Item from deck for quiz or review.  Skips items with no answer.
- (void) runQuizOnce
{
    [progressIndicator setDoubleValue:([progressIndicator maxValue] - [[self enumerator] remainingCount])];

    // skip associations without answer values.
    do {
        _currentAssociation = [[self enumerator] nextAssociation];
    } while (_currentAssociation && [[_currentAssociation answerItem] stringValue] == nil);

    if(_currentAssociation != nil)
    {
        [associationController setContent:_currentAssociation];
        
        GeniusItem * cueItem = [_currentAssociation cueItem];
        [self _setVisibleCueItem:cueItem];
        
        GeniusItem * answerItem = [_currentAssociation answerItem];
        [self _setVisibleAnswerItem:nil];
        
        [cueTextView setNeedsDisplay:YES];
        [answerTextView setNeedsDisplay:YES];
        
        // Prepare window for reviewing
        if ([_currentAssociation isFirstTime])
        {
            // Prepare window for reviewing
            [self _setVisibleAnswerItem:answerItem];   // show the answer for review
            
            [getRightView setHidden:YES];
            [newAssociationView setHidden:NO];
            
            [entryField setEnabled:YES];
            [entryField setStringValue:[answerItem stringValue]];
            [entryField selectText:self];
            
            [_newSound stop];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:GeniusPreferencesUseSoundEffectsKey])
                [_newSound play];
        }
        // Prepare window for learning
        else
        {
            [self _setVisibleAnswerItem:nil];       // hide the answer for learning
            
            [entryField setStringValue:@""];
            [entryField setEnabled:YES];
            [getRightView setHidden:YES];
            [yesButton setKeyEquivalent:@""];
            [noButton setKeyEquivalent:@""];
            
            [newAssociationView setHidden:YES];
            
            [entryField selectText:self];    
        }  
    }
    // No associations left, so time to clean up.
    else {
        [self quizTeardown];
    }
}

//! The UI is available.  Initializ the quiz.
- (void)windowDidLoad
{
    [self quizSetup];
    [self runQuizOnce];
}
//! Runs a quiz session for the provided @a enumerator.
/*!
    Optionally presents a user tips panel with advice about how to work on memorization.  Depending on user preferences
    A screen window is displayed to reduce distractions.  Other document views are hidden while running this quiz. New
    GeniusAssociation instances which have no GeniusAssociation#scoreNumber are presented in review mode. 
*/
- (void) runQuiz:(GeniusAssociationEnumerator *)enumerator
{
    [self setEnumerator:enumerator];

    // Show "Take a moment to slow down..." panel
    BOOL result = [[GeniusWelcomePanel sharedWelcomePanel] runModal];
    if (result == NO)
        return;

    [NSApp runModalForWindow:[self window]];
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

    // Handle OK button for reviewed item.
    if ([_currentAssociation isFirstTime])
    {
        [[self enumerator] associationWrong:_currentAssociation];
        [self runQuizOnce];
    }
    // Handle typed entry for learning item.
    else
    {
        // Now show correct answer for review and / or re-enforcement
        GeniusItem * answerItem = [_currentAssociation answerItem];
        [self _setVisibleAnswerItem:answerItem];
        
        [entryField setEnabled:NO];
        [getRightView setHidden:NO];
        
        NSString * inputString = [entryField stringValue];
        NSString * targetString = [answerItem stringValue];
        
        float correctness = 0.0;
        int matchingMode = [[NSUserDefaults standardUserDefaults] integerForKey:GeniusPreferencesQuizMatchingModeKey];
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
            if ([[NSUserDefaults standardUserDefaults] boolForKey:GeniusPreferencesUseSoundEffectsKey])
                [_rightSound play];    
            [[self enumerator] associationRight:_currentAssociation];
            [self runQuizOnce];
        }
        else
        {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:GeniusPreferencesQuizUseVisualErrorsKey])
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
                if ([[NSUserDefaults standardUserDefaults] boolForKey:GeniusPreferencesUseSoundEffectsKey])
                    [_rightSound play];    
            }
            else if (correctness == 0.0)
            {
                // incorrect
                [noButton setKeyEquivalent:@"\r"];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:GeniusPreferencesUseSoundEffectsKey])
                    [_wrongSound play];
            }
            else
            {
                // partial credit
            }
        }
    }
}

//! Upon user review the answer is correct.
- (IBAction)getRightYes:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [[self enumerator] associationRight:_currentAssociation];
    
    [self runQuizOnce];
}

//! Upon user review the answer is wrong.
- (IBAction)getRightNo:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [[self enumerator] associationWrong:_currentAssociation];

    [self runQuizOnce];
}

//! Upon user review the answer is skipped the item.
- (IBAction)getRightSkip:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [[self enumerator] associationSkip:_currentAssociation];

    [self runQuizOnce];
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
    [self quizTeardown];
}

@end


//! Support for animated fade in and out of quiz backdrop window
/*!
    @todo Fix this so the fade in effect works.
*/
@implementation MyQuizController(NSAnimationDelegate)

//! Handles fade in and out of quiz backdrop window.
/*!
    We're set up in runQuiz:cumulativeTime: as the delegate of an NSAnimation.  We use the progress
    of the animation to determine the current alpha transparency of the quiz backdrop window.
*/
- (void)animation:(NSAnimation*)animation didReachProgressMark:(NSAnimationProgress)progress
{
	float alpha = [animation currentValue] * 0.5;
	[[self screenWindow] setAlphaValue:alpha];
    //! @bug This just adds another progress mark at the same place. Which means the fade in effect is actually lost.
	[animation addProgressMark:0.1]; 
}

@end
