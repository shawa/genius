//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusWindowController.h"

#import "GeniusDocument.h"
#import "GeniusInspectorController.h"
#import "GeniusPreferences.h"

// Model
#import "GeniusAtom.h"	// +defaultTextAttributes
#import "GeniusItem.h"	// GeniusItemAtomAKey, GeniusItemAtomBKey, GeniusItemDisplayGradeKey, ...

// View
#import "GeniusTableView.h"

// Widgets
#import "IconTextFieldCell.h"
#import "ColorView.h"
#import "KFSplitView.h"
#import "ImageStringFormatter.h"


@interface GeniusWindowController (Private)
- (void) _handleUserDefaultsDidChange:(NSNotification *)aNotification;
@end


@implementation GeniusWindowController

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_splitView release];
	[_tableView release];
	[_defaultColumnsMenu release];
	[super dealloc];
}


//- (void)windowWillLoad

- (void)windowDidLoad
{
	// Tweak window appearance
	[[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.78 alpha:1.0]];
	
	[[self window] setDelegate:self];

	// Configure list font size
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(_handleUserDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
	[self _handleUserDefaultsDidChange:nil];
}

- (void) _setupCellForAtomTableColumn:(NSTableColumn *)tableColumn
{
	NSCell * cell = [tableColumn dataCell];
	
	// Set up line break mode for table columns
	[cell setLineBreakMode:NSLineBreakByTruncatingTail];

	// Print "[Image]" in strings with image characters
	static ImageStringFormatter * sStringFormatter = nil;
	if (sStringFormatter == nil)
		sStringFormatter = [ImageStringFormatter new];
    [cell setFormatter:sStringFormatter];
}

- (void) _setupCellForDateTableColumn:(NSTableColumn *)tableColumn
{
	NSCell * cell = [tableColumn dataCell];

	// Set up date formatter
	static NSDateFormatter * sDateFormatter = nil;
	if (sDateFormatter == nil)
	{
		sDateFormatter = [NSDateFormatter new];
		[sDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[sDateFormatter setDateStyle:NSDateFormatterShortStyle];
		[sDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
    [cell setFormatter:sDateFormatter];
}

- (void) setupTableView:(NSTableView *)tableView
{
	NSTableColumn * tableColumn = [tableView tableColumnWithIdentifier:GeniusItemAtomAKey];
	[self _setupCellForAtomTableColumn:tableColumn];

	tableColumn = [tableView tableColumnWithIdentifier:GeniusItemAtomBKey];
	[self _setupCellForAtomTableColumn:tableColumn];

    // Set up icon text field cells for colored grade indication
    tableColumn = [tableView tableColumnWithIdentifier:GeniusItemDisplayGradeKey];
    IconTextFieldCell * cell = [IconTextFieldCell new];
    [tableColumn setDataCell:cell];
    //NSNumberFormatter * numberFormatter = [[tableColumn dataCell] formatter];
    //[cell setFormatter:numberFormatter];
	
	// Set up double-click action to handle uneditable rich text cells
//	[tableView setDoubleAction:@selector(_tableViewDoubleAction:)];		// XXX

    tableColumn = [tableView tableColumnWithIdentifier:GeniusItemLastTestedDateKey];
	[self _setupCellForDateTableColumn:tableColumn];

    tableColumn = [tableView tableColumnWithIdentifier:GeniusItemLastModifiedDateKey];
	[self _setupCellForDateTableColumn:tableColumn];

	
	_tableView = [tableView retain];
	
	_defaultColumnsMenu = [[_tableView toggleColumnsMenu] copy];
/*	NSEnumerator * menuItemEnumerator = [[_defaultColumnsMenu itemArray] objectEnumerator];
	NSMenuItem * menuItem;
	while ((menuItem = [menuItemEnumerator nextObject]))
	{
	}*/
}

- (void) setupSplitView:(NSSplitView *)splitView
{
	//[splitView setDelegate:self];

	NSView * bottomView = [[splitView subviews] objectAtIndex:1];
	[(ColorView *)bottomView setFrameColor:[NSColor colorWithCalibratedWhite:0.65 alpha:1.0]];

	_splitView = [splitView retain];
	//[_splitView collapseSubviewAt:1];
	[_splitView setSubview:bottomView isCollapsed:YES];
	[_splitView resizeSubviewsWithOldSize:[_splitView bounds].size];
}

- (void) setupAtomTextView:(NSTextView *)textView
{
	[textView setAlignment:NSCenterTextAlignment];
}


+ (NSData *) _noSelectionPlaceholderData
{
	static NSData * sData = nil;
	if (sData == nil)
	{
		NSString * noSelectionString = NSLocalizedString(@"No selection", nil);

		// noSelectionString -> noSelectionAttrString
		NSMutableDictionary * attribs = [[[GeniusAtom defaultTextAttributes] mutableCopy] autorelease];
		[attribs setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		[attribs setObject:[NSFont systemFontOfSize:24.0] forKey:NSFontAttributeName];
		NSAttributedString * noSelectionAttrString = [[[NSAttributedString alloc] initWithString:noSelectionString attributes:attribs] autorelease];

		// noSelectionAttrString -> noSelectionData
		if (noSelectionAttrString)
		{
			NSRange range = NSMakeRange(0, [noSelectionAttrString length]);
			sData = [[noSelectionAttrString RTFDFromRange:range documentAttributes:nil] retain];
		}
	}
	return sData;
}

// In order to set NSNoSelectionPlaceholderBindingOption
- (void) bindTextView:(NSTextView *)textView toController:(id)observableController withKeyPath:(NSString *)keyPath;
{
	NSDictionary * options = nil;
	NSData * noSelectionPlaceholderData = [GeniusWindowController _noSelectionPlaceholderData];
	if (noSelectionPlaceholderData)
		options = [NSDictionary dictionaryWithObject:noSelectionPlaceholderData forKey:NSNoSelectionPlaceholderBindingOption];

	NSString * fullKeyPath = [NSString stringWithFormat:@"%@.%@", keyPath, GeniusAtomStringRTDDataKey];
	[textView bind:NSDataBinding toObject:observableController withKeyPath:fullKeyPath options:options];	
}


+ (float) listTextFontSizeForSizeMode:(int)mode
{
	// IB: 11/14, 13/17  -- iTunes: 11/15, 13/18

	switch (mode)
	{
		case 0:
			return [NSFont smallSystemFontSize];
		case 1:
			return [NSFont systemFontSize];
		case 2:
			return 15.0;
	}
	
	return [NSFont systemFontSize];
}

+ (float) rowHeightForSizeMode:(int)mode
{
	switch (mode)
	{
		case 0:
			return [NSFont smallSystemFontSize] + 4.0;
		case 1:
			return [NSFont systemFontSize] + 5.0;
		case 2:
			return 15.0 + 6.0;
	}
	
	return [NSFont systemFontSize];
}

- (void) _handleUserDefaultsDidChange:(NSNotification *)aNotification
{	
	// _dismissFieldEditor
	NSWindow * window = [self window];
	if ([window makeFirstResponder:window] == NO)
		[window endEditingFor:nil];
	
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	// Handle font size
	int mode = [ud integerForKey:GeniusPreferencesListTextSizeModeKey];
	float fontSize = [GeniusWindowController listTextFontSizeForSizeMode:mode];

	float rowHeight = [GeniusWindowController rowHeightForSizeMode:mode];
	[_tableView setRowHeight:rowHeight];

	NSEnumerator * tableColumnEnumerator = [[_tableView tableColumns] objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
		[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:fontSize]];
}

@end


/*@implementation GeniusWindowController (NSResponder)

- (void)keyDown:(NSEvent *)theEvent
{
	BOOL result = NO;
	if ([[self document] respondsToSelector:@selector(performKeyDown:)])
		result = [[self document] performKeyDown:theEvent];
		
	if (result == NO)
		[super keyDown:theEvent];
}

@end*/


@implementation GeniusWindowController (Actions)

// Edit menu

- (IBAction) selectSearchField:(id)sender
{
	[_searchField selectText:sender];
}


// View menu

- (IBAction) showRichTextEditor:(id)sender
{
	NSView * bottomView = [[_splitView subviews] objectAtIndex:1];

	//[_splitView uncollapseSubviewAt:1];
	[_splitView setSubview:bottomView isCollapsed:NO];
	[_splitView resizeSubviewsWithOldSize:[_splitView bounds].size];
	
/*	int i;
	for (i=0; i<3; i++)
	{
		[bottomView setFrameSize:NSMakeSize([_splitView frame].size.width, 128.0)];
		[_splitView adjustSubviews];
		[_splitView displayIfNeeded];
	}*/
}


// Item menu

- (IBAction) toggleInspector:(id)sender
{
//	[self _dismissFieldEditor];

	GeniusInspectorController * ic = [GeniusInspectorController sharedInspectorController];
	if ([[ic window] isVisible])
		[[ic window] performClose:sender];
	else
		[ic showWindow:sender];
}

// Toolbar

- (IBAction) toggleFontPanel:(id)sender
{
	NSFontPanel * fontPanel = [NSFontPanel sharedFontPanel];
	if ([fontPanel isVisible])
		[fontPanel performClose:sender];
	else
	{
		[self showRichTextEditor:sender];
		[fontPanel makeKeyAndOrderFront:sender];
	}
}

- (IBAction) toggleColorPanel:(id)sender
{
	NSColorPanel * colorPanel = [NSColorPanel sharedColorPanel];
	if ([colorPanel isVisible])
		[colorPanel performClose:sender];
	else
	{
		[self showRichTextEditor:sender];
		[colorPanel makeKeyAndOrderFront:sender];
	}
}

@end


@implementation GeniusWindowController (NSWindowDelegate)

- (NSMenuItem *) _columnsMenuItem
{
	// Wire View -> Columns menu to the custom table view's dynamic one
	NSString * viewTitle = NSLocalizedString(@"View", nil);
	NSMenuItem * viewMenuItem = [[NSApp mainMenu] itemWithTitle:viewTitle];
	
	NSString * columnsTitle = NSLocalizedString(@"Columns", nil);
	NSMenuItem * columnsMenuItem = [[viewMenuItem submenu] itemWithTitle:columnsTitle];

	return columnsMenuItem;
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	NSMenuItem * columnsMenuItem = [self _columnsMenuItem];
	[columnsMenuItem setSubmenu:[_tableView toggleColumnsMenu]];
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
	NSMenuItem * columnsMenuItem = [self _columnsMenuItem];
	[columnsMenuItem setSubmenu:_defaultColumnsMenu];
}

/*- (void)windowDidResignKey:(NSNotification *)aNotification
{
	if ([[NSApp keyWindow] isKindOfClass:[NSPanel class]])
		[self _dismissFieldEditor];
}*/

@end


/*@implementation GeniusWindowController (NSMenuValidation)

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	
	return [super validateMenuItem:menuItem];
}

@end*/


@implementation GeniusWindowController (NSSplitViewDelegate)

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	return YES;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	return proposedMin;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	NSSize size = [sender frame].size;	
	return size.height - 100.0;
}

@end
