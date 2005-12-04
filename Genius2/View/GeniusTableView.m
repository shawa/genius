#import "GeniusTableView.h"


//NSString * GeniusTableViewHiddenTableColumnsDidChangeNotification = @"GeniusTableViewHiddenTableColumnsDidChangeNotification";


@interface GeniusTableHeaderView : NSTableHeaderView
@end

@interface GeniusTableView (Private)
- (NSArray *) _allTableColumns;
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
			NSTableColumn * tableColumn = [self tableColumnWithIdentifier:identifier];
			[self removeTableColumn:tableColumn];
		}

	}
	
	// Swap in custom header view to handle contextual menu
	NSTableHeaderView * oldHeaderView = [self headerView];
	GeniusTableHeaderView * headerView = [[GeniusTableHeaderView alloc] initWithFrame:[oldHeaderView frame]];
	[self setHeaderView:headerView];
	[headerView release];
}


- (NSArray *) _allTableColumns
{
	return _allTableColumns;
}

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


// table view header contextual menu

- (IBAction) _toggleTableColumnShown:(NSMenuItem *)sender
{
	int index = [sender tag];
	NSTableColumn * tableColumn = [_allTableColumns objectAtIndex:index];

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


// Handle delete:
- (void)keyDown:(NSEvent *)theEvent
{	
    if ([theEvent keyCode] == 51 &&
		([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask == 0))	// Delete
    {	
        id delegate = [self delegate];
        if (delegate && [delegate respondsToSelector:@selector(delete:)])
        {
            [delegate delete:self];
            return;
        }
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
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@""];

	GeniusTableView * tableView = (GeniusTableView *)[self tableView];
	NSSet * nonHiddenTableColumnSet = [NSSet setWithArray:[tableView tableColumns]];

	NSArray * allTableColumns = [tableView _allTableColumns];				// both hidden and non-hidden
	int i, count = [allTableColumns count];
	for (i=0; i<count; i++)
	{
		NSTableColumn * tableColumn = [allTableColumns objectAtIndex:i];
		
		NSString * title = [[tableColumn headerCell] title];
		if ([title isEqualToString:@""])
			continue;

		NSMenuItem * menuItem = [menu addItemWithTitle:title action:@selector(_toggleTableColumnShown:) keyEquivalent:@""];
		[menuItem setTarget:tableView];
		[menuItem setTag:i];
		[menuItem setState:([nonHiddenTableColumnSet containsObject:tableColumn] ? NSOnState : NSOffState)]; 
	}

	return menu;
}

@end
