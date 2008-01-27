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
#import "GeniusDocument_DebugLogging.h"

#import "GeniusDocumentPrivate.h"
#import "GeniusDocumentFile.h"
#import "IconTextFieldCell.h"
#import "GeniusToolbar.h"
#import "GeniusItem.h"
#import "GeniusAssociationEnumerator.h"
#import "MyQuizController.h"
#import "NSArrayGeniusAdditions.h"
#import "GeniusPreferencesController.h"
#import "GeniusPair.h"
#import "GeniusAssociation.h"
#import "IsPairImportantTransformer.h"
#import "ColorFromPairImportanceTransformer.h"
#import "GSTableView.h"

@interface GeniusDocument (VeryPrivate)
- (NSArray *) _enabledAssociationsForPairs:(NSArray *)pairs;
- (void) _updateStatusText;
- (void) _updateLevelIndicator;
@end

// Standard NSDocument subclass for controlling display and editing of a Genius file.
@implementation GeniusDocument

//! Sets up logging and registers value transformers.
+ (void) initialize
{
    [super initialize];
    
    // install our read only value tranformers referenced in GeniusDocument.nib.
    [NSValueTransformer setValueTransformer:[[[IsPairImportantTransformer alloc] init] autorelease] forName:@"IsPairImportantTransformer"];
    [NSValueTransformer setValueTransformer:[[[ColorFromPairImportanceTransformer alloc] init] autorelease] forName:@"ColorFromPairImportanceTransformer"];

    // install swizzle based logging
#if DEBUG
    [self installLogging];
#endif
}

//! Basic NSDocument init method.
/*!
    Initializes some transformers and registers them with NSValueTransformer.
*/
- (id)init
{
    self = [super init];
    if (self) {
        // Init array for genius pairs.
        [self setPairs:[NSMutableArray array]];

        // Expect not to be loading a 1.0 format file
        _shouldShowImportWarningOnSave = NO;

        // 50 - 50 value for the learn review setting.
        probabilityCenter = [[NSNumber alloc] initWithFloat:50.0F];

        // default card side titles
        _columnHeadersDict = [[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Question", @"columnA", @"Answer", @"columnB", nil] retain];

        // default visible columns.
        _visibleColumnIdentifiers = [[NSMutableArray alloc] initWithObjects:@"disabled", @"columnA", @"columnB", @"scoreAB", nil];

        _customTypeStringCache = [[NSMutableSet alloc] init];

        // setup change tracking of ourself
        [self addObserver:self];
        
        // initialize table layout font size and row height monitor changes to preference
        [self setListTextSizeMode:[[NSUserDefaults standardUserDefaults] integerForKey:GeniusPreferencesListTextSizeModeKey]];
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"ListTextSizeMode" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

//! Releases various ivars and deallocates memory.
- (void) dealloc
{
    [_pairs release];
    [_visibleColumnIdentifiers release];
    [_columnHeadersDict release];
    [_searchField release];
    [_customTypeStringCache release];
    [probabilityCenter release];
    [_sortedCustomTypeStrings release];
    
    [super dealloc];
}

//! Standard NSWindowController override.
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"GeniusDocument";
}

//! Initializes UI based on the existing document model info.
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    // Slip the help text in on top of the table view so it doesn't flicker.
    NSRect newFrame = [tableView convertRect:[helpTextOverlay frame] fromView:[helpTextOverlay superview]];
    [helpTextOverlay retain];
    [helpTextOverlay removeFromSuperview];
    [helpTextOverlay setFrame:newFrame];
    [tableView addSubview:helpTextOverlay];
    [helpTextOverlay release];
    
    // set up tool bar and enable tabbing from search field to table view.
    [self setupToolbarForWindow:[aController window]];
    [_searchField setNextKeyView:tableView];
	
    [statusField setStringValue:@""];
    [self reloadInterfaceFromModel];
}

//! inserts the item at index in pairs array, taking care to start observing it.
- (void) insertObject:(GeniusPair*) pair inPairsAtIndex:(int)index
{
    NSUndoManager *undoManager = [self undoManager];
    
    [[undoManager prepareWithInvocationTarget:self] removeObjectFromPairsAtIndex:index];

    [pair addObserver:self];
    [_pairs insertObject:pair atIndex:index];
}

//! removes the item at index from pairs array, taking care to stop observing it first.
- (void) removeObjectFromPairsAtIndex:(int) index
{
    NSUndoManager *undoManager = [self undoManager];
    
    GeniusPair *pair = [_pairs objectAtIndex:index];
    [[undoManager prepareWithInvocationTarget:self] insertObject:pair inPairsAtIndex:index];
    [pair removeObserver:self];
    [_pairs removeObjectAtIndex:index];
}

//! _pairs getter.
- (NSArray*) pairs
{
    return _pairs;
}

//! _pairs setter.  observes contents of @a values
- (void) setPairs: (NSMutableArray*) values
{
    [_pairs makeObjectsPerformSelector:@selector(removeObserver:) withObject:self];
    [values makeObjectsPerformSelector:@selector(addObserver:) withObject:self];        

    [values retain];
    [_pairs release];
    _pairs = values;
}

//! _searchField getter.
- (NSSearchField *) searchField
{
    return _searchField;
}

//! Dumps the GeniusDocument#_customTypeStringCache and rebuilds it from _pairs.
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
    [_sortedCustomTypeStrings release];
    _sortedCustomTypeStrings = [[[_customTypeStringCache allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] retain];
}

//! Updates fontSize and rowHeight to reflect the current small medium or large List Text preference 
- (void) setListTextSizeMode: (int) mode
{
    [self willChangeValueForKey:@"fontSize"];
    [self willChangeValueForKey:@"rowHeight"];
    
    switch (mode)
    {
        case 0:
            fontSize = [NSFont smallSystemFontSize];
            break;
        case 1:
            fontSize = [NSFont systemFontSize];
            break;
        case 2:
            fontSize = 16.0;
            break;
        default:
            fontSize = [NSFont systemFontSize];
    }
    
    NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    rowHeight = [layoutManager defaultLineHeightForFont:[NSFont systemFontOfSize:fontSize]];
    
    [self didChangeValueForKey:@"rowHeight"];
    [self didChangeValueForKey:@"fontSize"];
}

@end

//! Ecclectic collection of misc methods.
/*!
    @category GeniusDocument(Private)
    Not sure why this category exists.
*/
@implementation GeniusDocument(Private)

//! Updates UI to reflect the document.
- (void) reloadInterfaceFromModel
{
    // Sync with _visibleColumnIdentifiers
    [tableView setVisibleColumns:_visibleColumnIdentifiers];
    
    if ([_pairs count])
    {
        [tableView reloadData];
        [self _reloadCustomTypeCacheSet];
    }
    
    [self _updateStatusText];
	[self _updateLevelIndicator];
}

//! Returns array of keypaths used as bindings in our NSTableView.
/*
 @todo Must this be created new each time?
 @todo Perhaps this should be derived from the columns in our NSTableView?
 @todo They are particularly not in display order if the colums are reordered.
 @todo notesString is not a column binding.
 */
- (NSArray *) columnBindings    // in display order
{
    return [NSArray arrayWithObjects:@"itemA.stringValue", @"itemB.stringValue", @"customGroupString", @"customTypeString", @"associationAB.scoreNumber", @"associationBA.scoreNumber", @"notesString", nil];
}

@end

//! The super secret stuff that not even we should be using.
/*!
    @category GeniusDocument(VeryPrivate)
    I don't know what makes these worthy of being in the VeryPrivate category.
*/
@implementation GeniusDocument(VeryPrivate)

//! Convenience method to check which GeniusPair GeniusAssociation scores are Displayed.
/*!
    Hiding a score column excludes its related GeniusAssociation from the quiz.
    @todo Wouldn't this be better controlled during Quiz setup?
    @todo Is this really that clear as UI control?
*/
- (NSArray *) _enabledAssociationsForPairs:(NSArray *)pairs
{
    BOOL useAB = !([tableView columnWithIdentifier:@"scoreAB"] < 0);
    BOOL useBA = !([tableView columnWithIdentifier:@"scoreBA"] < 0);

    return [GeniusPair associationsForPairs:pairs useAB:useAB useBA:useBA];
}

//! Updates the selection summary text at bottom of window.
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

//! Updates the progress bar at lower right of Genius window to reflect current success with a Genius Document.
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
}

@end

//! Supports executing undo actions arranged by controller.
@implementation NSWindowController(UndoRedoSupport)
//! support for undo of property changes.
- (void) setValue:(id)value forKeyPath:(NSString*)keyPath inObject:(id)object
{
    [object setValue:value forKeyPath:keyPath];
}
@end

//! Collection of methods loosely related to coordinating model and view changes.
/*! @category GeniusDocument(UndoRedoSupport) */
@implementation GeniusDocument(UndoRedoSupport)
//! support for undo of property changes.
- (void) setValue:(id)value forKeyPath:(NSString*)keyPath inObject:(id)object
{
    [object setValue:value forKeyPath:keyPath];
}

//! registers observer for relevant keys.
- (void) addObserver: (id) observer
{
    [self addObserver:observer forKeyPath:@"probabilityCenter" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    [_columnHeadersDict addObserver:observer forKeyPath:@"columnA" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    [_columnHeadersDict addObserver:observer forKeyPath:@"columnB" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
}

//! un-registers up observer for relevant keys.
- (void) removeObserver: (id) observer
{
    [self removeObserver:self forKeyPath:@"probabilityCenter"];
    [_columnHeadersDict removeObserver:self forKeyPath:@"columnA"];
    [_columnHeadersDict removeObserver:self forKeyPath:@"columnB"];
}


//! Catches changes to many objects in the model graph and updates cached values as needed.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"ListTextSizeMode"])
    {
        [self setListTextSizeMode:[[change objectForKey:NSKeyValueChangeNewKey] intValue]];
    }
    else
    {
        NSUndoManager *undoManager = [self undoManager];
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        if (oldValue == [NSNull null]) {
            oldValue = nil;
        }
        
        [[undoManager prepareWithInvocationTarget:self] setValue:oldValue forKeyPath:keyPath inObject:object];
        
        if ([keyPath isEqualToString:@"customTypeString"])
            [self _reloadCustomTypeCacheSet];
        
        [self _updateStatusText];
        [self _updateLevelIndicator];
    }
}

@end


//! Support for the NSTableView.
/*! GeniusDocument(NSTableDataSource) */
@implementation GeniusDocument(NSTableDataSource)

//! Copy paste support, writes out selected items to @a pboard as tab delimited text.
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

//! Validates drop target. 
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

//! Accept drop previously validated.
/*! Unpacks GeniusItem instances from the paste board.  Expects tablular text.  */
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
        
    return YES;
}

@end

/*!
    @category GeniusDocument(IBActions)
    @abstract Collections of methods accessed directly from the GUI.
*/
@implementation GeniusDocument(IBActions)

//! Turns on/off display of the group column.
- (IBAction)toggleGroupColumn:(id)sender
{
    [tableView toggleColumnWithIdentifier:@"customGroup"];
}

//! Turns on/off display of the type column.
- (IBAction)toggleTypeColumn:(id)sender
{
    [tableView toggleColumnWithIdentifier:@"customType"];
}

//! Turns on/off display of the standard style score column.
- (IBAction)toggleABScoreColumn:(id)sender
{
    [tableView toggleColumnWithIdentifier:@"scoreAB"];
}

//! Turns on/off display of the jepardy style score column.
- (IBAction)toggleBAScoreColumn:(id)sender
{
    [tableView toggleColumnWithIdentifier:@"scoreBA"];
}

//! shows panel for setting field labels
- (IBAction) showDeckPreferences:(id)sender
{
    [NSApp beginSheet:deckPreferences modalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

//! Puts away deck preferences sheet.
- (IBAction) endDeckPreferences: (id) sender
{
    [deckPreferences orderOut:self];
    [NSApp endSheet:deckPreferences returnCode:1];
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

//! FirstResponder wrapper for arrayController insert:.
- (IBAction) add:(id)sender
{
    // In case user is typing in table view.
    [[tableView window] endEditingFor:nil]; 

    // Isolate this action it its own undo group.
    NSUndoManager *undoManager = [self undoManager];
    if([undoManager groupingLevel] > 0)
    {
        [undoManager endUndoGrouping];
        [undoManager beginUndoGrouping];
    }

    unsigned int count = [[arrayController arrangedObjects] count];    
    [arrayController insertObject:[[arrayController newObject] autorelease]
            atArrangedObjectIndex:count];
    [tableView editColumn: 1 row:count withEvent:nil select:YES];
    [undoManager setActionName:@"Insert Pair"];
}

//! FirstResponder wrapper for arrayController remove:.
- (IBAction) delete:(id)sender
{
    // In case user is typing in table view.
    [[tableView window] endEditingFor:nil]; 

    // Isolate this action it its own undo group.
    NSUndoManager *undoManager = [self undoManager];
    if([undoManager groupingLevel] > 0)
    {
        [undoManager endUndoGrouping];
        [undoManager beginUndoGrouping];
    }
    
    [arrayController remove:sender];
    [undoManager setActionName:@"Delete Pair"];
}

//! Duplicates the selected items and inserts them in the document.
- (IBAction) duplicate:(id)sender
{
    NSArray * selectedObjects = [arrayController selectedObjects];
    
    NSIndexSet * selectionIndexes = [arrayController selectionIndexes];
    int lastIndex = [selectionIndexes lastIndex];
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastIndex+1, [selectionIndexes count])];
    NSArray * newObjects = [[NSArray alloc] initWithArray:selectedObjects copyItems:YES];
    [arrayController insertObjects:newObjects atArrangedObjectIndexes:indexSet];
    [arrayController setSelectedObjects:newObjects];
    [newObjects release];
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
    in the this document are deleted.
    @todo Check if it makes that much sense to nuke the performance data? 
*/
- (void)_resetAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 0)
        return;
        
    NSArray * associations = [GeniusPair associationsForPairs:(NSArray *)contextInfo useAB:YES useBA:YES];
    [associations makeObjectsPerformSelector:@selector(reset)];
}

//! Sets the importance of the selected items from -1 to 10.
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

//! Move cursor to search field
- (IBAction) selectSearchField: (id) sender
{
    [[_searchField window] makeFirstResponder:_searchField];
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
- (void) beginQuiz:(GeniusAssociationEnumerator *)enumerator
{
    NSUndoManager *undoManager = [self undoManager];
    if([undoManager groupingLevel] > 0)
    {
        [undoManager endUndoGrouping];
        [undoManager beginUndoGrouping];
    }

    [enumerator performChooseAssociations];    // Pre-perform for progress indication

    if ([enumerator remainingCount] == 0)
    {
		NSString * title = NSLocalizedString(@"There is nothing to study.", nil);
		NSString * message = NSLocalizedString(@"Make sure the items you want to study are enabled, or add more items.", nil);
		NSString * okTitle = NSLocalizedString(@"OK", nil);

        NSAlert * alert = [NSAlert alertWithMessageText:title defaultButton:okTitle alternateButton:nil otherButton:nil informativeTextWithFormat:message];
        NSButton * defaultButton = [[alert buttons] objectAtIndex:0];
        [defaultButton setKeyEquivalent:@"\r"];
        
        [alert runModal];
    }
    else {
        MyQuizController *quizController = [[MyQuizController alloc] init];
        [quizController runQuiz:enumerator];
        [quizController release];
    }

    [self _updateStatusText];
    [self _updateLevelIndicator];
    [[self undoManager] setActionName:@"Run Quiz"];
}

//! Set up quiz mode using enabled and based probablity.
/*! 
    Uses the learn review slider value as input to probability based selection process.  In the event
    that the learn revew slider is set to review, then only previously learned items will appear in the quiz.
    Tries to setup the review for 13 items.
*/
- (IBAction)quizAutoPick:(id)sender
{
    [[tableView window] endEditingFor:nil]; 

    NSArray * associations = [self _enabledAssociationsForPairs:_pairs];
    GeniusAssociationEnumerator * enumerator = [[GeniusAssociationEnumerator alloc] initWithAssociations:associations];
    [enumerator setCount:13];    
    /*
        0% should be m=0.0 (learn only)
        50% should be m=1.0
        100% should be minimum=0 (review only)
    */
    float weight = [probabilityCenter doubleValue];
    if (weight == 100.0)
        [enumerator setMinimumScore:0]; // Review only
    float m_value = (weight / 100.0) * 2.0;
    [enumerator setProbabilityCenter:m_value];
    
    [self beginQuiz:enumerator];
}

//! Set up quiz mode using enabled and previously learned GeniusPair items.
/*! 
    Sets the minimum required score on the GeniusAssociationEnumerator to 0 which
    precludes pairs with uninitialized score values.  @see GeniusAssociation#score
*/
- (IBAction)quizReview:(id)sender
{
    [[tableView window] endEditingFor:nil]; 

    NSArray * associations = [self _enabledAssociationsForPairs:_pairs];
    GeniusAssociationEnumerator * enumerator = [[GeniusAssociationEnumerator alloc] initWithAssociations:associations];
    [enumerator setCount:13];
    [enumerator setMinimumScore:0];

    [self beginQuiz:enumerator];
}

//! Set up quiz mode using the user selected GeniusPair items.
/*! Excludes disabled items */
- (IBAction)quizSelection:(id)sender
{
    [[tableView window] endEditingFor:nil]; 

    NSArray * selectedPairs = [arrayController selectedObjects];
    if ([selectedPairs count] == 0)
        selectedPairs = _pairs;

    NSArray * associations = [self _enabledAssociationsForPairs:selectedPairs];
    GeniusAssociationEnumerator * enumerator = [[GeniusAssociationEnumerator alloc] initWithAssociations:associations];

    [self beginQuiz:enumerator];
}

@end


//! Enabled / Disable menu items.
/*! @category GeniusDocument(NSMenuValidation) */
@implementation GeniusDocument(NSMenuValidation)

//! Enable / Disable menu items.
/*!
    Handles updates of table colum toggles, auto pick quiz mode, setting of importance, duplication, and reseting.
*/
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    SEL action = [menuItem action];
    
    if (action == @selector(toggleABScoreColumn:) || action == @selector(toggleBAScoreColumn:))
    {
        NSString * titleA = [_columnHeadersDict valueForKey:@"columnA"];
        NSString * titleB = [_columnHeadersDict valueForKey:@"columnB"];

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
        NSArray * visibleColumnIdentifiers = [tableView visibleColumnIdentifiers];
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


@implementation GeniusDocument(NSTableViewDelegate)

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

@end

//! Subclass to handle item filtering
@implementation GeniusArrayController

//! Returns an object initialized from data in the provided @a decoder
- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    return self;
}

//! Releases _filterString and frees memory.
- (void) dealloc
{
    [_filterString release];
    [super dealloc];
}

//! _filterString getter
- (NSString *) filterString
{
    return _filterString;
}

//! _filterString setter.
- (void) setFilterString:(NSString *)string
{
    [string retain];
    [_filterString release];
    _filterString = string;

    [self rearrangeObjects];
}

//! Returns a given array, appropriately sorted and filtered.
- (NSArray *)arrangeObjects:(NSArray *)objects
{
    if ([_filterString length] > 0)
    {
        //! @todo Set colum bindings as a property rather than pull them from the geniusDocument.
        NSMutableArray * keyPaths = [[geniusDocument columnBindings] mutableCopy];
        //! @todo notesString is is already returned from @c columnBindings
        [keyPaths addObject:@"notesString"];
        NSMutableArray * filteredObjects = [NSMutableArray array];
        NSEnumerator * pairEnumerator = [objects objectEnumerator];
        GeniusPair * pair;
        while ((pair = [pairEnumerator nextObject]))
        {
            //! @todo surely there is a better way to do this.  Perhaps use SearchKit?
            NSString * tabularText = [pair tabularTextByOrder:keyPaths];
            NSRange range = [tabularText rangeOfString:_filterString options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound)
                [filteredObjects addObject:pair];
        }
        return [super arrangeObjects:filteredObjects];
    }
    else
    {
        return [super arrangeObjects:objects];
    }
}

@end

//! NSComboBox Supporting Methods.
/*! @category GeniusDocument(NSComboBoxDataSource) */
@implementation GeniusDocument(NSComboBoxDataSource)

//! returns index of @a aString from _customTypeStringCache.
- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
    return [_sortedCustomTypeStrings indexOfObject:aString];
}

//! returns object at @a index from _customTypeStringCache.
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
    return [_sortedCustomTypeStrings objectAtIndex:index];
}

//! returns number of items in _customTypeStringCache.
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [_sortedCustomTypeStrings count];
}

@end

//! NSComboBoxCell supporting methods.
/*! @category GeniusDocument(NSComboBoxCellDataSource) */
@implementation GeniusDocument(NSComboBoxCellDataSource)

//! returns value from _customTypeStringCache.
- (id)comboBoxCell:(NSComboBoxCell *)aComboBoxCell objectValueForItemAtIndex:(int)index
{
    return [_sortedCustomTypeStrings objectAtIndex:index];
}

//! count of _customTypeStringCache.
- (int)numberOfItemsInComboBoxCell:(NSComboBoxCell *)aComboBoxCell
{
    return [_sortedCustomTypeStrings count];
}

//! Returns index of @a string in _customTypeStringCache.
- (unsigned int)comboBoxCell:(NSComboBoxCell *)aComboBoxCell indexOfItemWithStringValue:(NSString *)string
{
    string = [aComboBoxCell stringValue];   // string comes in as (null) for some reason
    
    return [_sortedCustomTypeStrings indexOfObject:string];
}

//! Field completion for the custom type popup.
- (NSString *)comboBoxCell:(NSComboBoxCell *)aComboBoxCell completedString:(NSString*)uncompletedString
{
    NSEnumerator * stringEnumerator = [_sortedCustomTypeStrings objectEnumerator];
    NSString * string;
    while ((string = [stringEnumerator nextObject]))
        if ([[string lowercaseString] hasPrefix:[uncompletedString lowercaseString]])
            return string;
    return nil;
}

@end

//! Implementation of some of the NSWindow delegate methods.
@implementation GeniusDocument (NSWindowDelegate)

//! Removes self from notification center
- (void)windowWillClose:(NSNotification *)aNotification
{
    [self removeObserver:self];
    [_pairs makeObjectsPerformSelector:@selector(removeObserver:) withObject:self];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation GeniusDocument(NSControlDelegate)

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    BOOL retval = NO;
    if ([control isKindOfClass:[NSTextField class]] && commandSelector == @selector(insertNewline:))
    {
        retval = YES;
        [fieldEditor insertNewlineIgnoringFieldEditor:nil];
    }
    return retval;
}

@end