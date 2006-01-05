#import "GeniusDocumentController.h"

#import "GeniusDocument.h"
#import "GeniusV1FileImporter.h"
#import "GeniusItem.h"


@implementation GeniusDocumentController

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError
{
    NSDocument * oldDoc = [self currentDocument];
    BOOL shouldCloseExistingWindow = (oldDoc && [[self documents] count] == 1 && [oldDoc isDocumentEdited] == NO
		&& [[[(GeniusDocument *)oldDoc itemArrayController] content] count] == 0);

	NSDocument * newDoc = [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
	if (newDoc == nil)
		return nil;
	
	// Close existing untitled window if necessary
	if (shouldCloseExistingWindow)
	{
		NSArray * windowControllers = [newDoc windowControllers];
		if (windowControllers && [windowControllers count] > 0)
		{
			NSWindow * oldWindow = [(GeniusDocument *)oldDoc window];
			NSWindow * newWindow = [[windowControllers objectAtIndex:0] window];
			[newWindow setFrame:[oldWindow frame] display:YES];
			[oldWindow close];
		}
	}

	return newDoc;
}


/*
	"How can I support reading one type and (internally) automatically converting to another?"
	file:///Developer/ADC%20Reference%20Library/documentation/Cocoa/Conceptual/Documents/Tasks/FAQ.html#//apple_ref/doc/uid/20000954-1081265-BAJFDEGD
*/

- (id)makeDocumentWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if ([typeName isEqualToString:@"GeniusDocument"])
	{
		if (outError)
			*outError = nil;
			
		// Try Genius v2.0 format
		id document = [super makeDocumentWithContentsOfURL:absoluteURL ofType:typeName error:outError];
		if (document)
			return document;
			
		if (outError && *outError)
		{
			if ([[*outError domain] isEqual:NSCocoaErrorDomain] && [*outError code] == NSFileReadCorruptFileError)
			{
				// Try Genius v1.x format
				id document = [super makeUntitledDocumentOfType:typeName error:outError];
				if (document == nil)
					return nil;
					
				BOOL result = [document importGeniusV1_5FileAtURL:absoluteURL];
				if (result)
				{
					*outError = nil;
					return document;
				}
			}
		}
	}
			
	return nil;
}


- (IBAction) importFile:(id)sender
{
    NSDocumentController * dc = [NSDocumentController sharedDocumentController];
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    [openPanel setTitle:NSLocalizedString(@"Import Text File", nil)];
    [openPanel setPrompt:NSLocalizedString(@"Import", nil)];

    [dc runModalOpenPanel:openPanel forTypes:[NSArray arrayWithObject:@"txt"]];

    NSString * path = [openPanel filename];
    if (path == nil)
        return;
    
    NSString * text = [NSString stringWithContentsOfFile:path];
    if (text == nil)
        return;
    
    [dc newDocument:self];
    GeniusDocument * document = (GeniusDocument *)[dc currentDocument];
    
    NSArray * items = [GeniusItem itemsFromTabularText:text order:[GeniusItem keyPathOrderForTextRepresentation]];
    if (items)
    {
        [[document itemArrayController] setContent:items];
        //[document reloadInterfaceFromModel];
    }
}

@end
