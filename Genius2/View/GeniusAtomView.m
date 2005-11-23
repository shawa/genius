//
//  GeniusAtomView.m
//  test
//
//  Created by John R Chang on 2005-10-12.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAtomView.h"

#import "GeniusAtom.h"


NSString * GeniusAtomViewUseRichTextAndGraphicsKey = @"useRichTextAndGraphics";


@implementation GeniusAtomView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_objectController = nil;
		_keyPath = nil;
		_useRichTextAndGraphics = NO;
	    }
    return self;
}

- (void) dealloc
{
	[_objectController release];
	[_keyPath release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[textView setRichText:NO];
	[textView setImportsGraphics:NO];
	[textView setUsesFontPanel:NO];
}


+ (NSDictionary *) _defaultTextAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:24.0], NSFontAttributeName, NULL];
/*	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont userFontOfSize:12.0], NSFontAttributeName,
		[NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName, NULL];*/
}


- (void) _unbind
{
	// Unbind
	[textView unbind:NSValueBinding];
	[textView unbind:NSDataBinding];
//	[textView unbind:NSEditableBinding];	
}

- (void) _bind
{
	// Rebind
	NSString * noSelectionString = NSLocalizedString(@"No selection", nil);
	if (_useRichTextAndGraphics == YES)
	{
		// noSelectionString -> noSelectionData
		NSDictionary * options = nil;
		NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:24.0], NSFontAttributeName,
			NSForegroundColorAttributeName, [NSColor grayColor],
			NULL];
		NSAttributedString * attrString = [[[NSAttributedString alloc] initWithString:noSelectionString attributes:attributes] autorelease];
		if (attrString)
		{
			NSRange range = NSMakeRange(0, [attrString length]);
			NSData * noSelectionData = [attrString RTFDFromRange:range documentAttributes:nil];
			options = [NSDictionary dictionaryWithObject:noSelectionData forKey:NSNoSelectionPlaceholderBindingOption];
		}

		NSString * keyPath = [NSString stringWithFormat:@"%@.%@", _keyPath, GeniusAtomRTFDDataKey];
		[textView bind:NSDataBinding toObject:_objectController withKeyPath:keyPath options:options];

/*		options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSNoSelectionPlaceholderBindingOption];
		[textView bind:NSEditableBinding toObject:controller withKeyPath:[NSString stringWithFormat:@"selection.%@", GeniusAtomRTFDDataKey] options:options];*/
	}
	else
	{
		NSString * keyPath = [NSString stringWithFormat:@"%@.%@", _keyPath, GeniusAtomStringKey];
		NSDictionary * options = [NSDictionary dictionaryWithObject:noSelectionString forKey:NSNoSelectionPlaceholderBindingOption];
		[textView bind:NSValueBinding toObject:_objectController withKeyPath:keyPath options:options];		

/*		options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSNoSelectionPlaceholderBindingOption];
		[textView bind:NSEditableBinding toObject:controller withKeyPath:[NSString stringWithFormat:@"selection.%@", GeniusAtomStringKey] options:options];*/
	}

	// Set default text attributes
	NSDictionary * defaultTextAttributes = [GeniusAtomView _defaultTextAttributes];
	NSMutableAttributedString * attrString = [textView textStorage];
	NSRange range = NSMakeRange(0, [attrString length]);		
	[attrString setAttributes:defaultTextAttributes range:range];
	[textView setTypingAttributes:defaultTextAttributes];
	[textView setAlignment:NSCenterTextAlignment];
	
	if ([textView isEditable])
		[textView selectAll:nil];
}

- (void) bindAtomToController:(id)observableController withKeyPath:(NSString *)keyPath;
{
	[self _unbind];

	[_objectController release];
	_objectController = [observableController retain];
	[_keyPath release];
	_keyPath = [keyPath copy];

	[self _bind];
}


- (BOOL) useRichTextAndGraphics
{
	return _useRichTextAndGraphics;
}

- (void) setUseRichTextAndGraphics:(BOOL)flag
{
	[self willChangeValueForKey:@"useRichTextAndGraphics"];
	_useRichTextAndGraphics = flag;
	[self didChangeValueForKey:@"useRichTextAndGraphics"];	
}


- (BOOL) _shouldConvertRichTextToPlainText
{
	NSString * messageText = NSLocalizedString(@"Convert this column to plain text?", nil);
	NSString * informativeText = NSLocalizedString(@"If you convert this column, you will lose all text styles (such as fonts and colors) and attachments.", nil);
	NSString * defaultButton = NSLocalizedString(@"Convert", nil);
	NSString * alternateButton = NSLocalizedString(@"Cancel", nil);

	NSAlert * alert = [NSAlert alertWithMessageText:messageText defaultButton:defaultButton
		alternateButton:alternateButton otherButton:nil informativeTextWithFormat:informativeText];
	int returnCode = [alert runModal];
	if (returnCode == 0)	// No	// XXX: documentation says it's supposed to be NSAlertSecondButtonReturn
		return NO;
	
	return YES;
}

- (IBAction) performToggleRichText:(id)sender
{
	BOOL flag = ([sender state] == NSOnState);
	if (flag == NO)
	{
		if ([self _shouldConvertRichTextToPlainText] == NO)
		{
			[sender setState:NSOnState];
			return;
		}
	}
		
	[self _unbind];
	
	// Change text view
	[textView setRichText:flag];
	[textView setImportsGraphics:flag];
	[textView setUsesFontPanel:flag];

	[self setUseRichTextAndGraphics:flag];
	[self _bind];

	// Clear rich text
/*	if (flag == NO)
		[[controller content] setValue:nil forKey:GeniusAtomRTFDDataKey];	// clear out rtfdData from atom too
*/	
}

@end
