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

#import "GeniusDocumentFile.h"
#import "GeniusPair.h"
#import "GeniusAssociation.h"
#import "GeniusDocument.h"
#import "GSTableView.h"

//! Methods related to reading and writing genius files.
/*!
    @category GeniusDocument(FileFormat)
    Genius supports importing and exporting delimited files as well as saving and loading
    in its own native format.
*/
@implementation GeniusDocument(FileFormat)

//! Packs up GeniusDocument as NSData suitable for writing to disk.
/*!
    Includes a formatVersion value of 1 to distinguish this file format from future and past
    versions.   Only saves files in version 1.5 format.  Making them incompatible with previous
    versions of Genius.
*/
- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    NSMutableData * data = [NSMutableData data];
    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

    NSEvent * event = [NSApp currentEvent];
    if (event && ([event modifierFlags] & NSAlternateKeyMask))
        [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
    else
		[archiver setOutputFormat:kCFPropertyListBinaryFormat_v1_0];
    
    [archiver encodeInt:1 forKey:@"formatVersion"];
    [archiver encodeObject:[tableView visibleColumnIdentifiers] forKey:@"visibleColumnIdentifiers"];
    [archiver encodeObject:_columnHeadersDict forKey:@"columnHeadersDict"];
    [archiver encodeObject:_pairs forKey:@"pairs"];
    [archiver encodeObject:_cumulativeStudyTime forKey:@"cumulativeStudyTime"];
    [archiver encodeObject:probabilityCenter forKey:@"learnVsReviewNumber"];
    [archiver finishEncoding];
    [archiver release];

    return data;
}

//! Reads in a GeniusDocument from the provided @a data.
/*!
    This method supports reading the version 1.5 format as well as version 1.0.  The 1.5
    version is dependent on the NSKeyedUnarchiver while the 1.0 version was stored in
    plist format.
*/
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    BOOL result = NO;
    
    [[self undoManager]  disableUndoRegistration];
    
    NSKeyedUnarchiver * unarchiver = nil;
    NS_DURING
        // if this fails then we are opening a 1.0 file 
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NS_HANDLER
    NS_ENDHANDLER

    // 1.5 format or higher
    if (unarchiver)
    {
        // Read Genius 1.5 file format (formatVersion==1)
        NSLog(@"1.5");
        
        int formatVersion = [unarchiver decodeIntForKey:@"formatVersion"];
        //  greater than one for genius 2.0
        if (formatVersion > 1)
        {
			NSString * title = NSLocalizedString(@"This document was saved by a newer version of Genius.", nil);
			NSString * message = NSLocalizedString(@"Please upgrade Genius to a newer version.", nil);
			NSString * cancelTitle = NSLocalizedString(@"Cancel", nil);
		
            NSAlert * alert = [NSAlert alertWithMessageText:title defaultButton:cancelTitle alternateButton:nil otherButton:nil informativeTextWithFormat:message];
            [alert runModal];
            result = NO;
        }
        // handle 1.5 format
        else
        {
            NSArray * visibleColumnIdentifiers = [unarchiver decodeObjectForKey:@"visibleColumnIdentifiers"];
            if (visibleColumnIdentifiers)
                [_visibleColumnIdentifiers setArray:visibleColumnIdentifiers];

            NSDictionary * dict = [unarchiver decodeObjectForKey:@"columnHeadersDict"];
            if (dict) {
                NSString *title;
                if ((title = [dict valueForKey:@"columnA"]) != nil)
                    [_columnHeadersDict setObject:title forKey:@"columnA"];

                if ((title = [dict valueForKey:@"columnB"]) != nil)
                    [_columnHeadersDict setObject:title forKey:@"columnB"];
            }

            [self setPairs:[unarchiver decodeObjectForKey:@"pairs"]];

            NSDate * cumulativeStudyTime = [unarchiver decodeObjectForKey:@"cumulativeStudyTime"];
            if (cumulativeStudyTime)
            {
                [_cumulativeStudyTime release];
                _cumulativeStudyTime = [cumulativeStudyTime retain];
            }
            
            NSNumber * learnVsReviewNumber = [unarchiver decodeObjectForKey:@"learnVsReviewNumber"];
            if (learnVsReviewNumber) {
                [self takeValue:learnVsReviewNumber forKey:@"probabilityCenter"];
            }

            [unarchiver finishDecoding];
            [unarchiver release];

            result = YES;
        }
    }
    // 1.0 format
    else
    {
        // Import Genius 1.0 file format
        NSLog(@"1.0");
        
        NSDictionary * rootDict = [NSPropertyListSerialization propertyListFromData:data
                                                                   mutabilityOption:kCFPropertyListMutableContainersAndLeaves
                                                                             format:NULL
                                                                   errorDescription:NULL];
        if ((rootDict != nil) && ([rootDict objectForKey:@"items"] != nil))
        {
            NSDictionary * itemDicts = [rootDict objectForKey:@"items"];
            NSEnumerator * itemDictEnumerator = [itemDicts objectEnumerator];
            NSDictionary * itemDict;
            NSMutableArray * array = [NSMutableArray array];
            while ((itemDict = [itemDictEnumerator nextObject]))
            {
                GeniusPair * pair = [[GeniusPair alloc] init];
                
                NSString * question = [itemDict objectForKey:@"question"];
                [[pair itemA] setValue:question forKey:@"stringValue"];
                
                NSString * answer = [itemDict objectForKey:@"answer"];
                [[pair itemB] setValue:answer forKey:@"stringValue"];

                NSNumber * scoreNumber = [itemDict objectForKey:@"score"];
                [[pair associationAB] setScoreNumber:scoreNumber];

                NSDate * dueDate = [itemDict objectForKey:@"fireDate"];
                [[pair associationAB] setDueDate:dueDate];
                
                [array addObject:pair];
            }
            [self setPairs:array];
            /*!
                @todo This information is probably best tracked through formatVersion.  A missing
                formatVersion means this GeniusDocument was loaded from an older version, and we should
                therefore display the warning.  Alternatively one could support saving both styles as
                an explicit user option, or even just quietly use the old format for old docs.
             */
            _shouldShowImportWarningOnSave = YES;
            [self updateChangeCount:NSChangeDone];  // due to the 1.0 to 1.5 version change
            result = YES;
        }
        else
        {
            result = NO;
        }
    }
    [[self undoManager]  enableUndoRegistration];
    return result;
}

//! Saves GeniusDocument
/*! 
The implementation checks to see if saving the file would make it impossible to open the file again with older versions of Genius.
Assuming this is okay, it simply passes the call to super.
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

    //! @todo Consider adding headers to the exported file.    
    NSString * string = [GeniusPair tabularTextFromPairs:_pairs order:[GeniusDocument columnBindings]];
    [string writeToFile:path atomically:NO];
}

//! Support for loading delimited files.
/*!
    By default looks for files with .txt ending.  Relies on GeniusPair for convering the delimited
    text into an array of GeniusPair instances.
*/
+ (IBAction)importFile:(id)sender
{
    NSDocumentController * documentController = [NSDocumentController sharedDocumentController];
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    [openPanel setTitle:NSLocalizedString(@"Import Text File", nil)];
    [openPanel setPrompt:NSLocalizedString(@"Import", nil)];

    [documentController runModalOpenPanel:openPanel forTypes:[NSArray arrayWithObject:@"txt"]];

    NSString * path = [openPanel filename];
    if (path == nil)
        return;
    
    NSString * text = [NSString stringWithContentsOfFile:path];
    if (text == nil)
        return;
    
    [documentController newDocument:self];
    GeniusDocument * document = (GeniusDocument *)[documentController currentDocument];
    
    NSMutableArray * pairs = [GeniusPair pairsFromTabularText:text order:[GeniusDocument columnBindings]];
    if (pairs)
    {
        [document setPairs:pairs];
        [document reloadInterfaceFromModel];
    }
}

@end
