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
#import "GeniusDocumentPrivate.h"   // arrayController, columnBindings for +importFile:
#import "GeniusPair.h"
#import "GeniusAssociation.h"

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
    [archiver encodeObject:[self visibleColumnIdentifiers] forKey:@"visibleColumnIdentifiers"];
    [archiver encodeObject:_columnHeadersDict forKey:@"columnHeadersDict"];
    [archiver encodeObject:_pairs forKey:@"pairs"];
    [archiver encodeObject:_cumulativeStudyTime forKey:@"cumulativeStudyTime"];
    NSNumber * learnReviewNumber = [NSNumber numberWithFloat:[learnReviewSlider floatValue]];
    [archiver encodeObject:learnReviewNumber forKey:@"learnVsReviewNumber"];
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
    NSKeyedUnarchiver * unarchiver = nil;
    NS_DURING
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NS_HANDLER
    NS_ENDHANDLER

    if (unarchiver)
    {
        // Read Genius 1.5 file format (formatVersion==1)
        
        int formatVersion = [unarchiver decodeIntForKey:@"formatVersion"];
        if (formatVersion > 1)
        {
			NSString * title = NSLocalizedString(@"This document was saved by a newer version of Genius.", nil);
			NSString * message = NSLocalizedString(@"Please upgrade Genius to a newer version.", nil);
			NSString * cancelTitle = NSLocalizedString(@"Cancel", nil);
		
            NSAlert * alert = [NSAlert alertWithMessageText:title defaultButton:cancelTitle alternateButton:nil otherButton:nil informativeTextWithFormat:message];
            [alert runModal];
            return NO;
        }

        NSArray * visibleColumnIdentifiers = [unarchiver decodeObjectForKey:@"visibleColumnIdentifiers"];
        if (visibleColumnIdentifiers)
            [_visibleColumnIdentifiersBeforeNibLoaded setArray:visibleColumnIdentifiers];
        NSDictionary * columnHeadersDict = [unarchiver decodeObjectForKey:@"columnHeadersDict"];
        
        if (columnHeadersDict) {
            NSString *title;
            if ((title == [columnHeadersDict valueForKey:@"columnA"]) != nil)
                [_columnHeadersDict setValue:title forKey:@"columnA"];

            if ((title == [columnHeadersDict valueForKey:@"columnB"]) != nil)
                [_columnHeadersDict setValue:title forKey:@"columnB"];
        }


        [_pairs setArray:[unarchiver decodeObjectForKey:@"pairs"]];

        NSDate * cumulativeStudyTime = [unarchiver decodeObjectForKey:@"cumulativeStudyTime"];
        if (cumulativeStudyTime)
        {
            [_cumulativeStudyTime release];
            _cumulativeStudyTime = [cumulativeStudyTime retain];
        }
        
        NSNumber * learnVsReviewNumber = [unarchiver decodeObjectForKey:@"learnVsReviewNumber"];
        if (learnVsReviewNumber)
            _learnVsReviewWeightBeforeNibLoaded = [learnVsReviewNumber floatValue];

        [unarchiver finishDecoding];
        [unarchiver release];
        
        return YES;
    }
    else
    {
        // Import Genius 1.0 file format
        NSDictionary * rootDict = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:kCFPropertyListMutableContainersAndLeaves format:NULL errorDescription:NULL];
        if (rootDict == nil)
            return NO;
        NSDictionary * itemDicts = [rootDict objectForKey:@"items"];
        if (itemDicts == nil)
            return NO;
        NSEnumerator * itemDictEnumerator = [itemDicts objectEnumerator];
        NSDictionary * itemDict;
        while ((itemDict = [itemDictEnumerator nextObject]))
        {
            GeniusPair * pair = [GeniusPair new];
            
            NSString * question = [itemDict objectForKey:@"question"];
            [[pair itemA] setValue:question forKey:@"stringValue"];
            
            NSString * answer = [itemDict objectForKey:@"answer"];
            [[pair itemB] setValue:answer forKey:@"stringValue"];

            NSNumber * scoreNumber = [itemDict objectForKey:@"score"];
            [[pair associationAB] setScoreNumber:scoreNumber];

            NSDate * dueDate = [itemDict objectForKey:@"fireDate"];
            [[pair associationAB] setDueDate:dueDate];
            
            [_pairs addObject:pair];
        }
        
        /*!
            @todo This information is probably best tracked through formatVersion.  A missing
            formatVersion means this GeniusDocument was loaded from an older version, and we should
            therefore display the warning.  Alternatively one could support saving both styles as
            an explicit user option, or even just quietly use the old format for old docs.
         */
        _shouldShowImportWarningOnSave = YES;
        NSLog(@"1.0");

        return YES;
    }
        
    return NO;
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

    // Construct line of headers
    /*NSMutableString * string = [NSMutableString string];
    NSArray * itemKeys = [self itemKeys];
    int i, count = [itemKeys count];
    for (i=0; i<count; i++)
    {
        NSString * itemKey = [itemKeys objectAtIndex:i];
        NSString * header = [_headers objectForKey:itemKey];
        [string appendString:header];
        if (i<count-1)
            [string appendString:@"\t"];
    }*/ //! @todo Consider adding headers to the exported file.
    
    NSString * string = [GeniusPair tabularTextFromPairs:_pairs order:[self columnBindings]];
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
    
    //! @todo Maybe make this work in a 'streaming' fashion so we don't load the whole file at once.
    NSString * text = [NSString stringWithContentsOfFile:path];
    if (text == nil)
        return;
    
    [documentController newDocument:self];
    GeniusDocument * document = (GeniusDocument *)[documentController currentDocument];
    
    NSArray * pairs = [GeniusPair pairsFromTabularText:text order:[document columnBindings]];
    if (pairs)
    {
        [[document pairs] setArray:pairs];
        [document reloadInterfaceFromModel];
    }
}

@end
