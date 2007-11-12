//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusDocument.h"

#import "GeniusWindowController.h"
#import "GeniusWindowToolbar.h"
#import "GeniusPreferences.h"

// View
#import "GeniusTableView.h"

// Model
#import "GeniusDocumentInfo.h"
#import "GeniusItem.h"	// actions
#import "GeniusAtom.h"	// -toggleColumnRichText:

// Quiz
#import "QuizModel.h"
#import "QuizController.h"


const int kGeniusDocumentAtomAColumnIndex = 1;

static NSString * GeniusDocumentOverallPercentKey = @"overallPercent";
static NSString * GeniusDocumentCorrectCountABKey = @"correctCountAB";
static NSString * GeniusDocumentCorrectCountBAKey = @"correctCountBA";

@interface GeniusDocument (Private)
- (void) touchOverallPercent;
@end


@implementation GeniusDocument

- (id)init 
{
    self = [super init];
    if (self != nil) {
        // initialization code


		NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(_itemScoreHasChangedNotification:) name:GeniusItemScoreHasChangedNotification object:nil];
    }
	
    return self;
}

/*- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
	self = [super initWithType:typeName error:outError];
	[NSEntityDescription insertNewObjectForEntityForName:@"GeniusItem" inManagedObjectContext:[self managedObjectContext]];	
	return self;
}*/

- (void)makeWindowControllers
{
	GeniusWindowController * wc = [[GeniusWindowController alloc] initWithWindowNibName:@"GeniusDocument" owner:self];
	[self addWindowController:wc];
	[wc release];
}


/*
	Warning: "If you have a nib in which File's Owner is a subclass of
	NSWindowController or NSDocument, do not bind anything through file's owner."
	http://theobroma.treehouseideas.com/document.page/18
*/
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{	
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code

/* Hook up object controllers */
	[itemArrayController setManagedObjectContext:[self managedObjectContext]];

/* Window */	
	// Set up toolbar
	[(GeniusWindowController *)windowController setupToolbarWithLevelIndicator:levelIndicator searchField:searchField];
	//[[searchField cell] setSearchMenuTemplate:nil];

/* Table View */	
	[(GeniusWindowController *)windowController setupTableView:tableView];

	NSDictionary * configDict = [[self documentInfo] tableViewConfigurationDictionary];
	if (configDict)
		[(GeniusTableView *)tableView setConfigurationFromDictionary:configDict];

	// Set up handler to automatically make new item if user presses Return in last row
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(_handleTextDidEndEditing:) name:NSTextDidEndEditingNotification object:nil];

	// Set up drag-and-drop
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSTabularTextPboardType, NSStringPboardType, nil]];    
	[tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];

/* Split View */
	[(GeniusWindowController *)windowController setupSplitView:splitView];

/* Text Views */
	[(GeniusWindowController *)windowController setupAtomTextView:atomATextView];
	[(GeniusWindowController *)windowController setupAtomTextView:atomBTextView];

	// In order to set NSNoSelectionPlaceholderBindingOption
	[(GeniusWindowController *)windowController bindTextView:atomATextView toController:itemArrayController withKeyPath:@"selection.atomA"];
	[(GeniusWindowController *)windowController bindTextView:atomBTextView toController:itemArrayController withKeyPath:@"selection.atomB"];

/* Misc. */
	[[self undoManager] removeAllActions]; // -documentInfo created a new managed object, which sets the dirty bit
//	[tableView editColumn:kGeniusDocumentAtomAColumnIndex row:1 withEvent:nil select:YES];
}

- (void)dealloc
{	
	NSLog(@"dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_documentInfo release];
	
	[super dealloc];
}


- (NSWindowController *) windowController
{
	NSArray * windowControllers = [self windowControllers];
	if ([windowControllers count] == 0)
		return nil;
	return [windowControllers objectAtIndex:0];
}

- (NSWindow *) window
{
	return [[self windowController] window];
}


- (void) _dismissFieldEditor
{
	NSWindow * window = [self window];
	if ([window makeFirstResponder:window] == NO)
		[window endEditingFor:nil];
}


// Make new item if user presses Return in last row
- (void) _handleTextDidEndEditing:(NSNotification *)aNotification
{
	NSView * textView = [aNotification object];
	if ([textView isDescendantOf:tableView])
	{
		if ([tableView selectedRow] == [tableView numberOfRows] - 1)
		{
			NSNumber * textMovement = [[aNotification userInfo] objectForKey:@"NSTextMovement"];
			int movementCode = [textMovement intValue];
			if (movementCode == NSReturnTextMovement)
			{
				[self newItem:nil];
			}
		}
	}
	
	[atomATextView display];
}

- (void) _tableViewDoubleAction:(id)sender
{
	if ([sender clickedRow] == -1 || [sender clickedColumn] == -1)
		return;

	if ([sender clickedColumn] == 1 || [sender clickedColumn] == 2)
		[(GeniusWindowController *)[self windowController] showRichTextEditor:sender];

	// Select all in the appropriate text view
/*	NSTextView * textView;
	if ([sender clickedColumn] == 1)		// XXX
		textView = atomATextView;
	else if ([sender clickedColumn] == 2)	// XXX
		textView = atomBTextView;
	[[self window] makeFirstResponder:textView];
	[textView selectAll:sender];*/
}


#if 1
- (NSError *)willPresentError:(NSError *)inError {
    // The error is a Core Data validation error if its domain is
    // NSCocoaErrorDomain and it is between the minimum and maximum
    // for Core Data validation error codes.
    if (!([[inError domain] isEqualToString:NSCocoaErrorDomain])) {
        return inError;
    }
    int errorCode = [inError code];
    if ((errorCode < NSValidationErrorMinimum) ||
                (errorCode > NSValidationErrorMaximum)) {
        return inError;
    }
    // If there are multiple validation errors, inError is an 
    // NSValidationMultipleErrorsError. If it's not, return it
    if (errorCode != NSValidationMultipleErrorsError) {
        return inError;
    }
    // For an NSValidationMultipleErrorsError, the original errors
    // are in an array in the userInfo dictionary for key NSDetailedErrorsKey
    NSArray *detailedErrors = [[inError userInfo] objectForKey:NSDetailedErrorsKey];
    // For this example, only present error messages for up to 3 validation errors at a time.
    unsigned numErrors = [detailedErrors count];
    NSMutableString *errorString = [NSMutableString stringWithFormat:@"%u validation errors have occurred", numErrors];
    if (numErrors > 3) {
        [errorString appendFormat:@".\nThe first 3 are:\n"];
    } else {
        [errorString appendFormat:@":\n"];
    }
    unsigned i, displayErrors = numErrors > 3 ? 3 : numErrors;
    for (i = 0; i < displayErrors; i++) {
        [errorString appendFormat:@"%@\n",
            [[detailedErrors objectAtIndex:i] localizedDescription]];
    }
    // Create a new error with the new userInfo
    NSMutableDictionary *newUserInfo = [NSMutableDictionary
                dictionaryWithDictionary:[inError userInfo]];
    [newUserInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
    NSError *newError = [NSError errorWithDomain:[inError domain] code:[inError code] userInfo:newUserInfo];  
    return newError;
}
#endif


- (NSArrayController *) itemArrayController
{
	return itemArrayController;
}


- (GeniusDocumentInfo *) documentInfo
{
	if (_documentInfo == nil)
	{			
		// Attempt to fetch pre-existing documentInfo
		NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
		NSManagedObjectContext * context = [self managedObjectContext];
		NSEntityDescription * entity = [NSEntityDescription entityForName:@"GeniusDocumentInfo" inManagedObjectContext:context];
		[request setEntity:entity];
		NSError * error = nil;
		NSArray * array = [context executeFetchRequest:request error:&error];
		if (array)
		{
			int count = [array count]; // may be 0
			if (count == 1)
				_documentInfo = [[array objectAtIndex:0] retain];
		}

		// Otherwise create new documentInfo
		if (_documentInfo == nil)
		{
			_documentInfo = [[NSEntityDescription insertNewObjectForEntityForName:@"GeniusDocumentInfo" inManagedObjectContext:context] retain];
		}
	}
	
	return _documentInfo;
}


- (float) overallPercent
{
	float sum = 0.0;
	NSArray * arrangedObjects = [itemArrayController arrangedObjects];
	NSEnumerator * itemEnumerator = [arrangedObjects objectEnumerator];
	GeniusItem * item;
	while ((item = [itemEnumerator nextObject]))
	{
		float grade = [item grade];
		if (grade != -1.0)
			sum += grade;
	}

	return sum / [arrangedObjects count] * 100.0;
}

- (void) touchOverallPercent
{
	[self willChangeValueForKey:GeniusDocumentOverallPercentKey];
	[self didChangeValueForKey:GeniusDocumentOverallPercentKey];
}

- (void) setOverallPercent:(float)value
{
	[self touchOverallPercent];
	// do nothing
}

- (void) _itemScoreHasChangedNotification:(NSNotification *)notification
{
	[self touchOverallPercent];
}

@end


@implementation GeniusDocument (NSTableDataSource)	// drag-and-drop

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    [pboard declareTypes:[NSArray arrayWithObjects:NSTabularTextPboardType, NSStringPboardType, nil] owner:self];
    
    // Convert row numbers to items
    _itemsDuringDrag = [[itemArrayController arrangedObjects] objectsAtIndexes:rowIndexes];

    NSString * tabularText = [GeniusItem tabularTextFromItems:_itemsDuringDrag];
    [pboard setString:tabularText forType:NSTabularTextPboardType];
    [pboard setString:tabularText forType:NSStringPboardType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{	
    if ([info draggingSource] == aTableView)    // intra-document
    {
        if (operation == NSTableViewDropOn)
            return NSDragOperationNone;
		else
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
        NSArray * copyOfItemsDuringDrag = [[NSArray alloc] initWithArray:_itemsDuringDrag copyItems:YES];
    
        NSIndexSet * indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [copyOfItemsDuringDrag count])];
        [itemArrayController insertObjects:copyOfItemsDuringDrag atArrangedObjectIndexes:indexes];
        
        if ([info draggingSource] == aTableView)
            [itemArrayController removeObjects:_itemsDuringDrag];
        
        [copyOfItemsDuringDrag release];
        _itemsDuringDrag = nil;
    }
    else                                        // inter-document, inter-application
    {
        NSPasteboard * pboard = [info draggingPasteboard];
        NSString * string = [pboard stringForType:NSStringPboardType];
        if (string == nil)
            return NO;

        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        NSArray * items = [GeniusItem itemsFromTabularText:string order:[GeniusItem keyPathOrderForTextRepresentation]];
        //[self setFilterString:@""];
        [itemArrayController addObjects:items];
    }
        
//    [self _markDocumentDirty:nil];
    return YES;
}

@end


@implementation GeniusDocument (NSTableViewDelegate)

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString * identifier = [aTableColumn identifier];
    if ([identifier isEqualToString:GeniusItemDisplayGradeKey])
    {
        GeniusItem * item = [[itemArrayController arrangedObjects] objectAtIndex:rowIndex];		
		NSImage * image = [item gradeIcon];
        [aCell setImage:image];
    }
}

@end


@implementation GeniusDocument (CustomizableTableViewDelegate)

- (NSArray *)tableViewDefaultTableColumnIdentifiers:(NSTableView *)aTableView
{
	return [NSArray arrayWithObjects:GeniusItemIsEnabledKey, GeniusItemAtomAKey, GeniusItemAtomBKey,
		GeniusDocumentCorrectCountABKey, GeniusItemDisplayGradeKey, nil];
}

- (void) tableView:(NSTableView *)aTableView didHideTableColumn:(NSTableColumn *)tableColumn
{
	NSDictionary * configDict = [(GeniusTableView *)aTableView configurationDictionary];
	[[self documentInfo] setTableViewConfigurationDictionary:configDict];	
}

- (void) tableView:(NSTableView *)aTableView didShowTableColumn:(NSTableColumn *)tableColumn
{
	NSDictionary * configDict = [(GeniusTableView *)aTableView configurationDictionary];
	[[self documentInfo] setTableViewConfigurationDictionary:configDict];	

	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
	int mode = [ud integerForKey:GeniusPreferencesListTextSizeModeKey];
	float fontSize = [GeniusWindowController listTextFontSizeForSizeMode:mode];
	[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:fontSize]];
}


- (BOOL) tableView:(NSTableView *)aTableView shouldChangeHeaderTitleOfTableColumn:(NSTableColumn *)aTableColumn
{
	NSString * identifier = [aTableColumn identifier];
	if ([identifier isEqual:GeniusItemAtomAKey] || [identifier isEqual:GeniusItemAtomBKey])
		return YES;
	return NO;
}

- (void) tableView:(NSTableView *)aTableView didChangeHeaderTitleOfTableColumn:(NSTableColumn *)aTableColumn
{
	NSDictionary * configDict = [(GeniusTableView *)aTableView configurationDictionary];
	[[self documentInfo] setTableViewConfigurationDictionary:configDict];	
}

@end


@implementation GeniusDocument (GeniusTableViewDelegate)

- (BOOL)performKeyDown:(NSEvent *)theEvent
{	
	if (([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == 0)
	{
		if ([theEvent keyCode] == 36)	// Return
		{
			// If the user presses Return on a selected item, start editing it
			int selectedRow = [tableView selectedRow];
			if (selectedRow != -1)
			{
				[tableView editColumn:kGeniusDocumentAtomAColumnIndex row:selectedRow withEvent:nil select:YES];
				return YES;
			}
		}
		else if ([theEvent keyCode] == 51)	// Delete
		{	
			// Delete the selected item
			[self delete:self];
			return YES;
		}
	}
	
	return NO;
}

@end


@implementation GeniusDocument (NSTextViewDelegate)

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
	NSTextView * textView = [aNotification object];
	
	if ([[textView string] length] == 0)
		[textView setTypingAttributes:[GeniusAtom defaultTextAttributes]];
}

// Workaround suspected bindings bug where data model doesn't get updated if string only contains an image
- (void)textDidEndEditing:(NSNotification *)aNotification
{
	NSTextView * textView = [aNotification object];

	NSAttributedString * attrString = [textView textStorage];	
	if ([attrString containsAttachments])
	{
		// attrString -> rtfdData
		NSRange range = NSMakeRange(0, [attrString length]);
		NSData * rtfdData = [attrString RTFDFromRange:range documentAttributes:nil];

		NSDictionary * infoForBinding = [textView infoForBinding:NSDataBinding];
		NSString * object = [infoForBinding objectForKey:NSObservedObjectKey];
		NSString * keyPath = [infoForBinding objectForKey:NSObservedKeyPathKey];
		
		[object setValue:rtfdData forKeyPath:keyPath];
	}
}

@end


@implementation GeniusDocument (NSMenuValidation)

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	// Edit menu
	if ([menuItem action] == @selector(delete:)
		|| [menuItem action] == @selector(duplicate:)
		|| [menuItem action] == @selector(setItemRating:)
		|| [menuItem action] == @selector(swapColumns:))
	{
		return [itemArrayController selectionIndex] != NSNotFound;
	}
	// Format menu
	else if ([menuItem action] == @selector(makePlainText:))
	{
		NSArray * selectedObjects = [itemArrayController selectedObjects];
		NSEnumerator * objectEnumerator = [selectedObjects objectEnumerator];
		GeniusItem * item;
		while ((item = [objectEnumerator nextObject]))
			if ([item usesDefaultTextAttributes] == NO)
				return YES;		
		return NO;
	}
	else if ([menuItem action] == @selector(resetItemScore:))
	{
		NSArray * selectedObjects = [itemArrayController selectedObjects];
		NSEnumerator * objectEnumerator = [selectedObjects objectEnumerator];
		GeniusItem * item;
		while ((item = [objectEnumerator nextObject]))
			if ([item isAssociationsReset] == NO)
				return YES;		
		return NO;
	}
	// Study menu
	else if ([menuItem action] == @selector(setQuizDirectionModeAction:))
	{
		int tag = [menuItem tag];
		int quizDirectionMode = [[self documentInfo] quizDirectionMode];
		[menuItem setState:(tag == quizDirectionMode) ? NSOnState : NSOffState];
	}
	
	return [super validateMenuItem:menuItem];
}

@end


/*!
    @category GeniusDocument(Actions)
    @abstract Collections of methods accessed directly from the GUI.
 */
@implementation GeniusDocument(Actions)

//! Initiates modal sheet for selecting export file.
- (IBAction)exportFile:(id)sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
    [savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", nil)];
    [savePanel setPrompt:NSLocalizedString(@"Export", nil)];
    
    NSWindowController * windowController = [[self windowControllers] lastObject];
    [savePanel beginSheetForDirectory:nil file:nil modalForWindow:[windowController window] modalDelegate:self didEndSelector:@selector(_exportFileDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

//! Handles user response to modal sheet initiated in exportFile:.
- (void)_exportFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSString * path = [sheet filename];
    if (path == nil)
        return;

    //! @todo Construct line of headers
    
    NSArray * arrangedObjects = [itemArrayController arrangedObjects];
    NSString * tabularText = [GeniusItem tabularTextFromItems:arrangedObjects];
    [tabularText writeToFile:path atomically:NO];
}


//! Deletes the selected items.
- (IBAction)delete:(id)sender
{
    NSArray * selectedObjects = [itemArrayController selectedObjects];
	if ([selectedObjects count] == 0)
	{
		NSBeep();
		return;
	}
	
    [itemArrayController removeObjects:selectedObjects];
}

//! copies the selected items and inserts them in the active genius document
- (IBAction) duplicate:(id)sender
{
	[self _dismissFieldEditor];

    NSArray * selectedObjects = [itemArrayController selectedObjects];

    NSIndexSet * selectionIndexes = [itemArrayController selectionIndexes];
    int lastIndex = [selectionIndexes lastIndex];
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastIndex+1, [selectionIndexes count])];
    NSArray * newObjects = [[NSArray alloc] initWithArray:selectedObjects copyItems:YES];
    [itemArrayController insertObjects:newObjects atArrangedObjectIndexes:indexSet];
    [itemArrayController setSelectedObjects:newObjects];
    [newObjects release];
}


//! Creates and inserts a new Item.
- (IBAction) newItem:(id)sender
{
	[self _dismissFieldEditor];

	id newObject = [itemArrayController newObject];
	[itemArrayController addObject:newObject];

	// Auto-select first text field
	if ([[self window] isKeyWindow])
	{
		int rowIndex = [[itemArrayController arrangedObjects] indexOfObject:newObject];
		[tableView editColumn:kGeniusDocumentAtomAColumnIndex row:rowIndex withEvent:nil select:YES];
	}
}

//! Sets users rating (importance) for the selected item.
- (IBAction) setItemRating:(NSMenuItem *)sender
{
	int newRating = [sender tag];
	NSNumber * newRatingValue = (newRating == 0) ? nil : [NSNumber numberWithInt:newRating];
	
	NSArray * selectedObjects = [itemArrayController selectedObjects];
	NSEnumerator * objectEnumerator = [selectedObjects objectEnumerator];
	GeniusItem * item;
	while ((item = [objectEnumerator nextObject]))
		[item setValue:newRatingValue forKey:@"myRating"];
}

//! Makes all the b items a items and vice versa.
- (IBAction) swapColumns:(id)sender
{
	NSArray * selectedObjects = [itemArrayController selectedObjects];
	[selectedObjects makeObjectsPerformSelector:@selector(swapAtoms)];

	[itemArrayController rearrangeObjects];
}


//! Initiates modal sheet to check if the user really wants to drop formatting.
/*!
    @todo make formating part of display.
*/
- (IBAction) makePlainText:(NSMenuItem *)sender
{
	NSString * messageText = NSLocalizedString(@"Convert the selected items to plain text?", nil);
	NSString * informativeText = NSLocalizedString(@"If you convert the items, you will lose all text styles (such as fonts and colors) and attachments.", nil);
	NSString * defaultButtonTitle = NSLocalizedString(@"Convert", nil);
	NSString * alternateButtonTitle = NSLocalizedString(@"Cancel", nil);

	NSAlert * alert = [NSAlert alertWithMessageText:messageText defaultButton:defaultButtonTitle
		alternateButton:alternateButtonTitle otherButton:nil informativeTextWithFormat:informativeText];
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(_makePlainTextAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

//! actually removes the formatting.  @see makePlainText:
- (void)_makePlainTextAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	if (returnCode == 0)	// Cancel	// XXX: documentation says it's supposed to be NSAlertSecondButtonReturn
		return;

	NSArray * selectedObjects = [itemArrayController selectedObjects];
	[selectedObjects makeObjectsPerformSelector:@selector(clearTextAttributes)];

	[atomATextView setTypingAttributes:[NSDictionary dictionary]];	// nil doesn't have any effect
	[atomBTextView setTypingAttributes:[NSDictionary dictionary]];	// nil doesn't have any effect
}

//! Erases all historical information about testing for the selected item.
/*! @todo This isn't what reset means in the 1.7 version */
- (IBAction) resetItemScore:(id)sender
{
	NSArray * selectedObjects = [itemArrayController selectedObjects];
	[selectedObjects makeObjectsPerformSelector:@selector(resetAssociations)];

	[tableView reloadData];
}


//! Enables / disables BA testing direction.
- (IBAction) setQuizDirectionModeAction:(NSMenuItem *)sender
{
	int tag = [sender tag];
	[[self documentInfo] setQuizDirectionMode:tag];

	if (tag == GeniusQuizBidirectionalMode)
	{
		NSTableColumn * tableColumn = [tableView tableColumnWithIdentifier:GeniusDocumentCorrectCountBAKey];
		int index = [[tableView toggleColumnsMenu] indexOfItemWithRepresentedObject:tableColumn];
		if (index != NSNotFound)
		{
			NSMenuItem * menuItem = [[tableView toggleColumnsMenu] itemAtIndex:index];
			if ([menuItem state] == NSOffState)
				[tableView toggleTableColumnShown:menuItem];
		}
	}

	[tableView reloadData];
}

//! runs a quiz with default quiz model parameters.
- (IBAction) runQuiz:(id)sender
{
	//! @todo let user choose initial set of items

	QuizController * quiz = [[QuizController alloc] initWithDocument:self];
	[quiz runQuiz];
	[quiz release];
}

@end
