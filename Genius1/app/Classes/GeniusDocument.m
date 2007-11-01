/*
	Genius
	Copyright (C) 2003-2006 John R Chang

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.	

	http://www.gnu.org/licenses/gpl.txt
*/

#import "GeniusDocument.h"
#import "GeniusDocumentPrivate.h"
#import "GeniusDocumentFile.h"
#import "IconTextFieldCell.h"
#import "GeniusToolbar.h"
#import "GeniusItem.h"
#import "GeniusAssociationEnumerator.h"
#import "MyQuizController.h"
#import "NSArrayGeniusAdditions.h"
#import "GeniusPreferencesController.h"


@interface IsPairImportantTransformer : NSValueTransformer
@end
@implementation IsPairImportantTransformer
+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)supportsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    int importance = [value intValue];
    return [NSNumber numberWithBool:(importance > kGeniusPairNormalImportance) ? YES : NO];
}
@end

@interface ColorFromPairImportanceTransformer : NSValueTransformer
@end
@implementation ColorFromPairImportanceTransformer
+ (Class)transformedValueClass { return [NSColor class]; }
+ (BOOL)supportsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    int importance = [value intValue];
    if (importance == kGeniusPairMaximumImportance)
        return [NSColor redColor];
    else if (importance < kGeniusPairNormalImportance)
        return [NSColor darkGrayColor];
    else
        return [NSColor blackColor];
}
@end


@interface GeniusDocument (VeryPrivate)
- (void) _handleUserDefaultsDidChange:(NSNotification *)aNotification;
- (NSArray *) _enabledAssociationsForPairs:(NSArray *)pairs;
- (void) _updateStatusText;
- (void) _updateLevelIndicator;
@end

@interface GeniusDocument (KeyValueObserving)
- (void) _markDocumentDirty:(NSNotification *)notification;
- (void) _reloadCustomTypeCacheSet;
- (NSArray *) _sortedCustomTypeStrings;
@end

@interface GeniusDocument (TableColumnManagement)
+ (NSArray *) _defaultColumnIdentifiers;
- (void) _hideTableColumn:(NSTableColumn *)column;
- (void) _showTableColumn:(NSTableColumn *)column;
- (void) _toggleColumnWithIdentifier:(NSString *)identifier;

- (NSString *) _titleForTableColumnWithIdentifier:(NSString *)identifier;
- (void) _setTitle:(NSString *)title forTableColumnWithIdentifier:(NSString *)identifier;
@end


@implementation GeniusDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        _visibleColumnIdentifiersBeforeNibLoaded = [[GeniusDocument _defaultColumnIdentifiers] mutableCopy];
        _learnVsReviewWeightBeforeNibLoaded = 50.0;
        _columnHeadersDict = [NSMutableDictionary new];
        _pairs = [NSMutableArray new];

        _tableColumns = [NSMutableDictionary new];

        _shouldShowImportWarningOnSave = NO;
        _customTypeStringCache = [NSMutableSet new];
                
        [NSValueTransformer setValueTransformer:[[IsPairImportantTransformer new] autorelease] forName:@"IsPairImportantTransformer"];
        [NSValueTransformer setValueTransformer:[[ColorFromPairImportanceTransformer new] autorelease] forName:@"ColorFromPairImportanceTransformer"];
    }
    return self;
}

- (void) dealloc
{
    [_pairs release];
    [_visibleColumnIdentifiersBeforeNibLoaded release];
    [_columnHeadersDict release];
    [_tableColumns release];
    
    [super dealloc];
}


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"GeniusDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    [self setupToolbarForWindow:[aController window]];
    [_searchField setNextKeyView:tableView];
    //[tableView setNextKeyView:_searchField];    // This doesn't work!
	
    // Retain all table columns in case we hide them later
    NSEnumerator * columnEnumerator = [[tableView tableColumns] objectEnumerator];
    NSTableColumn * column;
    while ((column = [columnEnumerator nextObject]))
    {
        NSString * identifier = [column identifier];
        if (identifier)
            [_tableColumns setObject:column forKey:[column identifier]];
    }
        
    // Set up icon text field cells for colored score indication
    IconTextFieldCell * cell = [IconTextFieldCell new];

    NSTableColumn * tableColumn = [tableView tableColumnWithIdentifier:@"scoreAB"];
    NSNumberFormatter * numberFormatter = [[tableColumn dataCell] formatter];
    [cell setFormatter:numberFormatter];
    [tableColumn setDataCell:cell];
    tableColumn = [tableView tableColumnWithIdentifier:@"scoreBA"];
    [tableColumn setDataCell:cell];

    //[cell release];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSTabularTextPboardType, nil]];    

	// Configure list font size
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(_handleUserDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
	[self _handleUserDefaultsDidChange:nil];
        
    if (_shouldShowImportWarningOnSave)
        [self updateChangeCount:NSChangeDone];
        
    [statusField setStringValue:@""];
    [self reloadInterfaceFromModel];
}


- (NSMutableArray *) pairs
{
    return _pairs;
}

- (NSSearchField *) searchField
{
    return _searchField;
}

@end


@implementation GeniusDocument (Private)

- (void) reloadInterfaceFromModel
{
    // Sync with _visibleColumnIdentifiersBeforeNibLoaded

        // Hide table columns that should not be visible, but are
    NSMutableSet * actualColumnIdentifiersSet = [NSMutableSet setWithArray:[self visibleColumnIdentifiers]];
    NSSet * expectedColumnIdentifierSet = [NSSet setWithArray:_visibleColumnIdentifiersBeforeNibLoaded];
    [actualColumnIdentifiersSet minusSet:expectedColumnIdentifierSet];
    NSEnumerator * identifierToHideEnumerator = [actualColumnIdentifiersSet objectEnumerator];
    NSString * identifier;
    while ((identifier = [identifierToHideEnumerator nextObject]))
    {
        NSTableColumn * tableColumn = [tableView tableColumnWithIdentifier:identifier];
        [self _hideTableColumn:tableColumn];
    }
    
        // Show table columns that should be visible, but aren't
    NSEnumerator * expectedIdentifierEnumerator = [_visibleColumnIdentifiersBeforeNibLoaded objectEnumerator];
    NSString * expectedIdentifier;
    while ((expectedIdentifier = [expectedIdentifierEnumerator nextObject]))
    {
        NSTableColumn * expectedColumn = [_tableColumns objectForKey:expectedIdentifier];
        if ([[tableView tableColumns] containsObject:expectedColumn] == NO)
            [self _showTableColumn:expectedColumn];
    }

    [tableView sizeToFit];

    [learnReviewSlider setFloatValue:_learnVsReviewWeightBeforeNibLoaded];

    if ([_pairs count])
    {
        [initialWatermarkView removeFromSuperview];
        initialWatermarkView = nil;
        
        // Sync with _columnHeadersDict, i.e. custom table headers
        NSString * title;
        title = [_columnHeadersDict objectForKey:@"columnA"];
        if (title)
            [self _setTitle:title forTableColumnWithIdentifier:@"columnA"];

        title = [_columnHeadersDict objectForKey:@"columnB"];
        if (title)
            [self _setTitle:title forTableColumnWithIdentifier:@"columnB"];

        [tableView reloadData];
        
        // Sync with _pairs    
        NSEnumerator * pairEnumerator = [_pairs objectEnumerator];
        GeniusPair * pair;
        while ((pair = [pairEnumerator nextObject]))
        {
            [pair addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
            [pair addObserver:self forKeyPath:@"customTypeString" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        }

        [arrayController setContent:_pairs];    // reload
        [self _reloadCustomTypeCacheSet];
    }

    [self _updateStatusText];
	[self _updateLevelIndicator];
}


- (NSArray *) visibleColumnIdentifiers
{
    // NSTableColumns -> NSStrings
    NSMutableArray * outIdentifiers = [NSMutableArray array];
    NSEnumerator * columnEnumerator = [[tableView tableColumns] objectEnumerator];
    NSTableColumn * column;
    while ((column = [columnEnumerator nextObject]))
        [outIdentifiers addObject:[column identifier]];
    return outIdentifiers;
}

- (NSArrayController *) arrayController
{
    return arrayController;
}

- (NSArray *) columnBindings    // in display order
{
    return [NSArray arrayWithObjects:@"itemA.stringValue", @"itemB.stringValue", @"customGroupString", @"customTypeString", @"associationAB.scoreNumber", @"associationBA.scoreNumber", @"notesString", nil];
}

@end


@implementation GeniusDocument (VeryPrivate)

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
			return 16.0;
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
			return 16.0 + 6.0;
	}
	
	return [NSFont systemFontSize];
}

- (void) _handleUserDefaultsDidChange:(NSNotification *)aNotification
{	
	// _dismissFieldEditor
    NSWindow * window = [[[self windowControllers] objectAtIndex:0] window];
	if ([window makeFirstResponder:window] == NO)
		[window endEditingFor:nil];
	
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	// Handle font size
	int mode = [ud integerForKey:GeniusPreferencesListTextSizeModeKey];
	float fontSize = [GeniusDocument listTextFontSizeForSizeMode:mode];

	float rowHeight = [GeniusDocument rowHeightForSizeMode:mode];
	[tableView setRowHeight:rowHeight];

	NSEnumerator * tableColumnEnumerator = [[tableView tableColumns] objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
		[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:fontSize]];
}


- (NSArray *) _enabledAssociationsForPairs:(NSArray *)pairs
{
    NSTableColumn * associationABColumn = [_tableColumns objectForKey:@"scoreAB"];
    BOOL useAB = [[tableView tableColumns] containsObject:associationABColumn];
    NSTableColumn * associationBAColumn = [_tableColumns objectForKey:@"scoreBA"];
    BOOL useBA = [[tableView tableColumns] containsObject:associationBAColumn];

    return [GeniusPair associationsForPairs:pairs useAB:useAB useBA:useBA];
}

- (void) _updateStatusText
{
    NSString * status = @"";
    int rowCount = [_pairs count];
    if (rowCount == 0)
    {
        [statusField setStringValue:status];
        return;
    }
    
	NSString * queryString = [arrayController filterString];
	if ([queryString isEqualToString:@""])
	{
		int numberOfSelectedRows = [tableView numberOfSelectedRows];
		if (numberOfSelectedRows > 0)
		{
			NSString * format = NSLocalizedString(@"n of m selected", nil);
			status = [NSString stringWithFormat:format, numberOfSelectedRows, rowCount];
		}
		else if (rowCount == 1)
		{
			status = NSLocalizedString(@"1 item", nil);
		}
		else
		{
			NSString * format = NSLocalizedString(@"n items", nil);
			status = [NSString stringWithFormat:format, rowCount];
		}
	}
	else
	{
		NSString * format = NSLocalizedString(@"n of m shown", nil);
		status = [NSString stringWithFormat:format, [[arrayController arrangedObjects] count], rowCount];
	}

    [statusField setStringValue:status];
}

- (void) _updateLevelIndicator
{	
	NSArray * associations = [self _enabledAssociationsForPairs:_pairs];
	int associationCount = [associations count];

	if (associationCount == 0)
	{
		[levelIndicator setDoubleValue:0.0];
		[levelField setStringValue:@""];
		return;
	}

	int learnedAssociationCount = 0;
	NSEnumerator * associationEnumerator = [associations objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
		if ([association scoreNumber] != nil)
			learnedAssociationCount++;
	
	float percentLearned = (float)learnedAssociationCount/(float)associationCount;
	[levelIndicator setDoubleValue:(percentLearned * 100.0)];
	[levelField setDoubleValue:(percentLearned * 100.0)];

/*	NSString * unlearnedPercentString = [NSString stringWithFormat:@"%.0f%%", (1.0-percentLearned) * 100.0];
	NSString * xOfYString = [NSString stringWithFormat:@"%.0f of %d", percentLearned * (float)[_pairs count], [_pairs count]];
	status = [NSString stringWithFormat:@"%@ remaining (%@ studied)", unlearnedPercentString, xOfYString];*/
}

@end


@implementation GeniusDocument (KeyValueObserving)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"customTypeString"])
        [self _reloadCustomTypeCacheSet];
    
    [self _markDocumentDirty:nil];
    [self _updateStatusText];
	[self _updateLevelIndicator];
}

- (void) _markDocumentDirty:(NSNotification *)notification
{
    if ([self isDocumentEdited])
        return;

    [self updateChangeCount:NSChangeDone];
}


- (void) _reloadCustomTypeCacheSet
{
    [_customTypeStringCache removeAllObjects];
    
    NSEnumerator * pairEnumerator = [_pairs objectEnumerator];
    GeniusPair * pair;
    while ((pair = [pairEnumerator nextObject]))
    {
        NSString * customTypeString = [pair customTypeString];
        if (customTypeString && [customTypeString isEqualToString:@""] == NO)
            [_customTypeStringCache addObject:customTypeString];
    }
}

- (NSArray *) _sortedCustomTypeStrings
{
    return [[_customTypeStringCache allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

@end


@implementation GeniusDocument (NSTableDataSource)

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard*)pboard
{
    [pboard declareTypes:[NSArray arrayWithObjects:NSTabularTextPboardType, nil] owner:self];
    
    // Convert row numbers to items
    _pairsDuringDrag = [NSMutableArray array];
    NSEnumerator * rowNumberEnumerator = [rows objectEnumerator];
    NSNumber * rowNumber;
    while ((rowNumber = [rowNumberEnumerator nextObject]))
    {
        GeniusItem * item = [[arrayController arrangedObjects] objectAtIndex:[rowNumber intValue]];
        [(NSMutableArray *)_pairsDuringDrag addObject:item];
    }    

    NSString * outputString = [GeniusPair tabularTextFromPairs:_pairsDuringDrag order:[self columnBindings]];
    [pboard setString:outputString forType:NSTabularTextPboardType];
    [pboard setString:outputString forType:NSStringPboardType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if ([info draggingSource] == aTableView)    // intra-document
    {
        if (operation == NSTableViewDropOn)
            return NSDragOperationNone;    
        return NSDragOperationMove;
    }
    else                                        // inter-document, inter-application
    {
        [aTableView setDropRow:-1 dropOperation:NSTableViewDropOn]; // entire table view
        return NSDragOperationCopy;
    }
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    if ([info draggingSource] == aTableView)      // intra-document
    {
        NSArray * copyOfItemsDuringDrag = [[NSArray alloc] initWithArray:_pairsDuringDrag copyItems:YES];
    
        NSIndexSet * indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [copyOfItemsDuringDrag count])];
        [arrayController insertObjects:copyOfItemsDuringDrag atArrangedObjectIndexes:indexes];
        
        if ([info draggingSource] == aTableView)
            [arrayController removeObjects:_pairsDuringDrag];
        
        [copyOfItemsDuringDrag release];
        _pairsDuringDrag = nil;
    }
    else                                        // inter-document, inter-application
    {
        NSPasteboard * pboard = [info draggingPasteboard];
        NSString * string = [pboard stringForType:NSStringPboardType];
        if (string == nil)
            return NO;

        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        NSArray * pairs = [GeniusPair pairsFromTabularText:string order:[self columnBindings]];
        [arrayController setFilterString:@""];
        [arrayController addObjects:pairs];
    }
        
    [self _markDocumentDirty:nil];
    return YES;
}

@end

/*!
    @category GeniusDocument(IBActions)
    @abstract Collections of methods accessed directly from the GUI.
*/
@implementation GeniusDocument(IBActions)

//! Saves GeniusDocument
/*! 
    The implementation checks to see if saving the file would make it impossible to open the file again with older versions of Genius.
    Assuming this is okay, it goes on to save the document with a call to super.
    @todo Perhaps this would be better to have in the GeniusDocument(FileFormat) category next to loadDataRepresentation:ofType:.
*/
- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
    if (_shouldShowImportWarningOnSave)
    {
		NSString * title = NSLocalizedString(@"This document needs to be saved in a newer format.", nil);
		NSString * message = NSLocalizedString(@"Once you save, the file will no longer be readable by previous versions of Genius.", nil);
		NSString * cancelTitle = NSLocalizedString(@"Cancel", nil);
		NSString * saveTitle = NSLocalizedString(@"Save", nil); 

        NSAlert * alert = [NSAlert alertWithMessageText:title defaultButton:cancelTitle alternateButton:saveTitle otherButton:nil informativeTextWithFormat:message];
        int result = [alert runModal];
        if (result != NSAlertAlternateReturn) // not NSAlertSecondButtonReturn?
            return;
        
        _shouldShowImportWarningOnSave = NO;
    }
    
    [super saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}


//! Turns on/off display of the group column.
- (IBAction)toggleGroupColumn:(id)sender
{
    [self _toggleColumnWithIdentifier:@"customGroup"];
}

//! Turns on/off display of the type column.
- (IBAction)toggleTypeColumn:(id)sender
{
    [self _toggleColumnWithIdentifier:@"customType"];
}

//! Turns on/off display of the standard style score column.
- (IBAction)toggleABScoreColumn:(id)sender
{
    [self _toggleColumnWithIdentifier:@"scoreAB"];
}

//! Turns on/off display of the jepardy style score column.
- (IBAction)toggleBAScoreColumn:(id)sender
{
    [self _toggleColumnWithIdentifier:@"scoreBA"];
}

//! Marks document as dirty @see _markDocumentDirty:.
- (IBAction)learnReviewSliderChanged:(id)sender
{
    [self _markDocumentDirty:nil];
}

//! Toggles open state of info drawer at default window edge.
- (IBAction)showInfo:(id)sender
{
    [infoDrawer toggle:sender];
}

//! Toggles open state of notes drawer at bottom of window.
- (IBAction)showNotes:(id)sender
{
    if ([notesDrawer state] == NSDrawerOpenState)
        [notesDrawer close];
    else
        [notesDrawer openOnEdge:NSMinYEdge];
}


//! Creates a new empty GeniusPair and inserts it in table view.
- (IBAction)add:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    //! @todo check if this is really how to end editing.
    NSWindow * window = [[[self windowControllers] objectAtIndex:0] window];
    if ([window makeFirstResponder:window] == NO)
        [window endEditingFor:nil];

    [initialWatermarkView removeFromSuperview];
    initialWatermarkView = nil;

    [_searchField setStringValue:@""];
    [self search:_searchField];

    //NSIndexSet * selectionIndexes = [arrayController selectionIndexes];
    [tableView deselectAll:self];
    
    // Insert after selection if possible; otherwise insert at document end
    int newPairIndex;
    //! @todo drop usage of new here.
    GeniusPair * pair = [GeniusPair new];
/*    if ([selectionIndexes count] >= 1)
    {
        newPairIndex = [selectionIndexes lastIndex] + 1;
        [arrayController insertObject:pair atArrangedObjectIndex:newPairIndex];
    }
    else*/
    {
        newPairIndex = [tableView numberOfRows];
        [arrayController addObject:pair];
    }
    [pair release];
    
    [tableView selectRow:newPairIndex byExtendingSelection:NO];
    [tableView editColumn:1 row:newPairIndex withEvent:nil select:YES];
    
    [self _markDocumentDirty:nil];
}

//! Duplicates the selected items and inserts them in the document.
- (IBAction)duplicate:(id)sender
{
    // First end editing in-progress (from -[NSWindow endEditingFor:] documentation)
    NSWindow * window = [[[self windowControllers] objectAtIndex:0] window];
    if ([window makeFirstResponder:window] == NO)
        [window endEditingFor:nil];

    NSArray * selectedObjects = [arrayController selectedObjects];

    NSIndexSet * selectionIndexes = [arrayController selectionIndexes];
    int lastIndex = [selectionIndexes lastIndex];
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastIndex+1, [selectionIndexes count])];
    NSArray * newObjects = [[NSArray alloc] initWithArray:selectedObjects copyItems:YES];
    [arrayController insertObjects:newObjects atArrangedObjectIndexes:indexSet];
    [arrayController setSelectedObjects:newObjects];
    [newObjects release];
    
    [self _markDocumentDirty:nil];
}

//! Initiates modal sheet to check if the user really wants to delete selected items.
- (IBAction)delete:(id)sender
{
    NSArray * selectedObjects = [arrayController selectedObjects];
	if ([selectedObjects count] == 0)
		return;

	NSString * title = NSLocalizedString(@"Are you sure you want to delete the selected items?", nil);
	NSString * message = NSLocalizedString(@"You cannot undo this operation.", nil);
	NSString * deleteTitle = NSLocalizedString(@"Delete", nil); 
	NSString * cancelTitle = NSLocalizedString(@"Cancel", nil);

    NSAlert * alert = [NSAlert alertWithMessageText:title defaultButton:deleteTitle alternateButton:cancelTitle otherButton:nil informativeTextWithFormat:message];
    NSButton * defaultButton = [[alert buttons] objectAtIndex:0];
    [defaultButton setKeyEquivalent:@"\r"];

    [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(_deleteAlertDidEnd:returnCode:contextInfo:) contextInfo:selectedObjects];
}

//! Handles the results of the modal sheet initiated in @a delete:.
/*!
    In the event the user confirmed the delete action, then the selected GeniusPair items are nuked.
 */
- (void)_deleteAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 0)
        return;
    
    [arrayController removeObjects:contextInfo];
    [self _markDocumentDirty:nil];
}

//! @todo dead code
- (IBAction)swapItems:(id)sender
{
}

//! Initiates modal sheet to check if the user really wants to reset selected items.
- (IBAction)resetScore:(id)sender
{
    NSArray * selectedObjects = [arrayController selectedObjects];
	if ([selectedObjects count] == 0)
		return;

	NSString * title = NSLocalizedString(@"Are you sure you want to reset the items?", nil);
	NSString * message = NSLocalizedString(@"Your performance history will be cleared for the selected items.", nil);
	NSString * resetTitle = NSLocalizedString(@"Reset", nil); 
	NSString * cancelTitle = NSLocalizedString(@"Cancel", nil);

    NSAlert * alert = [NSAlert alertWithMessageText:title defaultButton:resetTitle alternateButton:cancelTitle otherButton:nil informativeTextWithFormat:message];
    NSButton * defaultButton = [[alert buttons] objectAtIndex:0];
    [defaultButton setKeyEquivalent:@"\r"];
    
    [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(_resetAlertDidEnd:returnCode:contextInfo:) contextInfo:selectedObjects];
}

//! Handles the results of the modal sheet initiated in @a resetScore:.
/*!
    In the event the user confirmed the reset action, then the performance statistics for all GeniusPair items
    in the this document are nuked.
    @todo Check if it makes that much sense to nuke the performance data? 
*/
- (void)_resetAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 0)
        return;
        
    NSArray * associations = [GeniusPair associationsForPairs:(NSArray *)contextInfo useAB:YES useBA:YES];
    [associations makeObjectsPerformSelector:@selector(reset)];
}

//! Sets the importance of the selected items from 1 to 5.
- (IBAction)setItemImportance:(id)sender
{
    NSMenuItem * menuItem = (NSMenuItem *)sender;
    int importance = [menuItem tag];
    
    NSArray * selectedObjects = [arrayController selectedObjects];
    NSEnumerator * objectEnumerator = [selectedObjects objectEnumerator];
    GeniusPair * pair;
    while ((pair = [objectEnumerator nextObject]))
        [pair setImportance:importance];
}

//! Action invoked from the little find NSTextField 
- (IBAction)search:(id)sender
{
    [arrayController setFilterString:[sender stringValue]];
    [self tableViewSelectionDidChange:nil];
}

//! Actually starts the currenlty configured quiz
/*!
    In the event that the users choices have resulted in no items being available, the user is
    presented with an alert panel to that effect and the quiz is not begun.  In the end the status
    text and level indicator are updated
*/
- (void) _beginQuiz:(GeniusAssociationEnumerator *)enumerator
{
    if ([enumerator remainingCount] == 0)
    {
		NSString * title = NSLocalizedString(@"There is nothing to study.", nil);
		NSString * message = NSLocalizedString(@"Make sure the items you want to study are enabled, or add more items.", nil);
		NSString * okTitle = NSLocalizedString(@"OK", nil);

        NSAlert * alert = [NSAlert alertWithMessageText:title defaultButton:okTitle alternateButton:nil otherButton:nil informativeTextWithFormat:message];
        NSButton * defaultButton = [[alert buttons] objectAtIndex:0];
        [defaultButton setKeyEquivalent:@"\r"];
        
        [alert runModal];        
        return;
    }

/*    // Hide document window
    NSWindowController * windowController = [[self windowControllers] lastObject];
    NSWindow * documentWindow = [windowController window];
    [documentWindow orderOut:self];*/  
	
    // Start quiz
    NSTimeInterval studyTime;
    MyQuizController * quizController = [[MyQuizController alloc] initWithWindowNibName:@"Quiz"];
    [quizController runQuiz:enumerator cumulativeTime:&studyTime];
    [quizController release];
    
    // Show document window
    [self _updateStatusText];
	[self _updateLevelIndicator];
//    [windowController showWindow:self];
}

//! Set up quiz mode using enabled and based probablity.
/*! 
    Uses the learn review slider value as input to probability based selection process.  In the event
    that the learn revew slider is set to review, then only previously learned items will appear in the quiz.
*/
- (IBAction)quizAutoPick:(id)sender
{
    NSArray * associations = [self _enabledAssociationsForPairs:_pairs];
    GeniusAssociationEnumerator * enumerator = [[GeniusAssociationEnumerator alloc] initWithAssociations:associations];
    [enumerator setCount:13];    
    /*
        0% should be m=0.0 (learn only)
        50% should be m=1.0
        100% should be minimum=0 (review only)
    */
    float weight = [learnReviewSlider doubleValue];
    if (weight == 100.0)
        [enumerator setMinimumScore:0]; // Review only
    float m_value = (weight / 100.0) * 2.0;
    [enumerator setProbabilityCenter:m_value];
    
    [enumerator performChooseAssociations];    // Pre-perform for progress indication
    [self _beginQuiz:enumerator];
}

//! Set up quiz mode using enabled and previously learned GeniusPair items.
/*! 
    Sets the minimum required score on the GeniusAssociationEnumerator to 0 which
    precludes pairs with uninitialized score values.  @see score
*/
- (IBAction)quizReview:(id)sender
{
    NSArray * associations = [self _enabledAssociationsForPairs:_pairs];
    GeniusAssociationEnumerator * enumerator = [[GeniusAssociationEnumerator alloc] initWithAssociations:associations];
    [enumerator setCount:13];
    [enumerator setMinimumScore:0];

    [enumerator performChooseAssociations];    // Pre-perform for progress indication
    [self _beginQuiz:enumerator];
}

//! Set up quiz mode using the user selected GeniusPair items.
/*! Excludes disabled items */
- (IBAction)quizSelection:(id)sender
{
    NSArray * selectedPairs = [arrayController selectedObjects];
    if ([selectedPairs count] == 0)
        selectedPairs = _pairs;

    NSArray * associations = [self _enabledAssociationsForPairs:selectedPairs];
    GeniusAssociationEnumerator * enumerator = [[GeniusAssociationEnumerator alloc] initWithAssociations:associations];

    [enumerator performChooseAssociations];    // Pre-perform for progress indication
    [self _beginQuiz:enumerator];
}

@end


@implementation GeniusDocument (NSMenuValidation)

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    SEL action = [menuItem action];
    
    if (action == @selector(toggleABScoreColumn:) || action == @selector(toggleBAScoreColumn:))
    {
        NSString * titleA = [self _titleForTableColumnWithIdentifier:@"columnA"];
        NSString * titleB = [self _titleForTableColumnWithIdentifier:@"columnB"];

        if (action == @selector(toggleABScoreColumn:))
        {
			NSString * format = NSLocalizedString(@"Score (A->B)", nil);
            NSString * title = [NSString stringWithFormat:format, titleA, titleB];
			title = [@"    " stringByAppendingString:title];
            [menuItem setTitle:title];
        }
        else if (action == @selector(toggleBAScoreColumn:))
        {
			NSString * format = NSLocalizedString(@"Score (A<-B)", nil);
            NSString * title = [NSString stringWithFormat:format, titleA, titleB];
			title = [@"    " stringByAppendingString:title];
            [menuItem setTitle:title];
        }
    }
    
    NSString * chosenColumnIdentifier = nil;
    if (action == @selector(toggleGroupColumn:))
        chosenColumnIdentifier = @"customGroup";
    else if (action == @selector(toggleTypeColumn:))
        chosenColumnIdentifier = @"customType";
    else if (action == @selector(toggleABScoreColumn:))
        chosenColumnIdentifier = @"scoreAB";
    else if (action == @selector(toggleBAScoreColumn:))
        chosenColumnIdentifier = @"scoreBA";
    if (chosenColumnIdentifier)
    {
        NSArray * visibleColumnIdentifiers = [self visibleColumnIdentifiers];
        int state = ([visibleColumnIdentifiers containsObject:chosenColumnIdentifier] ? NSOnState : NSOffState);
        [menuItem setState:state];

        // Make sure at least one score column is always enabled.
        if ([chosenColumnIdentifier isEqualToString:@"scoreAB"] &&
                [visibleColumnIdentifiers containsObject:@"scoreBA"] == NO)
            return NO;
        if ([chosenColumnIdentifier isEqualToString:@"scoreBA"] &&
                [visibleColumnIdentifiers containsObject:@"scoreAB"] == NO)
            return NO;
    }
    

	if (action == @selector(quizAutoPick:) || action == @selector(quizReview:))
	{
		if ([[arrayController arrangedObjects] count] == 0)
			return NO;
	}

	NSArray * selectedObjects = [arrayController selectedObjects];
	int selectedCount = [selectedObjects count];

	if (action == @selector(duplicate:) || action == @selector(resetScore:) || action == @selector(setItemImportance:)
		|| action == @selector(quizSelection:))
	{
		if (selectedCount == 0)
			return NO;
	}
		
    if (action == @selector(setItemImportance:))
    {
        int expectedImportance = [menuItem tag];
        int i, actualCount = 0;
        for (i=0; i<selectedCount; i++)
        {
            GeniusPair * pair = [selectedObjects objectAtIndex:i];
            if ([pair importance] == expectedImportance)
                actualCount++;
        }
        if (actualCount == 0)
            [menuItem setState:NSOffState];
        else if (actualCount == selectedCount)
            [menuItem setState:NSOnState];
        else
            [menuItem setState:NSMixedState];
        return YES;
    }
    
    return [super validateMenuItem:(id)menuItem];
}

@end


@implementation GeniusDocument (NSTableViewDelegate)

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString * identifier = [aTableColumn identifier];
    if ([identifier isEqualToString:@"scoreAB"] || [identifier isEqualToString:@"scoreBA"])
    {
        GeniusPair * pair = [[arrayController arrangedObjects] objectAtIndex:rowIndex];
    
        int score;
        if ([identifier isEqualToString:@"scoreAB"])
            score = [[pair associationAB] score];
        else
            score = [[pair associationBA] score];

        NSImage * image = nil;
        if (score == -1)
            image = [NSImage imageNamed:@"status-red"];
        else if (score < 5)
            image = [NSImage imageNamed:@"status-yellow"];
        else
            image = [NSImage imageNamed:@"status-green"];
        [aCell setImage:image];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self _updateStatusText];
    [[infoDrawer contentView] setNeedsDisplay:YES];
}


// Editable table headers
- (BOOL) _tableView:(NSTableView *)aTableView shouldChangeHeaderTitleOfTableColumn:(NSTableColumn *)aTableColumn
{
    NSString * identifier = [aTableColumn identifier];
    return [identifier isEqualToString:@"columnA"] || [identifier isEqualToString:@"columnB"];
}

- (void) _tableView:(NSTableView *)aTableView didChangeHeaderTitleOfTableColumn:(NSTableColumn *)aTableColumn
{
    NSString * identifier = [aTableColumn identifier];
    if ([identifier isEqualToString:@"columnA"])
    {
        NSString * titleA = [self _titleForTableColumnWithIdentifier:identifier];
        [_columnHeadersDict setObject:titleA forKey:identifier];
    }
    else if ([identifier isEqualToString:@"columnB"])
    {
        NSString * titleB = [self _titleForTableColumnWithIdentifier:identifier];
        [_columnHeadersDict setObject:titleB forKey:identifier];
    }
    
    [self _markDocumentDirty:nil];
}


// Selectively movable table columns
/*static int sDuringDragOldColumnIndex = -1;
static NSTableColumn * sDuringDragTableColumn = nil;

- (void)tableView:(NSTableView *)aTableView mouseDownInHeaderOfTableColumn:(NSTableColumn*)tableColumn
{
    BOOL allowsColumnReordering = [self _tableView:aTableView shouldChangeHeaderTitleOfTableColumn:tableColumn];
    [tableView setAllowsColumnReordering:allowsColumnReordering];
    if (allowsColumnReordering == NO)
        return;

    sDuringDragOldColumnIndex = [[tableView tableColumns] indexOfObject:tableColumn];
    sDuringDragTableColumn = tableColumn;
}

- (void)tableViewColumnDidMove:(NSNotification *)aNotification
{
    int newColumnIndex = [[tableView tableColumns] indexOfObject:sDuringDragTableColumn];
    BOOL okToMove = [self _tableView:tableView shouldChangeHeaderTitleOfTableColumn:sDuringDragTableColumn] && (newColumnIndex == 1 || newColumnIndex == 2);
    if (okToMove == NO)
    {
        // Move back
        [tableView moveColumn:newColumnIndex toColumn:sDuringDragOldColumnIndex];
    }
}*/

@end


@implementation GeniusDocument (TableColumnManagement)

+ (NSArray *) _allColumnIdentifiers
{
    return [NSArray arrayWithObjects:@"disabled", @"columnA", @"columnB", @"customGroup", @"customType", @"scoreAB", @"scoreBA", nil];
}

+ (NSArray *) _defaultColumnIdentifiers
{
    return [NSArray arrayWithObjects:@"disabled", @"columnA", @"columnB", @"scoreAB", nil];
}


- (NSArray *) __columnIdentifiersReorderedByDefaultOrder:(NSArray *)identifiers
{
    NSMutableArray * outIdentifiers = [NSMutableArray array];
    NSEnumerator * identifierEnumerator = [[GeniusDocument _allColumnIdentifiers] objectEnumerator];
    NSString * identifier;
    while ((identifier = [identifierEnumerator nextObject]))
        if ([identifiers containsObject:identifier])
            [outIdentifiers addObject:identifier];
    return outIdentifiers;
}

- (void) _hideTableColumn:(NSTableColumn *)column
{
    [tableView removeTableColumn:column];
}

- (void) _showTableColumn:(NSTableColumn *)column
{
    // Determine proper column position
    NSString * identifier = [column identifier];
    NSMutableArray * identifiers = [NSMutableArray arrayWithArray:[self visibleColumnIdentifiers]];
    [identifiers addObject:identifier];
    NSArray * orderedIdentifiers = [self __columnIdentifiersReorderedByDefaultOrder:identifiers];
    int index = [orderedIdentifiers indexOfObject:identifier];
    
    [tableView addTableColumn:column];
    [tableView moveColumn:[tableView numberOfColumns]-1 toColumn:index];
}

- (void) _toggleColumnWithIdentifier:(NSString *)identifier
{
    NSTableColumn * column = [_tableColumns objectForKey:identifier];
    if (column == nil)
        return; // not found

    NSArray * tableColumns = [tableView tableColumns];
    if ([tableColumns containsObject:column])
        [self _hideTableColumn:column];
    else
        [self _showTableColumn:column];
    
    [tableView sizeToFit];
}


- (NSString *) _titleForTableColumnWithIdentifier:(NSString *)identifier
{
    NSTableColumn * column = [tableView tableColumnWithIdentifier:identifier];
    if (column == nil)
        return nil;
    return [[column headerCell] title];
}

- (void) _setTitle:(NSString *)title forTableColumnWithIdentifier:(NSString *)identifier
{
    NSTableColumn * column = [tableView tableColumnWithIdentifier:identifier];
    [[column headerCell] setStringValue:title];
}

@end


/*
    Adds support for the delegate methods
        -_tableView:shouldChangeHeaderTitleOfTableColumn:
        -_tableView:didChangeHeaderTitleOfTableColumn:
        -delete:
*/
@implementation MyTableView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    [self setDoubleAction:@selector(_doubleClick:)];   // Make editable
    [self setTarget:self];
    return self;
}

- (void) awakeFromNib
{
    [self setDoubleAction:@selector(_doubleClick:)];   // Make editable
    [self setTarget:self];
}

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
    if ([[self delegate] respondsToSelector:@selector(_tableView:shouldChangeHeaderTitleOfTableColumn:)])
    {
        BOOL shouldChange = (unsigned long)[[self delegate] performSelector:@selector(_tableView:shouldChangeHeaderTitleOfTableColumn:) withObject:self withObject:tableColumn];
        if (shouldChange == NO)
            return;
    }
        
    NSTableHeaderCell * cell = [tableColumn headerCell];
    NSString * string = [[cell title] copy];
    [cell setEditable:YES];
    [cell setTitle:@""];    
    
    NSTableHeaderView * headerView = [sender headerView];
    NSText * editor = [[headerView window] fieldEditor:YES forObject:cell];
    NSRect rect = [headerView headerRectOfColumn:columnIndex];

    sDuringEditTableColumn = tableColumn;
    [cell editWithFrame:rect inView:headerView editor:editor delegate:self event:nil];
    
    [editor setString:string];
    [editor selectAll:self];
    [string release];
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
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(_tableView:didChangeHeaderTitleOfTableColumn:)])
        [[self delegate] performSelector:@selector(_tableView:didChangeHeaderTitleOfTableColumn:) withObject:self withObject:sDuringEditTableColumn];
        
    [string release];
    sDuringEditTableColumn = nil;
}


// Workaround for Global drag and drop
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal   // NSDraggingSource
{
    if (isLocal)
        return [super draggingSourceOperationMaskForLocal:isLocal];
    else
        return NSDragOperationCopy;
}


// Handle delete:
- (void)keyDown:(NSEvent *)theEvent
{	
    if ([theEvent keyCode] == 51)       // Delete
    {
        id delegate = [self delegate];
        if (delegate && [delegate respondsToSelector:@selector(delete:)])
        {
            [delegate performSelector:@selector(delete:) withObject:self];
            return;
        }
    }
        // This is a super hack to make tab select the search field.
        // Toolbar items aren't views and therefore aren't included in the window's key view loop.
    else if ([theEvent keyCode] == 48)       // Tab
    {
        [[self window] makeFirstResponder:[documentController searchField]];
    }

    [super keyDown:theEvent];
}

@end


// Subclass to handle item filtering
@implementation GeniusArrayController

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    _filterString = [NSString new];
    return self;
}

- (void) dealloc
{
    [_filterString release];
    [super dealloc];
}

- (NSString *) filterString
{
    return _filterString;
}

- (void) setFilterString:(NSString *)string
{
    [_filterString release];
    _filterString = [string copy];
    [self rearrangeObjects];
}

- (NSArray *)arrangeObjects:(NSArray *)objects
{
    if ([_filterString isEqualToString:@""])
        return [super arrangeObjects:objects];
    else
    {
        NSMutableArray * keyPaths = [[geniusDocument columnBindings] mutableCopy];
        [keyPaths addObject:@"notesString"];    // HACK
        NSMutableArray * filteredObjects = [NSMutableArray array];
        NSEnumerator * pairEnumerator = [objects objectEnumerator];
        GeniusPair * pair;
        while ((pair = [pairEnumerator nextObject]))
        {
            NSString * tabularText = [pair tabularTextByOrder:keyPaths];
            NSRange range = [tabularText rangeOfString:_filterString options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound)
                [filteredObjects addObject:pair];
        }
        return [super arrangeObjects:filteredObjects];
    }
}

@end


@implementation GeniusDocument (NSComboBoxDataSource)

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
    NSArray * sortedVariantStrings = [self _sortedCustomTypeStrings];
    return [sortedVariantStrings indexOfObject:aString];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
    NSArray * sortedVariantStrings = [self _sortedCustomTypeStrings];
    return [sortedVariantStrings objectAtIndex:index];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    NSArray * sortedVariantStrings = [self _sortedCustomTypeStrings];
    return [sortedVariantStrings count];
}

@end


@implementation GeniusDocument (NSComboBoxCellDataSource)

- (id)comboBoxCell:(NSComboBoxCell *)aComboBoxCell objectValueForItemAtIndex:(int)index
{
    // O(n)
    NSArray * sortedVariantStrings = [self _sortedCustomTypeStrings];
    return [sortedVariantStrings objectAtIndex:index];
}

- (int)numberOfItemsInComboBoxCell:(NSComboBoxCell *)aComboBoxCell
{
    // O(n)
    NSArray * sortedVariantStrings = [self _sortedCustomTypeStrings];
    return [sortedVariantStrings count];
}

- (unsigned int)comboBoxCell:(NSComboBoxCell *)aComboBoxCell indexOfItemWithStringValue:(NSString *)string
{
    string = [aComboBoxCell stringValue];   // string comes in as (null) for some reason
    
    // O(n)
    NSArray * sortedVariantStrings = [self _sortedCustomTypeStrings];
    return [sortedVariantStrings indexOfObject:string];
}

- (NSString *)comboBoxCell:(NSComboBoxCell *)aComboBoxCell completedString:(NSString*)uncompletedString
{
    // O(n)
    NSArray * sortedVariantStrings = [self _sortedCustomTypeStrings];
    NSEnumerator * stringEnumerator = [sortedVariantStrings objectEnumerator];
    NSString * string;
    while ((string = [stringEnumerator nextObject]))
        if ([[string lowercaseString] hasPrefix:[uncompletedString lowercaseString]])
            return string;
    return nil;
}

@end


@implementation GeniusDocument (NSWindowDelegate)

- (void)windowWillClose:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
