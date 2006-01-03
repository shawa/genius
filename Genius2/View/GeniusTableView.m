#import "GeniusTableView.h"


@interface GeniusTableHeaderView : NSTableHeaderView
@end


static NSString * GeniusTableViewVisibleColumnIdentifiersConfigKey = @"VisibleColumnIdentifiers";

@implementation GeniusTableView

- (NSArray *) _currentIdentifiers
{
	NSMutableArray * allIdentifiers = [NSMutableArray array];
	NSArray * tableColumns = [self tableColumns];
	NSEnumerator * tableColumnEnumerator = [tableColumns objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
	{
		NSString * identifier = [tableColumn identifier];
		if (identifier)
			[allIdentifiers addObject:identifier];
	}
	return allIdentifiers;
}

- (void) _setVisibleTableColumnsWithIdentifiers:(NSArray *)visibleIdentifiers
{
}

- (void) awakeFromNib
{
	// Retain table columns
	_allTableColumns = [NSMutableArray new];
	NSArray * tableColumns = [self tableColumns];
	NSEnumerator * tableColumnEnumerator = [tableColumns objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
	{
		[_allTableColumns addObject:tableColumn];
	}

	// Remove non-default table columns
	id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(tableViewDefaultTableColumnIdentifiers:)])
	{
		NSMutableArray * hiddenIdentifiers = (NSMutableArray *)[self _currentIdentifiers];
		NSArray * visibleIdentifiers = [delegate tableViewDefaultTableColumnIdentifiers:self];
		[hiddenIdentifiers removeObjectsInArray:visibleIdentifiers];

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


+ (int) _positionOfObject:(id)object forInsertIntoArray:(NSArray *)array usingOrder:(NSArray *)orderArray
{
	int index = [orderArray indexOfObject:object];
	if (index == NSNotFound)
		return [array count];
	
	int i;
	for (i=index-1; i>=0; i--)
	{
		id anObject = [orderArray objectAtIndex:i];
		int pos = [array indexOfObject:anObject];
		if (pos != NSNotFound)
			return pos+1;
	}
	
	return 0;
}

- (IBAction) toggleTableColumnShown:(NSMenuItem *)sender
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
		[self addTableColumn:tableColumn];		// show

		// move to correct position
		int pos = [GeniusTableView _positionOfObject:tableColumn forInsertIntoArray:[self tableColumns] usingOrder:_allTableColumns];
		[self moveColumn:[self numberOfColumns]-1 toColumn:pos];

		if (delegate && [delegate respondsToSelector:@selector(tableView:didShowTableColumn:)])
			[delegate tableView:self didShowTableColumn:tableColumn];
			
		[self sizeToFit];
	}
	
	[sender setState:(state == NSOffState ? NSOnState : NSOffState)];
}


#pragma mark -

- (NSDictionary *)configurationDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[self _currentIdentifiers], GeniusTableViewVisibleColumnIdentifiersConfigKey, NULL];
}

- (void)setConfigurationFromDictionary:(NSDictionary *)configDict
{
	NSArray * currentIdentifiers = [self _currentIdentifiers];
	NSArray * visibleIdentifiers = [configDict objectForKey:GeniusTableViewVisibleColumnIdentifiersConfigKey];
	if (visibleIdentifiers)
	{		
		int i, count = [_allTableColumns count];
		for (i=0; i<count; i++)
		{
			NSTableColumn * tableColumn = [_allTableColumns objectAtIndex:i];
			NSString * identifier = [tableColumn identifier];
			if (identifier)
			{
				BOOL isVisible = [currentIdentifiers containsObject:identifier];
				BOOL shouldBeVisible = [visibleIdentifiers containsObject:identifier];
				
				if (shouldBeVisible && !isVisible)		// add
				{
					[self addTableColumn:tableColumn];
					[self moveColumn:[self numberOfColumns]-1 toColumn:i];
					[self sizeToFit];
				}
				else if (isVisible && !shouldBeVisible) // remove
				{
					[self removeTableColumn:tableColumn];
				}
			}
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
