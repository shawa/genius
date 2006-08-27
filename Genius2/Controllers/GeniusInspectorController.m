//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusInspectorController.h"

#import "GeniusDocument.h"
//#import "GeniusDocumentInfo.h"	// -isColumnARichText, -isColumnBRichText

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

/*+ (NSDocument *) _currentDocument
{
	return [[NSDocumentController sharedDocumentController] currentDocument];
}*/


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
		/*NSArray * windowControllers = [lastDocument windowControllers];
		if ([windowControllers count] > 0)
			NSLog(@"GeniusInspectorController: Resigned document %@", [[[windowControllers objectAtIndex:0] window] title]);
		*/
/*		GeniusDocumentInfo * documentInfo = [lastDocument documentInfo];
		[documentInfo removeObserver:self forKeyPath:GeniusDocumentInfoIsColumnARichTextKey];
		[documentInfo removeObserver:self forKeyPath:GeniusDocumentInfoIsColumnBRichTextKey];
*/		
		if ([[sdc documents] count] == 0)
			[self close];
	}

	GeniusDocument * document = [sdc documentForWindow:mainWindow];
	[documentController setContent:document];	
	if (document)
	{
		//NSLog(@"GeniusInspectorController: Target document %@ (%@)", [mainWindow title], [document description]);

/*		GeniusDocumentInfo * documentInfo = [document documentInfo];
		[self _setRichTextEnabled:[documentInfo isColumnARichText] forTextView:atomATextView objectController:atomAController];
		[self _setRichTextEnabled:[documentInfo isColumnBRichText] forTextView:atomBTextView objectController:atomBController];
		[documentInfo addObserver:self forKeyPath:GeniusDocumentInfoIsColumnARichTextKey options:0L context:NULL];
		[documentInfo addObserver:self forKeyPath:GeniusDocumentInfoIsColumnBRichTextKey options:0L context:NULL];
*/	}
}

- (void)windowDidLoad
{	
    [super windowDidLoad];

    [self setMainWindow:[NSApp mainWindow]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];

	NSDateFormatter * df = [NSDateFormatter new];
	[df setFormatterBehavior:NSDateFormatterBehavior10_4];
	[df setDateStyle:NSDateFormatterMediumStyle];
	[df setTimeStyle:NSDateFormatterMediumStyle];
	[lastModifiedDateField setFormatter:df];
	[lastTestedDateField setFormatter:df];
	[df release];
}

- (void)mainWindowChanged:(NSNotification *)notification {
    [self setMainWindow:[notification object]];
}

- (void)mainWindowResigned:(NSNotification *)notification {
    [self setMainWindow:nil];
}


/*- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
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
}*/


- (NSTabView *) tabView
{
	return tabView;
}

@end


@implementation GeniusInspectorController (Private)

+ (NSDictionary *) _defaultTextAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:18.0], NSFontAttributeName, NULL];
/*	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont userFontOfSize:12.0], NSFontAttributeName,
		[NSParagraphStyle defaultParagraphStyle], NSParagraphStyleAttributeName, NULL];*/
}

- (void) _setRichTextEnabled:(BOOL)flag forTextView:(NSTextView *)textView objectController:(NSObjectController *)controller
{	
	// Unbind
	[textView unbind:NSValueBinding];
	[textView unbind:NSDataBinding];
//	[textView unbind:NSEditableBinding];

	// Change text view
	[textView setRichText:flag];
	[textView setImportsGraphics:flag];
	[textView setUsesFontPanel:flag];

	// Clear rich text
	if (flag == NO)
		[[controller content] setValue:nil forKey:GeniusAtomRTFDDataKey];	// clear out rtfdData from atom too
	
	// Rebind
	NSString * noSelectionString = NSLocalizedString(@"No selection", nil);
	if (flag == YES)
	{
		NSDictionary * options = nil;
		NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:18.0], NSFontAttributeName,
			NSForegroundColorAttributeName, [NSColor grayColor],
			NULL];
		NSAttributedString * attrString = [[[NSAttributedString alloc] initWithString:noSelectionString attributes:attributes] autorelease];
		if (attrString)
		{
			NSRange range = NSMakeRange(0, [attrString length]);
			NSData * noSelectionData = [attrString RTFDFromRange:range documentAttributes:nil];
			options = [NSDictionary dictionaryWithObject:noSelectionData forKey:NSNoSelectionPlaceholderBindingOption];
		}

		[textView bind:NSDataBinding toObject:controller withKeyPath:[NSString stringWithFormat:@"selection.%@", GeniusAtomRTFDDataKey] options:options];

/*		options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSNoSelectionPlaceholderBindingOption];
		[textView bind:NSEditableBinding toObject:controller withKeyPath:[NSString stringWithFormat:@"selection.%@", GeniusAtomRTFDDataKey] options:options];*/
	}
	else
	{
		NSDictionary * options = [NSDictionary dictionaryWithObject:noSelectionString forKey:NSNoSelectionPlaceholderBindingOption];
		[textView bind:NSValueBinding toObject:controller withKeyPath:[NSString stringWithFormat:@"selection.%@", GeniusAtomStringKey] options:options];		

/*		options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSNoSelectionPlaceholderBindingOption];
		[textView bind:NSEditableBinding toObject:controller withKeyPath:[NSString stringWithFormat:@"selection.%@", GeniusAtomStringKey] options:options];*/
	}

	// Set default text attributes
	NSDictionary * defaultTextAttributes = [GeniusInspectorController _defaultTextAttributes];
	NSMutableAttributedString * attrString = [textView textStorage];
	NSRange range = NSMakeRange(0, [attrString length]);		
	[attrString setAttributes:defaultTextAttributes range:range];
	[textView setTypingAttributes:defaultTextAttributes];
	[textView setAlignment:NSCenterTextAlignment];
	
	if ([textView isEditable])
		[textView selectAll:nil];
}

@end


@implementation GeniusInspectorController (NSWindowDelegate)

// Commit changes upon window deactivation

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	NSWindow * window = [self window];
	if ([window makeFirstResponder:window] == NO)
		[window endEditingFor:nil];	
}

@end


@implementation GeniusInspectorController (NSTabViewDelegate)

// Commit changes upon tab view item deactivation

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSWindow * window = [self window];
	if ([window makeFirstResponder:window] == NO)
		[window endEditingFor:nil];	
}

@end
