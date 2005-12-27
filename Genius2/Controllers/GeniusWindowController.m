//
//  GeniusWindowController.m
//  Genius2
//
//  Created by John R Chang on 2005-10-14.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusWindowController.h"

#import "GeniusDocument.h"
#import "GeniusInspectorController.h"

// Model
#import "GeniusAtom.h"	// +defaultTextAttributes

// View
#import "GeniusTableView.h"

// Widgets
#import "IconTextFieldCell.h"
#import "ColorView.h"
#import "CollapsableSplitView.h"
#import "ImageStringFormatter.h"


@implementation GeniusWindowController

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


//- (void)windowWillLoad

- (void)windowDidLoad
{
	// Tweak window appearance
	[[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.78 alpha:1.0]];
}

- (void) _setupTableViewDataCell:(NSCell *)cell
{
	// Set up line break mode for table columns
	[cell setLineBreakMode:NSLineBreakByTruncatingTail];

	// Print "[Image]" in strings with image characters
	static ImageStringFormatter * sStringFormatter = nil;
	if (sStringFormatter == nil)
		sStringFormatter = [ImageStringFormatter new];
    [cell setFormatter:sStringFormatter];
}

- (void) setupTableView:(NSTableView *)tableView withHeaderViewMenu:(NSMenu *)headerViewMenu
{
	NSTableColumn * tableColumn = [tableView tableColumnWithIdentifier:@"atomA"];
	[self _setupTableViewDataCell:[tableColumn dataCell]];

	tableColumn = [tableView tableColumnWithIdentifier:@"atomB"];
	[self _setupTableViewDataCell:[tableColumn dataCell]];

    // Set up icon text field cells for colored grade indication
    tableColumn = [tableView tableColumnWithIdentifier:@"grade"];
    IconTextFieldCell * cell = [IconTextFieldCell new];
    [tableColumn setDataCell:cell];
    //NSNumberFormatter * numberFormatter = [[tableColumn dataCell] formatter];
    //[cell setFormatter:numberFormatter];
	
	// Set up double-click action to handle uneditable rich text cells
	[tableView setDoubleAction:@selector(_tableViewDoubleAction:)];	

	// Wire View -> Columns menu to the custom table view's dynamic one
	NSString * viewTitle = NSLocalizedString(@"View", nil);
	NSMenuItem * viewMenuItem = [[NSApp mainMenu] itemWithTitle:viewTitle];
	
	NSString * columnsTitle = NSLocalizedString(@"Columns", nil);
	NSMenuItem * columnsMenuItem = [[viewMenuItem submenu] itemWithTitle:columnsTitle];

	[columnsMenuItem setSubmenu:[(GeniusTableView *)tableView toggleColumnsMenu]];
}

- (void) setupSplitView:(NSSplitView *)splitView
{
	[splitView setDelegate:self];

	NSView * bottomView = [[splitView subviews] objectAtIndex:1];
	[(ColorView *)bottomView setFrameColor:[NSColor colorWithCalibratedWhite:0.65 alpha:1.0]];

	[(CollapsableSplitView *)splitView collapseSubviewAt:1];
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

	NSString * fullKeyPath = [NSString stringWithFormat:@"%@.%@", keyPath, @"stringRTFDData"];
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

@end


@implementation GeniusWindowController (Actions)

// Edit menu

- (IBAction) selectSearchField:(id)sender
{
	[_searchField selectText:sender];
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
		[[self document] showRichTextEditor:sender];
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
		[[self document] showRichTextEditor:sender];
		[colorPanel makeKeyAndOrderFront:sender];
	}
}

@end


/*@implementation GeniusWindowController (NSMenuValidation)

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	
	return [super validateMenuItem:menuItem];
}

@end*/
