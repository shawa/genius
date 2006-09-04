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


@implementation MyQuizController

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

- (void) dealloc
{
    [_newSound release];
    [_rightSound release];
    [_wrongSound release];

    [_cueItemFont release];
    [_answerItemFont release];

    [super dealloc];
}

/*
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


- (void) _handleStudyTimer:(NSTimer *)timer
{
    if (_cumulativeTimePtr)
    {
        (*_cumulativeTimePtr)++;
        
        NSString * string = [NSString stringWithFormat:@"%.0lf", *_cumulativeTimePtr];
        [studyTimeField setStringValue:string];
    }
}

- (void) runQuiz:(GeniusAssociationEnumerator *)enumerator cumulativeTime:(NSTimeInterval *)cumulativeTimePtr
{
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

    // Show "Take a moment to slow down..." panel
    BOOL result = [[GeniusWelcomePanel sharedWelcomePanel] runModal];
    if (result == NO)
        return;

    if (cumulativeTimePtr)
        _cumulativeTimePtr = cumulativeTimePtr;
    /*NSTimer * studyTimer = [[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(_handleStudyTimer:) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:studyTimer forMode:NSModalPanelRunLoopMode];*/

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


		NSString * origString = [answerItem stringValue];
		if (origString == nil)
			continue;

        // Prepare window for questioning
        BOOL isFirstTime = ([_currentAssociation scoreNumber] == nil);
        if (isFirstTime)
        {
            // Prepare window for reviewing
            [self _setVisibleAnswerItem:answerItem];   // show

            [getRightView setHidden:YES];
            [newAssociationView setHidden:NO];

            [entryField setEnabled:YES];
            [entryField setStringValue:origString];
            [entryField selectText:self];
            
			[_newSound stop];
			if ([ud boolForKey:@"useSoundEffects"])
				[_newSound play];
        }
        else
        {
            [self _setVisibleAnswerItem:nil];       // hide

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
            [self _setVisibleAnswerItem:answerItem];   // show
            
            [entryField setEnabled:NO];
            [getRightView setHidden:NO];


			NSString * userString = [entryField stringValue];
			
            float similarity = [origString isSimilarToString:userString];
            #if DEBUG
                NSLog(@"similarity = %f", similarity);
            #endif
            if (similarity == 1.0)
			{
				if ([ud boolForKey:@"useSoundEffects"])
					[_rightSound play];    
				[_enumerator associationRight:_currentAssociation];
				
				goto skip_review;
			}

			// Get annotated diff string
			NSAttributedString * attrString = [GeniusStringDiff attributedStringHighlightingDifferencesFromString:userString toString:origString];

			NSMutableAttributedString * mutAttrString = [attrString mutableCopy];
			NSMutableParagraphStyle * parStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			[parStyle setAlignment:NSCenterTextAlignment];
			[mutAttrString addAttribute:NSParagraphStyleAttributeName value:parStyle range:NSMakeRange(0, [attrString length])];
			[parStyle release];

			[entryField setAttributedStringValue:mutAttrString];
			[mutAttrString release];


            if (similarity > 0.5)
            {
                // correct
                [yesButton setKeyEquivalent:@"\r"];
				if ([ud boolForKey:@"useSoundEffects"])
					[_rightSound play];    
            }
            else if (similarity == 0.0)
            {
                // incorrect
                [noButton setKeyEquivalent:@"\r"];
				if ([ud boolForKey:@"useSoundEffects"])
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
}


- (GeniusItem *) visibleAnswerItem
{
    return _visibleAnswerItem;
}


- (IBAction)handleEntry:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [NSApp stopModal];
}

- (IBAction)getRightYes:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_enumerator associationRight:_currentAssociation];
    
    [NSApp stopModal];
}

- (IBAction)getRightNo:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_enumerator associationWrong:_currentAssociation];

    [NSApp stopModal];
}

- (IBAction)getRightSkip:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    [_enumerator associationSkip:_currentAssociation];

    [NSApp stopModal];
}

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

- (BOOL)windowShouldClose:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
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
