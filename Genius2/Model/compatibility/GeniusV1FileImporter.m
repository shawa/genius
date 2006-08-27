//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusV1FileImporter.h"
#import "GeniusV1Pair.h"

#import <CoreData/CoreData.h>

#import "GeniusItem.h"
#import "GeniusAtom.h"
#import "GeniusAssociation.h"
#import "GeniusAssociationDataPoint.h"

#import "GeniusPreferences.h"


@implementation GeniusDocument (GeniusV1FileImporter)

- (void) _updateAssociation:(GeniusAssociation *)association withValuesFromV1Association:(GeniusV1Association *)oldV1Assoc
{
	NSNumber * scoreNumber = [oldV1Assoc scoreNumber];
	if (scoreNumber)
	{
/*		unsigned int score = [scoreNumber unsignedIntValue];

		// Make up a fake set of data points from the single "score" value of Genius 1.x		
		NSMutableArray * dataPoints = [NSMutableArray array];

		int n = score; // MAX(18, score);
		NSDate * firstDate = [[NSDate date] addTimeInterval:-[GeniusAssociationDataPoint timeIntervalForCount:n-1] - 60*60*24*7*8];
		int i;
		for (i=0; i<n; i++)
		{
			// Create new data point
			NSDate * date = [firstDate addTimeInterval:[GeniusAssociationDataPoint timeIntervalForCount:i]];
			GeniusAssociationDataPoint * dataPoint = [[GeniusAssociationDataPoint alloc] initWithDate:date value:(float)YES];
			[dataPoints addObject:dataPoint];
			[dataPoint release];
		}

		NSData * data = [NSArchiver archivedDataWithRootObject:dataPoints];
		[association setValue:data forKey:GeniusAssociationDataPointArrayDataKey];*/
		
		[association setValue:scoreNumber forKey:GeniusAssociationHandicapKey];
	}

	NSDate * dueDate = [oldV1Assoc dueDate];
	if (dueDate)
		[association setValue:dueDate forKey:GeniusAssociationDueDateKey];
}

- (GeniusItem *) _insertGeniusItemWithGeniusV1Pair:(GeniusV1Pair *)v1Pair
{	
	// Create item
	NSManagedObjectContext * context = [self managedObjectContext];
	GeniusItem * newItem = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusItem" inManagedObjectContext:context];
	
	// Update atoms
	NSString * stringA = [[v1Pair itemA] stringValue];
	if (stringA)
	{
		[[newItem valueForKey:GeniusItemAtomAKey] setValue:stringA forKey:GeniusAtomStringKey];
	}
	
	NSString * stringB = [[v1Pair itemB] stringValue];
	if (stringB)
	{
		[[newItem valueForKey:GeniusItemAtomBKey] setValue:stringB forKey:GeniusAtomStringKey];
	}

	// Update associations
	GeniusV1Association * v1AssocAB = [v1Pair associationAB];
	if (v1AssocAB)
	{
		GeniusAssociation * assocAB = [newItem associationAB];
		[self _updateAssociation:assocAB withValuesFromV1Association:v1AssocAB];
	}

	GeniusV1Association * v1AssocBA = [v1Pair associationBA];
	if (v1AssocBA)
	{
		GeniusAssociation * assocBA = [newItem associationBA]; 
		[self _updateAssociation:assocBA withValuesFromV1Association:v1AssocBA];
	}

	// -1 ... 0, 3, 5, 8, 10
	int importance = [v1Pair importance];
	switch (importance)
	{
		case -1:
			[newItem setValue:[NSNumber numberWithBool:NO] forKey:GeniusItemIsEnabledKey];
			break;
		case 0:
			[newItem setValue:[NSNumber numberWithInt:1] forKey:GeniusItemMyRatingKey];
			break;
		case 3:
			[newItem setValue:[NSNumber numberWithInt:2] forKey:GeniusItemMyRatingKey];
			break;
		case 5:
			// do nothing
			break;
		case 8:
			[newItem setValue:[NSNumber numberWithInt:4] forKey:GeniusItemMyRatingKey];
			break;
		case 10:
			[newItem setValue:[NSNumber numberWithInt:5] forKey:GeniusItemMyRatingKey];
			break;
		default:
			break;
	}

	NSString * myGroup = [v1Pair customGroupString];
	if (myGroup)
		[newItem setValue:myGroup forKey:GeniusItemMyGroupKey];
	
	NSString * myType = [v1Pair customTypeString];
	if (myType)
		[newItem setValue:myType forKey:GeniusItemMyTypeKey];
	
	NSString * myNotes = [v1Pair notesString];
	if (myNotes)
		[newItem setValue:myNotes forKey:GeniusItemMyNotesKey];
	
	return newItem; //[newItem autorelease];
}


- (BOOL) importGeniusV1_5FileAtURL:(NSURL *)aURL
{
	NSData * data = [NSData dataWithContentsOfURL:aURL];
	if (data == nil)
		return NO;

    NSKeyedUnarchiver * unarchiver = nil;	
    NS_DURING
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NS_HANDLER
    NS_ENDHANDLER

    if (unarchiver)
    {
		/*
			GeniusV1File -> GeniusNotebook
			GeniusV1Pair -> GeniusRecord
			GeniusV1Association -> GeniusV1Association
			GeniusV1Item -> GeniusAtom
		*/
		[unarchiver setClass:[GeniusV1Pair class] forClassName:@"GeniusPair"];
		[unarchiver setClass:[GeniusV1Association class] forClassName:@"GeniusAssociation"];
		[unarchiver setClass:[GeniusV1Item class] forClassName:@"GeniusItem"];
        
        // Read Genius 1.5 file format (formatVersion==1)
		BOOL succeed = YES;
        int formatVersion = [unarchiver decodeIntForKey:@"formatVersion"];
        if (formatVersion > 1)
		{
			succeed = NO;
			goto catch_error;
		}

		// Document Header
		//NSLog(@"Importing Genius 1.x data file");
/*        NSArray * visibleColumnIdentifiers = [unarchiver decodeObjectForKey:@"visibleColumnIdentifiers"];
        if (visibleColumnIdentifiers)
			; //

        NSDictionary * columnHeadersDict = [unarchiver decodeObjectForKey:@"columnHeadersDict"];
        if (columnHeadersDict)
            ; //*/

/*        NSNumber * learnVsReviewNumber = [unarchiver decodeObjectForKey:@"learnVsReviewNumber"];
        if (learnVsReviewNumber)
		{
			NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
			[ud setObject:learnVsReviewNumber forKey:GeniusPreferencesQuizReviewLearnFloatKey];
		}*/

		// Document Body
		NSArray * pairs = [unarchiver decodeObjectForKey:@"pairs"];	// GeniusV1Pair objects
		if (pairs == nil)
		{
			succeed = NO;
			goto catch_error;
		}

		NSEnumerator * pairEnumerator = [pairs objectEnumerator];
		GeniusV1Pair * v1Pair;
		while ((v1Pair = [pairEnumerator nextObject]))
		{
			//GeniusItem * item = 
			[self _insertGeniusItemWithGeniusV1Pair:v1Pair];
			//[[notebook valueForKey:@"items"] addObject:item];
		}
		
	catch_error:
        [unarchiver finishDecoding];
        [unarchiver release];

        return succeed;
    }

/*    else
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
            GeniusV1Pair * v1Pair = [GeniusV1Pair new];
            
            NSString * question = [itemDict objectForKey:@"question"];
            //
            
            NSString * answer = [itemDict objectForKey:@"answer"];
            //

            NSNumber * scoreNumber = [itemDict objectForKey:@"score"];
            //

            NSDate * dueDate = [itemDict objectForKey:@"fireDate"];
            //

			//
        }

        return YES;
    }*/
        
    return NO;
}

@end
