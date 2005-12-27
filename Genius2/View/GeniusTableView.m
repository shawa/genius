#import "GeniusTableView.h"


@interface GeniusTableHeaderView : NSTableHeaderView
@end


@implementation GeniusTableView

- (void) awakeFromNib
{
	// Retain table columns
	_allTableColumns = [NSMutableArray new];
	NSArray * tableColumns = [self tableColumns];
	NSEnumerator * tableColumnEnumerator = [tableColumns objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
		[_allTableColumns addObject:tableColumn];

	// Remove non-default table columns
	id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(tableViewDefaultHiddenTableColumnIdentifiers:)])
	{
		NSArray * hiddenIdentifiers = [delegate tableViewDefaultHiddenTableColumnIdentifiers:self];

		NSEnumerator * identifierEnumerator = [hiddenIdentifiers objectEnumerator];
		NSString * identifier;
		while ((identifier = [identifierEnumerator nextObject]))
		{
			tableColumn = [self tableColumnWithIdentifier:identifier];
			[self removeTableColumn:tableColumn];
		}

	}
	
	// Swap in custom header view to handle contextual menu
	NSTableHeaderView * oldHeaderView = [self headerView];
	GeniusTableHeaderView * headerView = [[GeniusTableHeaderView alloc] initWithFrame:[oldHeaderView frame]];
	[self setHeaderView:headerView];
	[headerView release];
}


#pragma mark -
// table view header contextual menu

- (NSMenu *) toggleColumnsMenu
{
	if (_toggleColumnsMenu == nil)
	{
		_toggleColumnsMenu = [[NSMenu alloc] initWithTitle:@""];
	
		// Patch in menu items
		NSSet * nonHiddenTableColumnSet = [NSSet setWithArray:[self tableColumns]];

		int i, count = [_allTableColumns count];				// both hidden and non-hidden
		for (i=0; i<count; i++)
		{
			NSTableColumn * tableColumn = [_allTableColumns objectAtIndex:i];
			
			NSString * title = [[tableColumn headerCell] title];
			if ([title isEqualToString:@""])
				continue;

			NSMenuItem * menuItem = [_toggleColumnsMenu addItemWithTitle:title action:@selector(toggleTableColumnShown:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setTag:i];
			[menuItem setState:([nonHiddenTableColumnSet containsObject:tableColumn] ? NSOnState : NSOffState)]; 
		}
	}
	
	return _toggleColumnsMenu;
}

- (IBAction) toggleTableColumnShown:(NSMenuItem *)sender
{
	int tag = [sender tag];
	NSTableColumn * tableColumn = [_allTableColumns objectAtIndex:tag];

	id delegate = [self delegate];
	
	int state = [sender state];			
	if (state == NSOnState)
	{
		[self removeTableColumn:tableColumn];	// hide

		if (delegate && [delegate respondsToSelector:@selector(tableView:didHideTableColumn:)])
			[delegate tableView:self didShowTableColumn:tableColumn];
	}
	else
	{
		// XXX: TO DO: add in order
		[self addTableColumn:tableColumn];		// show

		if (delegate && [delegate respondsToSelector:@selector(tableView:didShowTableColumn:)])
			[delegate tableView:self didShowTableColumn:tableColumn];
			
		[self sizeToFit];
	}
	
	[sender setState:(state == NSOffState ? NSOnState : NSOffState)];
}


#pragma mark -

- (NSArray *) _hiddenTableColumnIdentifiers
{
	NSMutableArray * tableColumnIdentifiers = [NSMutableArray array];
	NSSet * nonHiddenTableColumnSet = [NSSet setWithArray:[self tableColumns]];	// only non-hidden
	NSEnumerator * tableColumnEnumerator = [_allTableColumns objectEnumerator];	// both hidden and non-hidden
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
	{
		if ([nonHiddenTableColumnSet containsObject:tableColumn] == NO)
		{
			NSString * identifier = [tableColumn identifier];
			if (identifier)
				[tableColumnIdentifiers addObject:identifier];
		}
	}
	return tableColumnIdentifiers;
}

- (NSDictionary *)configurationDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[self _hiddenTableColumnIdentifiers], @"hiddenIdentifiers", NULL];
}

- (void)setConfigurationFromDictionary:(NSDictionary *)configDict
{
	NSArray * hiddenIdentifiers = [configDict objectForKey:@"hiddenIdentifiers"];
	if (hiddenIdentifiers)
	{
		// XXX: doesn't add relevant columns
		NSEnumerator * identifierEnumerator = [hiddenIdentifiers objectEnumerator];
		NSString * identifier;
		while ((identifier = [identifierEnumerator nextObject]))
		{
			NSTableColumn * tableColumn = [self tableColumnWithIdentifier:identifier];
			[self removeTableColumn:tableColumn];
		}
	}
}


#pragma mark -
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


@implementation GeniusTableHeaderView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	GeniusTableView * tableView = (GeniusTableView *)[self tableView];
	return [tableView toggleColumnsMenu];
}

@end
