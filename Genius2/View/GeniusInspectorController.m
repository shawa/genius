#import "GeniusInspectorController.h"

#import "GeniusDocument.h"
#import "GeniusDocumentInfo.h"	// -isColumnARichText, -isColumnBRichText

#import "GeniusAtom.h"


@interface GeniusInspectorController (Private)
- (void) _setRichTextEnabled:(BOOL)flag forTextView:(NSTextView *)textView objectController:(NSObjectController *)controller;
@end


@implementation GeniusInspectorController

// file:///Developer/ADC%20Reference%20Library/documentation/Cocoa/Conceptual/Documents/Tasks/FAQ.html#//apple_ref/doc/uid/20000954-1081485
+ (id) sharedInspectorController
{
	static GeniusInspectorController * sController = nil;
	if (sController == nil)
		sController = [[GeniusInspectorController alloc] initWithWindowNibName:@"Inspector"];
	return sController;
}

+ (NSDocument *) _currentDocument
{
	return [[NSDocumentController sharedDocumentController] currentDocument];
}


- (void) dealloc
{
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];

	[super dealloc];
}


// See /Developer/Examples/AppKit/Sketch/SKTInspectorController.m
- (void)setMainWindow:(NSWindow *)mainWindow {
	NSDocumentController * sdc = [NSDocumentController sharedDocumentController];

	GeniusDocument * lastDocument = [documentController content];
	if (lastDocument)
	{
		NSArray * windowControllers = [lastDocument windowControllers];
		if ([windowControllers count] > 0)
			NSLog(@"GeniusInspectorController: Resigned document %@", [[[windowControllers objectAtIndex:0] window] title]);
		
		GeniusDocumentInfo * documentInfo = [lastDocument documentInfo];
		[documentInfo removeObserver:self forKeyPath:GeniusDocumentInfoIsColumnARichTextKey];
		[documentInfo removeObserver:self forKeyPath:GeniusDocumentInfoIsColumnBRichTextKey];
		
		if ([[sdc documents] count] == 0)
			[self close];
	}

	GeniusDocument * document = [sdc documentForWindow:mainWindow];
	[documentController setContent:document];	
	if (document)
	{
		NSLog(@"GeniusInspectorController: Target document %@", [mainWindow title]);

		GeniusDocumentInfo * documentInfo = [document documentInfo];
		[self _setRichTextEnabled:[documentInfo isColumnARichText] forTextView:atomATextView objectController:atomAController];
		[self _setRichTextEnabled:[documentInfo isColumnBRichText] forTextView:atomBTextView objectController:atomBController];
		[documentInfo addObserver:self forKeyPath:GeniusDocumentInfoIsColumnARichTextKey options:0L context:NULL];
		[documentInfo addObserver:self forKeyPath:GeniusDocumentInfoIsColumnBRichTextKey options:0L context:NULL];
	}
}

- (void)windowDidLoad
{	
    [super windowDidLoad];

    [self setMainWindow:[NSApp mainWindow]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
}

- (void)mainWindowChanged:(NSNotification *)notification {
    [self setMainWindow:[notification object]];
}

- (void)mainWindowResigned:(NSNotification *)notification {
    [self setMainWindow:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:GeniusDocumentInfoIsColumnARichTextKey])
	{
		BOOL flag = [(GeniusDocumentInfo *)object isColumnARichText];
		[self _setRichTextEnabled:flag forTextView:atomATextView objectController:atomAController];
	}
	else if ([keyPath isEqualToString:GeniusDocumentInfoIsColumnBRichTextKey])
	{
		BOOL flag = [(GeniusDocumentInfo *)object isColumnBRichText];
		[self _setRichTextEnabled:flag forTextView:atomBTextView objectController:atomBController];
	}
}

@end


@implementation GeniusInspectorController (Private)

+ (NSDictionary *) _defaultTextAttributes
{
	NSMutableParagraphStyle * paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont userFontOfSize:12.0], NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
}

- (void) _setRichTextEnabled:(BOOL)flag forTextView:(NSTextView *)textView objectController:(NSObjectController *)controller
{
	// Unbind
	[textView unbind:NSValueBinding];
	[textView unbind:NSDataBinding];

	// Change text view
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

		[[controller content] setValue:nil forKey:GeniusAtomRTFDDataKey];	// clear out rtfdData from atom too
	}
	
	// Rebind
	if (flag == YES)
		[textView bind:NSDataBinding toObject:controller withKeyPath:[NSString stringWithFormat:@"selection.%@", GeniusAtomRTFDDataKey] options:nil];
	else
		[textView bind:NSValueBinding toObject:controller withKeyPath:[NSString stringWithFormat:@"selection.%@", GeniusAtomStringKey] options:nil];
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

