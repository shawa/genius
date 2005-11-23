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

// Widgets
#import "IconTextFieldCell.h"
#import "ColorView.h"
#import "CollapsableSplitView.h"


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

- (void) setupTableView:(NSTableView *)tableView withHeaderViewMenu:(NSMenu *)headerViewMenu
{
	// Set up line break mode for table columns
	NSTableColumn * tableColumn = [tableView tableColumnWithIdentifier:@"atomA"];
	[[tableColumn dataCell] setLineBreakMode:NSLineBreakByTruncatingTail];

	tableColumn = [tableView tableColumnWithIdentifier:@"atomB"];
	[[tableColumn dataCell] setLineBreakMode:NSLineBreakByTruncatingTail];
	
    // Set up icon text field cells for colored grade indication
    tableColumn = [tableView tableColumnWithIdentifier:@"grade"];
    IconTextFieldCell * cell = [IconTextFieldCell new];
    [tableColumn setDataCell:cell];
    //NSNumberFormatter * numberFormatter = [[tableColumn dataCell] formatter];
    //[cell setFormatter:numberFormatter];
	
	// Set up double-click action to handle uneditable rich text cells
//	[tableView setDoubleAction:@selector(_tableViewDoubleAction:)];	
}

- (void) setupSplitView:(NSSplitView *)splitView
{
	[splitView setDelegate:self];

	NSView * bottomView = [[splitView subviews] objectAtIndex:1];
	[(ColorView *)bottomView setFrameColor:[NSColor colorWithCalibratedWhite:0.65 alpha:1.0]];

	[(CollapsableSplitView *)splitView collapseSubviewAt:1];
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

@end


@implementation GeniusWindowController (NSSplitViewDelegate)

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	if ([[sender subviews] indexOfObject:subview] == 1)
		return YES;
	return NO;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	return 0.0;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	return proposedMax - 100.0;
}

@end
