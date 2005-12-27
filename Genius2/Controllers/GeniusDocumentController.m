#import "GeniusDocumentController.h"

#import "GeniusDocument.h"
#import "GeniusV1FileImporter.h"


@implementation GeniusDocumentController

/*- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError
{
	GeniusDocument * document = [super openUntitledDocumentAndDisplay:displayDocument error:outError];
	if (document)
	{
		[document newItem:nil];
		[[document undoManager] removeAllActions];
	}
	return document;
}*/


/*
	XXX: "How can I support reading one type and (internally) automatically converting to another?"
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

/*- (IBAction) importFile:(id)sender
{
	// TO DO
}*/

@end
