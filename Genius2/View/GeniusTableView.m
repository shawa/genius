#import "GeniusTableView.h"


@implementation GeniusTableView

// Events

- (void)keyDown:(NSEvent *)theEvent
{
	id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(performKeyDown:)])
	{
		BOOL result = [delegate performKeyDown:theEvent];
		if (result == YES)
			return;
	}

	[super keyDown:theEvent];
}

// Handle Command-Return
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	NSWindow * window = [self window];
	
	// If the user presses Command-Return while editing a table view cell, end editing.
	NSText * fieldEditor = [window fieldEditor:NO forObject:self];
	if (fieldEditor && [[window firstResponder] isEqual:fieldEditor])
	{
		NSString * charactersIgnoringModifiers = [theEvent charactersIgnoringModifiers];
		if ([charactersIgnoringModifiers isEqualToString:@"\r"])
		{
			if ([window makeFirstResponder:self] == NO)
				[window endEditingFor:nil];
			return YES;
		}
	}
	
	return [super performKeyEquivalent:theEvent];
}

@end
