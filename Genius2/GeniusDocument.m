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
	if ([sender clickedRow] == -1)
		return;
	int clickedColumn = [sender clickedColumn];
	if ([sender clickedColumn] == -1)
		return;

	// XXX
/*	GeniusInspectorController * ic = [GeniusInspectorController sharedInspectorController];
	[ic window];	// load window

	NSTableColumn * column = [[sender tableColumns] objectAtIndex:clickedColumn];
	NSString * identifier = [column identifier];
	[[ic tabView] selectTabViewItemWithIdentifier:identifier];

	[ic showWindow:sender];*/
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

/*- (IBAction) exportFile:(id)sender
{
	// TO DO
}*/


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

/*- (IBAction) swapColumns:(id)sender
{
	// TO DO
}*/

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
