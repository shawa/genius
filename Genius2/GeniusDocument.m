//  GeniusDocument.m
//  Genius2
//
//  Created by John R Chang on 2005-07-02.
//  Copyright __MyCompanyName__ 2005 . All rights reserved.

#import "GeniusDocument.h"
#import "GeniusDocumentToolbar.h"
#import "GeniusDocumentInfo.h"

#import "IconTextFieldCell.h"

#import "GeniusItem.h"	// actions

#import "GeniusInspectorController.h"


@implementation GeniusDocument

- (id)init 
{
    self = [super init];
    if (self != nil) {
        // initialization code
		_tableColumnDictionary = nil;
		_inspectorController = nil;
    }
	
    return self;
}

- (void) dealloc
{
	[_inspectorController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_tableColumnDictionary release];
	[super dealloc];
}

- (NSString *)windowNibName 
{
    return @"GeniusDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{	
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
	
	// Set up window toolbar
	[self setupToolbarForWindow:[windowController window]];
	
	// Retain table columns
	_tableColumnDictionary = [NSMutableDictionary new];
	NSArray * tableColumns = [tableView tableColumns];
	NSEnumerator * tableColumnEnumerator = [tableColumns objectEnumerator];
	NSTableColumn * tableColumn;
	while ((tableColumn = [tableColumnEnumerator nextObject]))
	{
		NSString * columnTitle = [[tableColumn headerCell] stringValue];
		[(NSMutableDictionary *)_tableColumnDictionary setObject:tableColumn forKey:columnTitle];
	}

	// Remove non-default table columns
	NSArray * hiddenColumnIdentifiers = [[self documentInfo] hiddenColumnIdentifiers];
	NSEnumerator * hiddenColumnIdentifierEnumerator = [hiddenColumnIdentifiers objectEnumerator];
	NSString * identifier;
	while ((identifier = [hiddenColumnIdentifierEnumerator nextObject]))
	{
		tableColumn = [tableView tableColumnWithIdentifier:identifier];
		[tableView removeTableColumn:tableColumn];
	}

	// Set up line break mode for table columns
	tableColumn = [tableView tableColumnWithIdentifier:@"atomA"];
	[[tableColumn dataCell] setLineBreakMode:NSLineBreakByTruncatingTail];

	tableColumn = [tableView tableColumnWithIdentifier:@"atomB"];
	[[tableColumn dataCell] setLineBreakMode:NSLineBreakByTruncatingTail];

	// Set up handler to automatically make new item if user presses Return in last row
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleTextDidEndEditing:) name:NSTextDidEndEditingNotification object:nil];
	
    // Set up icon text field cells for colored grade indication
    tableColumn = [tableView tableColumnWithIdentifier:@"grade"];
    IconTextFieldCell * cell = [IconTextFieldCell new];
    [tableColumn setDataCell:cell];
    //NSNumberFormatter * numberFormatter = [[tableColumn dataCell] formatter];
    //[cell setFormatter:numberFormatter];
	
	// Set up contextual menu on the table column headers
	[[tableView headerView] setMenu:tableColumnMenu];
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


@implementation GeniusDocument (NSMenuValidation)

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if ([menuItem action] == @selector(toggleColumnRichText:))
	{
		int tag = [menuItem tag];
		if (tag == 0)
			[menuItem setState:([[self documentInfo] isColumnARichText] ? NSOnState : NSOffState)];
		else if (tag == 1)
			[menuItem setState:([[self documentInfo] isColumnBRichText] ? NSOnState : NSOffState)];
	}
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

// Edit menu

- (IBAction) selectSearchField:(id)sender
{
	[searchField selectText:sender];
}


// Item menu

- (IBAction) newItem:(id)sender
{
	id newObject = [itemArrayController newObject];
	[itemArrayController addObject:newObject];

	int rowIndex = [[itemArrayController arrangedObjects] indexOfObject:newObject];
	[tableView editColumn:1 row:rowIndex withEvent:nil select:YES];
}

- (IBAction) toggleInspector:(id)sender
{
	if (_inspectorController == nil)
	{
		_inspectorController = [[GeniusInspectorController alloc] initWithWindowNibName:@"GeniusInspector"];
		[(GeniusInspectorController *)_inspectorController setDocument:self];
	}
	
	if ([[_inspectorController window] isVisible])
		[_inspectorController close];
	else
		[_inspectorController showWindow:sender];
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

- (IBAction) resetItemScore:(id)sender
{
	NSArray * selectedObjects = [itemArrayController selectedObjects];
	NSEnumerator * objectEnumerator = [selectedObjects objectEnumerator];
	GeniusItem * item;
	while ((item = [objectEnumerator nextObject]))
		[item resetAssociations];

	[tableView reloadData];
}


// Format menu

- (IBAction) toggleColumnRichText:(NSMenuItem *)sender
{
	BOOL currentValue = NO;
	int columnIndex = [sender tag];
	if (columnIndex == 0)
		currentValue = [[self documentInfo] isColumnARichText];
	else if (columnIndex == 1)
		currentValue = [[self documentInfo] isColumnBRichText];

	if (currentValue == YES)
	{
		NSString * messageText = NSLocalizedString(@"Convert this column to plain text?", nil);
		NSString * informativeText = NSLocalizedString(@"If you convert this column, you will lose all text styles (such as fonts and colors) and attachments.", nil);
		NSString * defaultButton = NSLocalizedString(@"Convert", nil);
		NSString * alternateButton = NSLocalizedString(@"Don't Convert", nil);

		NSAlert * alert = [NSAlert alertWithMessageText:messageText defaultButton:defaultButton
			alternateButton:alternateButton otherButton:nil informativeTextWithFormat:informativeText];
		int returnCode = [alert runModal];
		if (returnCode == 0)	// No	// XXX: documentation says it's supposed to be NSAlertSecondButtonReturn
			return;
	}
	
	currentValue = !currentValue;
	NSArray * arrangedObjects = [itemArrayController arrangedObjects];
	NSEnumerator * objectEnumerator = [arrangedObjects objectEnumerator];
	GeniusItem * item;
	while ((item = [objectEnumerator nextObject]))
		[item setUsesRichText:currentValue forAtomAtIndex:columnIndex];
	
	if (columnIndex == 0)
		[[self documentInfo] setIsColumnARichText:currentValue];
	else if (columnIndex == 1)
		[[self documentInfo] setIsColumnBRichText:currentValue];
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
	NSBeep();
	// TO DO
}

- (IBAction) toggleSoundEffects:(id)sender
{
	// do nothing - NSUserDefaultsController handles this in the nib
}


// table view pop-up menu

- (IBAction) toggleTableColumnShown:(NSMenuItem *)sender
{
	NSString * menuItemTitle = [sender title];
	NSTableColumn * tableColumn = [_tableColumnDictionary objectForKey:menuItemTitle];

	NSArray * hiddenColumnIdentifiers = [[self documentInfo] hiddenColumnIdentifiers];
	
	int state = [sender state];			
	if (state == NSOnState)
	{
		[tableView removeTableColumn:tableColumn];	// hide

		hiddenColumnIdentifiers = [hiddenColumnIdentifiers arrayByAddingObject:[tableColumn identifier]];
	}
	else
	{
		// TO DO: add in order
		[tableView addTableColumn:tableColumn];		// show

		hiddenColumnIdentifiers = [[hiddenColumnIdentifiers mutableCopy] autorelease];
		[(NSMutableArray *)hiddenColumnIdentifiers removeObject:[tableColumn identifier]];
	}
	
	[sender setState:(state == NSOffState ? NSOnState : NSOffState)];
	
	[[self documentInfo] setHiddenColumnIdentifiers:hiddenColumnIdentifiers];
}

@end
