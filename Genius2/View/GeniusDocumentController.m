#import "GeniusDocumentController.h"

#import "GeniusDocument.h"
#import "GeniusV1FileImporter.h"


@implementation GeniusDocumentController

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError
{
	GeniusDocument * document = [super openUntitledDocumentAndDisplay:displayDocument error:outError];
	if (document)
	{
		[[document undoManager] disableUndoRegistration];
		[document newItem:nil];
		// This needs to be deferred, otherwise weird things happen
		[[document undoManager] performSelector:@selector(enableUndoRegistration) withObject:nil afterDelay:0.0];
	}
	return document;
}


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

@end
