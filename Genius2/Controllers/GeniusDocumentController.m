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
	// Handle opening Genius 1.x files
	if ([typeName isEqualToString:@"GeniusV1"])
	{
		id document = [super makeUntitledDocumentOfType:typeName error:outError];
		if (document)
			[document importGeniusV1FileFromURL:absoluteURL];
		
		return document;
	}

	return [super makeDocumentWithContentsOfURL:absoluteURL ofType:typeName error:outError];
}


/*- (IBAction) importFile:(id)sender
{
	// TO DO
}*/

@end
