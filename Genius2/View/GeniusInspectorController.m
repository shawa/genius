#import "GeniusInspectorController.h"

#import "GeniusDocument.h"
#import "GeniusDocumentInfo.h"


@implementation GeniusInspectorController

// file:///Developer/ADC%20Reference%20Library/documentation/Cocoa/Conceptual/Documents/Tasks/FAQ.html#//apple_ref/doc/uid/20000954-1081485
+ (id) sharedInspectorController
{
	static GeniusInspectorController * sController = nil;
	if (sController == nil)
		sController = [[GeniusInspectorController alloc] initWithWindowNibName:@"GeniusInspector"];
	return sController;
}

- (NSDocument *) _currentDocument
{
	return [[NSDocumentController sharedDocumentController] currentDocument];
}


- (NSArrayController *) arrayController
{
	return [(GeniusDocument *)[self _currentDocument] itemArrayController];
}


+ (NSDictionary *) _defaultTextAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont userFontOfSize:12.0], NSFontAttributeName, [NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName, nil];
}

- (void) _setRichTextEnabled:(BOOL)flag forTextView:(NSTextView *)textView objectController:(NSObjectController *)controller
{
	// Unbind
	if (flag == YES)
		[textView unbind:NSValueBinding];
	else
		[textView unbind:NSDataBinding];

	[textView setRichText:flag];
	[textView setImportsGraphics:flag];
	[textView setUsesFontPanel:flag];
	
	// Clear rich text
	if (flag == NO)
	{
		NSDictionary * defaultTextAttributes = [GeniusInspectorController _defaultTextAttributes];
		
		NSMutableAttributedString * attrString = [textView textStorage];
		NSRange range = NSMakeRange(0, [attrString length]);		
		[attrString setAttributes:defaultTextAttributes range:range];

		[textView setTypingAttributes:defaultTextAttributes];

		[[controller content] setValue:nil forKey:@"rtfData"];	// clear out rtfData from atom too
	}
	
	// Rebind
	if (flag == YES)
		[textView bind:NSDataBinding toObject:controller withKeyPath:@"selection.rtfData" options:nil];
	else
		[textView bind:NSValueBinding toObject:controller withKeyPath:@"selection.string" options:nil];
}


- (void)windowDidLoad
{
	NSLog(@"-[GeniusInspectorController windowDidLoad]");
	[super windowDidLoad];
	
	GeniusDocumentInfo * documentInfo = [(GeniusDocument *)[self _currentDocument] documentInfo];
	[self _setRichTextEnabled:[documentInfo isColumnARichText] forTextView:atomATextView objectController:atomAController];
	[self _setRichTextEnabled:[documentInfo isColumnBRichText] forTextView:atomBTextView objectController:atomBController];

	[documentInfo addObserver:self forKeyPath:@"isColumnARichText" options:0L context:NULL];
	[documentInfo addObserver:self forKeyPath:@"isColumnBRichText" options:0L context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"isColumnARichText"])
	{
		BOOL flag = [(GeniusDocumentInfo *)object isColumnARichText];
		[self _setRichTextEnabled:flag forTextView:atomATextView objectController:atomAController];
	}
	else if ([keyPath isEqualToString:@"isColumnBRichText"])
	{
		BOOL flag = [(GeniusDocumentInfo *)object isColumnBRichText];
		[self _setRichTextEnabled:flag forTextView:atomBTextView objectController:atomBController];
	}
}


#if 0
/*
+ (BOOL) _attributedStringHasDefaultAttributes:(NSAttributedString *)attrString
{
	// See /Developer/Examples/AppKit/TextEdit/Document.m -toggleRich:
	int length = [attrString length];
	if (length == 0)
		return YES;
		
	NSRange range;
	NSDictionary *attrs = [attrString attributesAtIndex:0 effectiveRange:&range];
	if (attrs == nil)
		return YES;
	if (range.length < length)
		return NO;

	NSDictionary * defaultAttrs = [GeniusInspectorController _defaultTextAttributes];
	if ([attrs count] > [defaultAttrs count])
		return NO;

	NSEnumerator * keyEnumerator = [defaultAttrs keyEnumerator];
	NSString * key;
	while ((key = [keyEnumerator nextObject]))
	{
		id attr = [attrs objectForKey:key];
		id defaultAttr = [defaultAttrs objectForKey:key];
		if (attr && [attr isEqual:defaultAttr] == NO)
			return NO;
	}

	return YES;
}


-(BOOL) _validateToggleRichText:(id *)value forTextView:(NSTextView *)textView
{
	if ([*value boolValue] == NO)
	{
		if ([GeniusInspectorController _attributedStringHasDefaultAttributes:[textView textStorage]] == NO)
		{			
			NSAlert * alert = [NSAlert alertWithMessageText:@"Convert this column to plain text?" defaultButton:@"Convert" alternateButton:@"Don’t Convert" otherButton:nil
			informativeTextWithFormat:@"If you convert this column, you will lose all text styles (such as fonts and colors) and attachments."];
			//[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(_toggleRichTextAlertDidEndSelector:returnCode:contextInfo:) contextInfo:contextInfo];*/
			int returnCode = [alert runModal];
			if (returnCode == 0)	// No	// XXX: ??? should be NSAlertSecondButtonReturn
				*value = [NSNumber numberWithBool:YES];
		}
	}
	
	return YES;
}


- (BOOL) atomARichText
{
	return [atomATextView isRichText];
}

- (void) setAtomARichText:(BOOL)flag
{
	[self _setRichTextEnabled:flag forTextView:atomATextView objectController:atomAController];
}

-(BOOL)validateAtomARichText:(id *)value error:(NSError **)outError
{
	return [self _validateToggleRichText:value forTextView:atomATextView];
}


- (BOOL) atomBRichText
{
	return [atomBTextView isRichText];
}

- (void) setAtomBRichText:(BOOL)flag
{
	[self _setRichTextEnabled:flag forTextView:atomBTextView objectController:atomBController];
}

-(BOOL)validateAtomBRichText:(id *)value error:(NSError **)outError
{
	return [self _validateToggleRichText:value forTextView:atomBTextView];
}
*/
#endif

@end

