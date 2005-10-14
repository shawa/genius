#import "GeniusTableView.h"


//NSString * GeniusTableViewHiddenTableColumnsDidChangeNotification = @"GeniusTableViewHiddenTableColumnsDidChangeNotification";


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
	if (delegate && [delegate respondsToSelector:@selector(tableViewHiddenTableColumnIdentifiers:)])
	{
		NSArray * hiddenTableColumnIdentifiers = [delegate tableViewHiddenTableColumnIdentifiers:self];

		NSEnumerator * identifierEnumerator = [hiddenTableColumnIdentifiers objectEnumerator];
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


- (NSArray *) allTableColumns
{
	return _allTableColumns;
}

- (NSArray *) hiddenTableColumnIdentifiers
{
	NSMutableArray * tableColumnIdentifiers = [NSMutableArray array];
	NSSet * nonHiddenTableColumnSet = [NSSet setWithArray:[self tableColumns]];	// only non-hidden
	NSArray * tableColumns = [self allTableColumns];							// both hidden and non-hidden
	NSEnumerator * tableColumnEnumerator = [tableColumns objectEnumerator];
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
	}
	else
	{
		// TO DO: add in order
		[self addTableColumn:tableColumn];		// show

		if (delegate && [delegate respondsToSelector:@selector(tableView:didShowTableColumn:)])
			[delegate tableView:self didShowTableColumn:tableColumn];
			
/*		NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:GeniusTableViewHiddenTableColumnsDidChangeNotification object:self];*/
	}
	
	[sender setState:(state == NSOffState ? NSOnState : NSOffState)];
	
/*	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:GeniusTableViewHiddenTableColumnsDidChangeNotification object:self];*/

	if (delegate && [delegate respondsToSelector:@selector(tableView:setHiddenTableColumnIdentifiers:)])
	{
		NSArray * hiddenIdentifiers = [self hiddenTableColumnIdentifiers];
		[delegate tableView:self setHiddenTableColumnIdentifiers:hiddenIdentifiers];
	}
}


// Handle delete:
- (void)keyDown:(NSEvent *)theEvent
{	
    if ([theEvent keyCode] == 51 && [theEvent modifierFlags] == 0)       // Delete
    {
        id delegate = [self delegate];
        if (delegate && [delegate respondsToSelector:@selector(delete:)])
        {
            [delegate delete:self];
            return;
        }
    }
}

@end


@implementation GeniusTableHeaderView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@""];

	GeniusTableView * tableView = (GeniusTableView *)[self tableView];
	NSSet * nonHiddenTableColumnSet = [NSSet setWithArray:[tableView tableColumns]];

	NSArray * tableColumns = [tableView allTableColumns];	// both hidden and non-hidden
	int i, count = [tableColumns count];
	for (i=0; i<count; i++)
	{
		NSTableColumn * tableColumn = [tableColumns objectAtIndex:i];
		
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
