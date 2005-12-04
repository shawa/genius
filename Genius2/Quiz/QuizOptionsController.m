//
//  QuizOptionsController.m
//  Genius2
//
//  Created by John R Chang on 2005-11-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QuizOptionsController.h"

#import "GeniusHelpController.h"


@implementation QuizOptionsController

- (id) init
{
	return [self initWithWindowNibName:@"QuizOptions"];
}

- (void)windowDidLoad
{
	[numItemsStepper setMinValue:1];
	[numItemsStepper setMaxValue:999];
	[numItemsStepper setValueWraps:NO];

//	NSRange range = NSMakeRange(0, [[learnMoreTextView string] length]);
	NSRect rect = [learnMoreTextView bounds]; // firstRectForCharacterRange:range];
	[learnMoreTextView addCursorRect:rect cursor:[NSCursor pointingHandCursor]];
}

- (int)runModal
{
	int result = [NSApp runModalForWindow:[self window]];
	[self close];
	return result;
}

- (IBAction)cancel:(id)sender
{
	[NSApp abortModal];
}

- (IBAction)quiz:(id)sender
{
	[NSApp stopModal];
}

- (NSMatrix *) quizModeRadioMatrix
{
	return quizModeRadioMatrix;
}

- (NSTextField *) fixedTimeTextField
{
	return fixedTimeTextField;
}

- (NSTextField *) numItemsTextField
{
	return numItemsTextField;
}

- (NSSlider *) reviewLearnSlider
{
	return reviewLearnSlider;
}

@end


@implementation QuizOptionsController (NSTextViewDelegate)

- (BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)link atIndex:(unsigned)charIndex
{
	static GeniusHelpController * sHelpController = nil;
	if (sHelpController == nil)
	{
		NSString * title = NSLocalizedString(@"Learning How To Learn", nil);
		sHelpController = [[GeniusHelpController alloc] initWithResourceName:@"Relax" title:title];
	}

    [sHelpController showWindow:nil];
	[NSApp abortModal];

	return YES;
}

@end


