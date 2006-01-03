#import "CustomizableTableView.h"


@interface CustomTableHeaderView : NSTableHeaderView
@end


static NSString * CustomizableTableViewVisibleColumnIdentifiersConfigKey = @"VisibleColumnIdentifiers";
static NSString * CustomizableTableViewColumnHeaderDictConfigKey = @"ColumnHeaderDict";

@implementation CustomizableTableView

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

- (NSArray *) _currentIdentifiers
{
	NSMutableArray * allIdentifiers = [NSMutableArray array];
	NSArray * tableColumns = [self tableColumns];
	NSEnumerator * tableColumnEnumerator = [tableColumns objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
	{
		NSString * identifier = [tableColumn identifier];
		if (identifier == nil)
			identifier = [[tableColumn headerCell] stringValue];

		if (identifier)
			[allIdentifiers addObject:identifier];
	}
	return allIdentifiers;
}


- (void) awakeFromNib
{
	// Retain all table columns from nib
	_allTableColumns = [NSMutableArray new];
	NSEnumerator * tableColumnEnumerator = [[self tableColumns] objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
		[(NSMutableArray *)_allTableColumns addObject:tableColumn];

	// Remove non-default table columns
	id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(tableViewDefaultTableColumnIdentifiers:)])
	{
		// Get hiddenIdentifiers
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
	
	_configDict = nil;
	
	// Swap in custom header view to handle contextual menu
	NSTableHeaderView * oldHeaderView = [self headerView];
	CustomTableHeaderView * headerView = [[CustomTableHeaderView alloc] initWithFrame:[oldHeaderView frame]];
	[self setHeaderView:headerView];
	[headerView release];


    [self setDoubleAction:@selector(_doubleClick:)];   // Make editable
    [self setTarget:self];
}


#pragma mark -

- (NSMutableDictionary *) _configDict
{
	if (_configDict == nil)
		_configDict = [NSMutableDictionary new];
	return _configDict;
}

- (NSDictionary *)configurationDictionary
{
	return _configDict;
}

- (void)setConfigurationFromDictionary:(NSDictionary *)configDict
{
	// Update from CustomizableTableViewVisibleColumnIdentifiersConfigKey
	NSArray * currentIdentifiers = [self _currentIdentifiers];
	NSArray * visibleIdentifiers = [configDict objectForKey:CustomizableTableViewVisibleColumnIdentifiersConfigKey];
	int i, count = [_allTableColumns count];
	for (i=0; i<count; i++)
	{
		NSTableColumn * tableColumn = [_allTableColumns objectAtIndex:i];
		NSString * identifier = [tableColumn identifier];
		if (identifier == nil)
			identifier = [[tableColumn headerCell] stringValue];

		if (identifier)
		{
			BOOL shouldBeVisible = visibleIdentifiers ? [visibleIdentifiers containsObject:identifier] : YES;
			BOOL isVisible = [currentIdentifiers containsObject:identifier];
			
			if (shouldBeVisible && !isVisible)		// add
			{
				[self addTableColumn:tableColumn];
				int pos = [CustomizableTableView _positionOfObject:tableColumn forInsertIntoArray:[self tableColumns] usingOrder:_allTableColumns];
				[self moveColumn:[self numberOfColumns]-1 toColumn:pos];
			}
			else if (isVisible && !shouldBeVisible) // remove
			{
				[self removeTableColumn:tableColumn];
			}
		}
	}
	[self sizeToFit];
	
	// Update from CustomizableTableViewColumnHeaderDictConfigKey
	NSDictionary * columnHeaderDict = [configDict objectForKey:CustomizableTableViewColumnHeaderDictConfigKey];
	NSEnumerator * identifierEnumerator = [columnHeaderDict keyEnumerator];
	NSString * identifier;
	while ((identifier = [identifierEnumerator nextObject]))
	{
		NSTableColumn * tableColumn = [self tableColumnWithIdentifier:identifier];
		if (tableColumn)
		{
			NSString * title = [columnHeaderDict objectForKey:identifier];
			[[tableColumn headerCell] setTitle:title];
		}
	}
	
	[_configDict release];
	_configDict = [configDict retain];
	
	[_toggleColumnsMenu release];
	_toggleColumnsMenu = nil;
}


#pragma mark -
// table view header contextual menu

- (NSMenu *) toggleColumnsMenu
{
	if (_toggleColumnsMenu == nil)
	{
		_toggleColumnsMenu = [[NSMenu alloc] initWithTitle:@""];
	
		// Patch in menu items
		NSArray * currentTableColumns = [self tableColumns];

		int i, count = [_allTableColumns count];				// both hidden and non-hidden
		for (i=0; i<count; i++)
		{
			NSTableColumn * tableColumn = [_allTableColumns objectAtIndex:i];
			
			NSString * title = [[tableColumn headerCell] title];
			if ([title isEqualToString:@""])
				continue;

			NSMenuItem * menuItem = [_toggleColumnsMenu addItemWithTitle:title action:@selector(_toggleTableColumnShown:) keyEquivalent:@""];
			[menuItem setTag:i];
			[menuItem setTarget:self];
			[menuItem setState:([currentTableColumns containsObject:tableColumn] ? NSOnState : NSOffState)]; 
		}
	}
	
	return _toggleColumnsMenu;
}

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
		[self addTableColumn:tableColumn];		// show

		// move to correct position
		int pos = [CustomizableTableView _positionOfObject:tableColumn forInsertIntoArray:[self tableColumns] usingOrder:_allTableColumns];
		[self moveColumn:[self numberOfColumns]-1 toColumn:pos];
			
		[self sizeToFit];
	}
	
	[sender setState:(state == NSOffState ? NSOnState : NSOffState)];	

	// note that delegate may call -configurationDictionary so this needs to come first
	[[self _configDict] setObject:[self _currentIdentifiers] forKey:CustomizableTableViewVisibleColumnIdentifiersConfigKey];

	// notify delegate
	if (state == NSOnState)
	{
		if (delegate && [delegate respondsToSelector:@selector(tableView:didHideTableColumn:)])
			[delegate tableView:self didHideTableColumn:tableColumn];
	}
	else
	{
		if (delegate && [delegate respondsToSelector:@selector(tableView:didShowTableColumn:)])
			[delegate tableView:self didShowTableColumn:tableColumn];
	}
}

@end


@implementation CustomizableTableView (EditableColumnTitles)

static NSTableColumn * sDuringEditTableColumn = nil;

- (void) _doubleClick:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    BOOL succeed = [[self window] makeFirstResponder:[self window]];
    if (!succeed)
        [[self window] endEditingFor:nil];

    int columnIndex = [sender clickedColumn];
    NSTableColumn * tableColumn = [[sender tableColumns] objectAtIndex:columnIndex];
    
    if ([self delegate] == nil)
        return;
    if ([[self delegate] respondsToSelector:@selector(tableView:shouldChangeHeaderTitleOfTableColumn:)])
    {
        BOOL shouldChange = (unsigned long)[[self delegate] performSelector:@selector(tableView:shouldChangeHeaderTitleOfTableColumn:) withObject:self withObject:tableColumn];
        if (shouldChange && [tableColumn identifier] != nil)
		{
			NSTableHeaderCell * cell = [tableColumn headerCell];
			NSString * string = [[cell title] copy];
			[cell setEditable:YES];
			[cell setTitle:@""];    
			
			NSTableHeaderView * headerView = [sender headerView];
			NSText * editor = [[headerView window] fieldEditor:YES forObject:cell];
			NSRect rect = [headerView headerRectOfColumn:columnIndex];
			rect.origin.y += 1;

			sDuringEditTableColumn = tableColumn;
			[cell editWithFrame:rect inView:headerView editor:editor delegate:self event:nil];
			
			[editor setString:string];
			[editor selectAll:self];
			[string release];
		}
    }
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    if (sDuringEditTableColumn == nil)
    {
        [super textDidEndEditing:aNotification];
        return;
    }
        
    NSText * aTextObject = [aNotification object];
    NSString * string = [[aTextObject string] copy];
    
    NSTableHeaderCell * cell = [sDuringEditTableColumn headerCell];
    [cell endEditing:aTextObject];
    
    [cell setTitle:string];

	// Update CustomizableTableViewColumnHeaderDictConfigKey
	NSMutableDictionary * columnHeaders = [[[self _configDict] objectForKey:CustomizableTableViewColumnHeaderDictConfigKey] mutableCopy];
	if (columnHeaders == nil)
		columnHeaders = [NSMutableDictionary new];
	[columnHeaders setObject:string forKey:[sDuringEditTableColumn identifier]];
	[[self _configDict] setObject:columnHeaders forKey:CustomizableTableViewColumnHeaderDictConfigKey];
    [columnHeaders release];
	
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(tableView:didChangeHeaderTitleOfTableColumn:)])
        [[self delegate] performSelector:@selector(tableView:didChangeHeaderTitleOfTableColumn:) withObject:self withObject:sDuringEditTableColumn];
        
    [string release];
    sDuringEditTableColumn = nil;
}

@end


@implementation CustomTableHeaderView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	CustomizableTableView * tableView = (CustomizableTableView *)[self tableView];
	return [tableView toggleColumnsMenu];
}

@end
