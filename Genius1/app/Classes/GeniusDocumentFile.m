//
//  GeniusDocumentFile.m
//  Genius
//
//  Created by John R Chang on Fri Nov 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GeniusDocumentFile.h"
#import "GeniusDocumentPrivate.h"   // arrayController, columnBindings for +importFile:
#import "GeniusPair.h"


@implementation GeniusDocument (FileFormat)

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    NSMutableData * data = [NSMutableData data];
    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

    NSEvent * event = [NSApp currentEvent];
    if (event && ([event modifierFlags] & NSAlternateKeyMask))
        [archiver setOutputFormat:kCFPropertyListBinaryFormat_v1_0];
    else
        [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
    
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
        if (columnHeadersDict)
            [_columnHeadersDict setDictionary:columnHeadersDict];

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
        
        _shouldShowImportWarningOnSave = YES;
        NSLog(@"1.0");

        return YES;
    }
        
    return NO;
}


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
    }*/ // FIX
    
    NSString * string = [GeniusPair tabularTextFromPairs:_pairs order:[self columnBindings]];
    [string writeToFile:path atomically:NO];
}


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
    
    NSArray * pairs = [GeniusPair pairsFromTabularText:text order:[document columnBindings]];
    if (pairs)
    {
        [[document pairs] setArray:pairs];
        [document reloadInterfaceFromModel];
    }
}

@end
