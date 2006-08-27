//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

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
	// Allow text field validation to occur before we continue
	NSWindow * window = [self window];
	if ([window makeFirstResponder:window] == NO)
		return;

	[NSApp stopModal];
}


- (NSTextField *) _radioMatrixCorrespondingTextField
{
	if ([quizModeRadioMatrix selectedRow] == 0)
		return numItemsTextField;
	else
		return fixedTimeTextField;
}

- (IBAction)didChangeQuizModeRadioMatrix:(id)sender
{
	NSTextField * textField = [self _radioMatrixCorrespondingTextField];
	
	// Begin editing in corresponding text field
	[[self window] makeFirstResponder:textField];
	[textField selectText:self];
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
