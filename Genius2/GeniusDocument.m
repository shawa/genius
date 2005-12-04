//  GeniusDocument.m
//  Genius2
//
//  Created by John R Chang on 2005-07-02.
//  Copyright __MyCompanyName__ 2005 . All rights reserved.

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


@interface GeniusDocument (Private)
- (void) _handleUserDefaultsDidChange:(NSNotification *)aNotification;
@end


@implementation GeniusDocument

- (id)init 
{
    self = [super init];
    if (self != nil) {
        // initialization code
    }
	
    return self;
}

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
	[documentInfoController setContent:[self documentInfo]];
	
/* Window */	
	// Set up toolbar
	[(GeniusWindowController *)windowController setupToolbarWithLevelIndicator:levelIndicator searchField:searchField];
	// [[searchField cell] setMenu:nil];

/* Table View */	
	[(GeniusWindowController *)windowController setupTableView:tableView withHeaderViewMenu:tableColumnMenu];

	NSDictionary * configDict = [[self documentInfo] tableViewConfigurationDictionary];	
	[(GeniusTableView *)tableView setConfigurationFromDictionary:configDict];

	// Configure list font size
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(_handleUserDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
	[self _handleUserDefaultsDidChange:nil];

	// Set up handler to automatically make new item if user presses Return in last row
	[nc addObserver:self selector:@selector(_handleTextDidEndEditing:) name:NSTextDidEndEditingNotification object:nil];

/* Split View */
	[(GeniusWindowController *)windowController setupSplitView:splitView];

/* Text Views */
	[(GeniusWindowController *)windowController setupAtomTextView:atomATextView];
	[(GeniusWindowController *)windowController bindTextView:atomATextView toController:itemArrayController withKeyPath:@"selection.atomA"];

	[(GeniusWindowController *)windowController setupAtomTextView:atomBTextView];
	[(GeniusWindowController *)windowController bindTextView:atomBTextView toController:itemArrayController withKeyPath:@"selection.atomB"];

/* Misc. */
	// -documentInfo created a new managed object, which sets the dirty bit
	[[self undoManager] removeAllActions];
}

- (void)dealloc
{
	//NSLog(@"-[GeniusDocument dealloc]");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (NSWindow *) mainWindow
{
	NSArray * windowControllers = [self windowControllers];
	if ([windowControllers count] == 0)
		return nil;
	return [[windowControllers objectAtIndex:0] window];
}

- (void) _dismissFieldEditor
{
	NSWindow * window = [self mainWindow];
	if ([window makeFirstResponder:window] == NO)
		[window endEditingFor:nil];
}


- (void) _handleUserDefaultsDidChange:(NSNotification *)aNotification
{
	[self _dismissFieldEditor];
	
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	// Handle font size
	int mode = [ud integerForKey:GeniusPreferencesListTextSizeModeKey];
	float fontSize = [GeniusWindowController listTextFontSizeForSizeMode:mode];

	float rowHeight = [GeniusWindowController rowHeightForSizeMode:mode];
	[tableView setRowHeight:rowHeight];

	NSEnumerator * tableColumnEnumerator = [[tableView tableColumns] objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
		[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:fontSize]];
}

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
}


- (void) _tableViewDoubleAction:(id)sender
{
	if ([sender clickedRow] == -1 || [sender clickedColumn] == -1)
		return;

	[self showRichTextEditor:sender];

	// Select all in the appropriate text view
	NSTextView * textView;
	if ([sender clickedColumn] == 1)		// XXX
		textView = atomATextView;
	else if ([sender clickedColumn] == 2)	// XXX
		textView = atomBTextView;
	[[self mainWindow] makeFirstResponder:textView];
	[textView selectAll:sender];
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
	GeniusDocumentInfo * documentInfo = nil;
		
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
			documentInfo = [array objectAtIndex:0];
	}

	// Otherwise create new documentInfo
	if (documentInfo == nil)
		documentInfo = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusDocumentInfo" inManagedObjectContext:context];
	
	return documentInfo;
}

@end


@implementation GeniusDocument (NSWindowDelegate)

/*- (void)windowDidResignKey:(NSNotification *)aNotification
{
	if ([[NSApp keyWindow] isKindOfClass:[NSPanel class]])
		[self _dismissFieldEditor];
}*/

@end


@implementation GeniusDocument (NSTableViewDelegate)

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString * identifier = [aTableColumn identifier];
    if ([identifier isEqualToString:@"grade"])
    {
        GeniusItem * item = [[itemArrayController arrangedObjects] objectAtIndex:rowIndex];		
        float grade = [[item valueForKey:@"grade"] floatValue];

        NSImage * image = nil;
        if (grade == -1)
            image = [NSImage imageNamed:@"status-red"];
        else if (grade < 0.9)
            image = [NSImage imageNamed:@"status-yellow"];
        else
            image = [NSImage imageNamed:@"status-green"];
		
        [aCell setImage:image];
    }
}

@end


@implementation GeniusDocument (GeniusTableViewDelegate)

- (NSArray *)tableViewDefaultHiddenTableColumnIdentifiers:(NSTableView *)aTableView
{
	return [NSArray arrayWithObjects:GeniusItemMyGroupKey, GeniusItemMyTypeKey, GeniusItemLastTestedDateKey, GeniusItemLastModifiedDateKey, nil];
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
	int index = [ud integerForKey:GeniusPreferencesListTextSizeModeKey];
	float fontSize = [GeniusWindowController listTextFontSizeForSizeMode:index];
	[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:fontSize]];
}


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

@end

@implementation GeniusDocument (NSTableDataSource)

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard*)pboard
{
    [pboard declareTypes:[NSArray arrayWithObjects:NSTabularTextPboardType, nil] owner:self];
    
    // Convert row numbers to items
    _itemsDuringDrag = [NSMutableArray array];
    NSEnumerator * rowNumberEnumerator = [rows objectEnumerator];
    NSNumber * rowNumber;
    while ((rowNumber = [rowNumberEnumerator nextObject]))
    {
        GeniusItem * item = [[itemArrayController arrangedObjects] objectAtIndex:[rowNumber intValue]];
        [(NSMutableArray *)_itemsDuringDrag addObject:item];
    }    

    NSString * outputString = [GeniusItem tabularTextFromItems:_itemsDuringDrag];
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

        NSArray * items = [GeniusItem itemsFromTabularText:string];
        //[itemArrayController setFilterString:@""];
        [itemArrayController addObjects:items];
    }
        
//    [self _markDocumentDirty:nil];
    return YES;
}

@end


@implementation GeniusDocument (NSMenuValidation)

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	// Edit menu
	if ([menuItem action] == @selector(delete:))
	{
		return [itemArrayController selectionIndex] != NSNotFound;
	}
	// Format menu
	else if ([menuItem action] == @selector(makePlainText:))
	{
		NSArray * selectedObjects = [itemArrayController selectedObjects];
		if ([selectedObjects count] == 0)
			return NO;
			
		NSEnumerator * objectEnumerator = [selectedObjects objectEnumerator];
		GeniusItem * item;
		while ((item = [objectEnumerator nextObject]))
			if ([item usesDefaultTextAttributes] == NO)
				return YES;
		
		return NO;
	}
	else if ([menuItem action] == @selector(resetItemScore:))
	{
		return [itemArrayController selectionIndex] != NSNotFound;
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


@implementation GeniusDocument (Actions)

// File menu

- (IBAction)exportFile:(id)sender
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
    [savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", nil)];
    [savePanel setPrompt:NSLocalizedString(@"Export", nil)];
    
    NSWindowController * windowController = [[self windowControllers] lastObject];
    [savePanel beginSheetForDirectory:nil file:nil modalForWindow:[windowController window] modalDelegate:self didEndSelector:@selector(_exportFileDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)_exportFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSString * path = [sheet filename];
    if (path == nil)
        return;

    // TO DO: Construct line of headers
    
    NSArray * arrangedObjects = [itemArrayController arrangedObjects];
    NSString * tabularText = [GeniusItem tabularTextFromItems:arrangedObjects];
    [tabularText writeToFile:path atomically:NO];
}


// Edit menu

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

// Item menu

- (IBAction) newItem:(id)sender
{
	[self _dismissFieldEditor];

	id newObject = [itemArrayController newObject];
	[itemArrayController addObject:newObject];

	// Auto-select first text field
	if ([[self mainWindow] isKeyWindow])
	{
		int rowIndex = [[itemArrayController arrangedObjects] indexOfObject:newObject];
		[tableView editColumn:1 row:rowIndex withEvent:nil select:YES];
	}
}

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

- (IBAction) swapColumns:(id)sender
{
	NSArray * selectedObjects = [itemArrayController selectedObjects];
	[selectedObjects makeObjectsPerformSelector:@selector(swapAtoms)];

	[itemArrayController rearrangeObjects];
}

- (IBAction) makePlainText:(NSMenuItem *)sender
{
	NSString * messageText = NSLocalizedString(@"Convert the selected items to plain text?", nil);
	NSString * informativeText = NSLocalizedString(@"If you convert the items, you will lose all text styles (such as fonts and colors) and attachments.", nil);
	NSString * defaultButton = NSLocalizedString(@"Convert", nil);
	NSString * alternateButton = NSLocalizedString(@"Cancel", nil);

	NSAlert * alert = [NSAlert alertWithMessageText:messageText defaultButton:defaultButton
		alternateButton:alternateButton otherButton:nil informativeTextWithFormat:informativeText];
	[alert beginSheetModalForWindow:[self mainWindow] modalDelegate:self didEndSelector:@selector(_makePlainTextAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)_makePlainTextAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	if (returnCode == 0)	// Cancel	// XXX: documentation says it's supposed to be NSAlertSecondButtonReturn
		return;

	NSArray * selectedObjects = [itemArrayController selectedObjects];
	[selectedObjects makeObjectsPerformSelector:@selector(clearTextAttributes)];

	[atomATextView setTypingAttributes:[NSDictionary dictionary]];	// nil doesn't have any effect
	[atomBTextView setTypingAttributes:[NSDictionary dictionary]];	// nil doesn't have any effect
}


- (IBAction) resetItemScore:(id)sender
{
	NSArray * selectedObjects = [itemArrayController selectedObjects];
	[selectedObjects makeObjectsPerformSelector:@selector(resetAssociations)];

	[tableView reloadData];
}

// Format menu

- (IBAction) showRichTextEditor:(id)sender
{
	NSView * bottomView = [[splitView subviews] objectAtIndex:1];
	int i;
	for (i=0; i<4; i++)
	{
		[bottomView setFrameSize:NSMakeSize([splitView frame].size.width, 128.0)];
		[splitView adjustSubviews];
		[splitView displayIfNeeded];
	}
}


// Study menu

- (IBAction) setQuizDirectionModeAction:(NSMenuItem *)sender
{
	int tag = [sender tag];
	[[self documentInfo] setQuizDirectionMode:tag];
	
	NSArray * arrangedObjects = [itemArrayController arrangedObjects];
	NSEnumerator * objectEnumerator = [arrangedObjects objectEnumerator];
	GeniusItem * item;
	while ((item = [objectEnumerator nextObject]))
		[item flushCache];
	
	[tableView reloadData];
}

- (IBAction) runQuiz:(id)sender
{
	// XXX: let user choose number of items or time limit, initial set of associations

	QuizController * quiz = [[QuizController alloc] initWithDocument:self];
	[quiz runQuiz];
	[quiz release];
}

@end
