//
//  GSTableView.m
//  Genius
//
//  Created by Chris Miner on 20.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GSTableView.h"
#import "IconTextFieldCell.h"

@interface GSTableView(Private)
- (void) _showTableColumn:(NSTableColumn *)column;
- (void) _hideTableColumn:(NSTableColumn *)column;
- (NSArray *) _columnIdentifiersReorderedByDefaultOrder:(NSArray *)identifiers;
@end

//! Simple NSTableView subclass to handle column showing/hiding, delete, and tab keys.
@implementation GSTableView

//! init method used when unpacking paletized class (NSTableView for example) from a nib.
- (id) initWithCoder: (NSCoder *) coder
{
    self = [super initWithCoder:coder];
    if (self) {
        tableColumnCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

//! standard dealloc method releases column cache
- (void) dealloc
{
    [tableColumnCache release];
    [super dealloc];
}

//! Creates initial cache of columns for hide/show support and installs our custom IconFieldCell.
- (void) awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSTabularTextPboardType, nil]];
    [self setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
    
    // Retain all table columns in case we hide them later
    NSEnumerator * columnEnumerator = [[self tableColumns] objectEnumerator];
    NSTableColumn * column;
    while ((column = [columnEnumerator nextObject]))
    {
        NSString * identifier = [column identifier];
        if (identifier)
            [tableColumnCache setObject:column forKey:[column identifier]];
    }
    
    // Set up icon text field cells for colored score indication
    IconTextFieldCell * cell = [[[IconTextFieldCell alloc] init] autorelease];
    
    NSTableColumn * tableColumn = [self tableColumnWithIdentifier:@"scoreAB"];
    NSNumberFormatter * numberFormatter = [[tableColumn dataCell] formatter];
    [cell setFormatter:numberFormatter];
    [tableColumn setDataCell:cell];
    tableColumn = [self tableColumnWithIdentifier:@"scoreBA"];
    [tableColumn setDataCell:cell];
}

//! Initializes the displayed columns to those requested.
- (void) setVisibleColumns: (NSArray*) identifiers
{
    // Hide table columns that should not be visible, but are
    NSMutableSet * actualColumnIdentifiersSet = [NSMutableSet setWithArray:[self visibleColumnIdentifiers]];
    NSSet * expectedColumnIdentifierSet = [NSSet setWithArray:identifiers];
    [actualColumnIdentifiersSet minusSet:expectedColumnIdentifierSet];
    NSEnumerator * identifierToHideEnumerator = [actualColumnIdentifiersSet objectEnumerator];
    NSString * identifier;
    while ((identifier = [identifierToHideEnumerator nextObject]))
    {
        NSTableColumn * tableColumn = [self tableColumnWithIdentifier:identifier];
        [self _hideTableColumn:tableColumn];
    }
    
    // Show table columns that should be visible, but aren't
    NSEnumerator * expectedIdentifierEnumerator = [identifiers objectEnumerator];
    NSString * expectedIdentifier;
    while ((expectedIdentifier = [expectedIdentifierEnumerator nextObject]))
    {
        NSTableColumn * expectedColumn = [tableColumnCache objectForKey:expectedIdentifier];
        if ([[self tableColumns] containsObject:expectedColumn] == NO)
            [self _showTableColumn:expectedColumn];
    }
    
    [self sizeToFit];
}

//! Removes or adds the column identified by @a identifier to GeniusDocument#tableView
- (void) toggleColumnWithIdentifier: (NSString *)identifier
{
    NSTableColumn * column = [tableColumnCache objectForKey:identifier];
    if (column == nil)
        return; // not found
    
    NSArray * tableColumns = [self tableColumns];
    if ([tableColumns containsObject:column])
        [self _hideTableColumn:column];
    else
        [self _showTableColumn:column];
    
    [self sizeToFit];
}

//! Convenience method for getting the identifiers for the table columns that are currently visible.
- (NSArray *) visibleColumnIdentifiers
{
    // NSTableColumns -> NSStrings
    NSMutableArray * outIdentifiers = [NSMutableArray array];
    NSEnumerator * columnEnumerator = [[self tableColumns] objectEnumerator];
    NSTableColumn * column;
    while ((column = [columnEnumerator nextObject]))
        [outIdentifiers addObject:[column identifier]];
    return outIdentifiers;
}

//! Handle delete key.
- (void) deleteBackward: (id) sender
{
    if ([[self delegate] respondsToSelector:@selector(delete:)])
    {
        [[self delegate] performSelector:@selector(delete:) withObject:self];
    }
}

//! Handle tab key.
- (void) insertTab: (id) sender
{
    if ([[self delegate] respondsToSelector:@selector(selectSearchField:)])
    {
        [[self delegate] performSelector:@selector(selectSearchField:) withObject:self];
    }
}

//! Handle esc key.
- (void) cancelOperation: (id) sender
{
    if ([self currentEditor])
    {
        // save changes
        [[self window] endEditingFor:nil];
        
        // we lose focus so re-establish
        [[self window] makeFirstResponder:self];
    }
}

//! Standard 1st responder implementation.
- (void) keyDown: (NSEvent *) event
{
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

@end

//! Unexposed methods.
@implementation GSTableView(Private)

//! Removes @a column from GeniusDocument#tableView.
- (void) _hideTableColumn:(NSTableColumn *)column
{
    [self removeTableColumn:column];
}

//! Adds column to table.
- (void) _showTableColumn:(NSTableColumn *)column
{
    // Determine proper column position
    NSString * identifier = [column identifier];
    NSMutableArray * identifiers = [NSMutableArray arrayWithArray:[self visibleColumnIdentifiers]];
    [identifiers addObject:identifier];
    NSArray * orderedIdentifiers = [self _columnIdentifiersReorderedByDefaultOrder:identifiers];
    int index = [orderedIdentifiers indexOfObject:identifier];
    
    [self addTableColumn:column];
    [self moveColumn:[self numberOfColumns]-1 toColumn:index];
}

//! Convenience method for sorting standard identifiers.
- (NSArray *) _columnIdentifiersReorderedByDefaultOrder:(NSArray *)identifiers
{
    NSMutableArray * outIdentifiers = [NSMutableArray array];
    NSArray *_allColumnIdentifiers = [NSArray arrayWithObjects:@"disabled", @"columnA", @"columnB", @"customGroup", @"customType", @"scoreAB", @"scoreBA", nil];
    NSEnumerator * identifierEnumerator = [_allColumnIdentifiers objectEnumerator];
    NSString * identifier;
    while ((identifier = [identifierEnumerator nextObject]))
        if ([identifiers containsObject:identifier])
            [outIdentifiers addObject:identifier];
    return outIdentifiers;
}

@end