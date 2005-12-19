// 
//  GeniusItem.m
//  Genius2
//
//  Created by John R Chang on 2005-09-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusItem.h"

// XXX
#import "GeniusDocument.h"	// -documentInfo
#import "GeniusDocumentInfo.h"	// -quizDirectionMode


static NSString * GeniusItemAssociationsKey = @"associations";
NSString * GeniusItemAtomAKey = @"atomA";
NSString * GeniusItemAtomBKey = @"atomB";

NSString * GeniusItemIsEnabledKey = @"isEnabled";
NSString * GeniusItemMyGroupKey = @"myGroup";
NSString * GeniusItemMyTypeKey = @"myType";
NSString * GeniusItemMyNotesKey = @"myNotes";
NSString * GeniusItemMyRatingKey = @"myRating";
NSString * GeniusItemLastTestedDateKey = @"lastTestedDate";
NSString * GeniusItemLastModifiedDateKey = @"lastModifiedDate";


@interface GeniusItem (Private)
- (void) _addSelfAsObserverToChildAtoms;
- (void) _removeSelfAsObserverToChildAtoms;

- (void) _recalculateGrade;

@end


@implementation GeniusItem 

- (NSArray *) allAtoms
{
	return [NSArray arrayWithObjects:[self valueForKey:GeniusItemAtomAKey], [self valueForKey:GeniusItemAtomBKey], nil];
}


#pragma mark <NSCopying>
/*
	/Developer/ADC Reference Library/documentation/Cocoa/Conceptual/CoreData/Articles/cdUsingMOs.html
	"In many cases the best strategy may be in copy to create a dictionary (property list) representation
	of a managed object, then on paste create a new managed object and populate it using the dictionary."
*/

+ (NSArray *)copyKeys {
    static NSArray *copyKeys = nil;
    if (copyKeys == nil) {
        copyKeys = [[NSArray alloc] initWithObjects:
			GeniusItemAtomAKey, GeniusItemAtomBKey,
            @"associations",
			GeniusItemIsEnabledKey, GeniusItemLastModifiedDateKey,
			GeniusItemMyGroupKey, GeniusItemMyTypeKey, GeniusItemMyNotesKey, GeniusItemMyRatingKey, nil];
    }
    return copyKeys;
}

- (NSDictionary *)dictionaryRepresentation
{
    return [self dictionaryWithValuesForKeys:[[self class] copyKeys]];
}


- (id)copyWithZone:(NSZone *)zone
{
	NSManagedObjectContext * context = [self managedObjectContext];

	// Create new item
	GeniusItem * newObject = [[[self class] allocWithZone:zone] initWithEntity:[self entity] insertIntoManagedObjectContext:context];

	// Unsubscribe
	[newObject _removeSelfAsObserverToChildAtoms];

	// Fill in data
	[newObject setValuesForKeysWithDictionary:[self dictionaryRepresentation]];
	
	// Use old atoms
	GeniusAtom * newAtomA = [[[self valueForKey:GeniusItemAtomAKey] copy] autorelease];
	[newObject setValue:newAtomA forKey:GeniusItemAtomAKey];

	GeniusAtom * newAtomB = [[[self valueForKey:GeniusItemAtomBKey] copy] autorelease];
	[newObject setValue:newAtomB forKey:GeniusItemAtomBKey];

	// Subscribe
	[newObject _addSelfAsObserverToChildAtoms];

	[newObject touchLastModifiedDate];

    return newObject;
}


#pragma mark -

- (void) _addSelfAsObserverToChildAtoms
{
	NSArray * allAtoms = [self allAtoms];
	NSEnumerator * atomEnumerator = [allAtoms objectEnumerator];
	NSManagedObject * atom;
	while ((atom = [atomEnumerator nextObject]))
	{
		[atom addObserver:self forKeyPath:GeniusAtomDirtyKey options:0 context:NULL];
	}
}

- (void) _removeSelfAsObserverToChildAtoms
{
	NSArray * allAtoms = [self allAtoms];
	NSEnumerator * atomEnumerator = [allAtoms objectEnumerator];
	NSManagedObject * atom;
	while ((atom = [atomEnumerator nextObject]))
		[atom removeObserver:self forKeyPath:GeniusAtomDirtyKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:GeniusAtomDirtyKey])
	{
		[self touchLastModifiedDate];
	}
}


#pragma mark -

- (void) commonAwake
{
	[self _addSelfAsObserverToChildAtoms];

//	[self flushCache];
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];

	NSManagedObjectContext * context = [self managedObjectContext];

	// Create child atoms
	GeniusAtom * atomA = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	
	GeniusAtom * atomB = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	

	// Link new atoms to self
	[self setPrimitiveValue:atomA forKey:GeniusItemAtomAKey];
	[self setPrimitiveValue:atomB forKey:GeniusItemAtomBKey];

	// Create child associations
	NSManagedObject * assocAB = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[assocAB setPrimitiveValue:atomA forKey:GeniusAssociationSourceAtomKey];
	[assocAB setPrimitiveValue:atomB forKey:GeniusAssociationTargetAtomKey];

	NSManagedObject * assocBA = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[assocBA setPrimitiveValue:atomB forKey:GeniusAssociationSourceAtomKey];
	[assocBA setPrimitiveValue:atomA forKey:GeniusAssociationTargetAtomKey];

	// Link new associations to self
	NSMutableSet * associationSet = [self mutableSetValueForKey:GeniusItemAssociationsKey];	// persistent
	[associationSet addObject:assocAB];
	[associationSet addObject:assocBA];

	// Initialize lastModifiedDate
	[self setPrimitiveValue:[NSDate date] forKey:GeniusItemLastModifiedDateKey];

	[self commonAwake];
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];

	[self flushCache];

	[self commonAwake];
}


#pragma mark -

- (GeniusAssociation *) _associationForSourceAtom:(GeniusAtom *)sourceAtom targetAtom:(GeniusAtom *)targetAtom
{
	// is NSFetchRequest faster?

	NSSet * associationSet = [self valueForKey:GeniusItemAssociationsKey];
	NSEnumerator * associationSetEnumerator = [associationSet objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationSetEnumerator nextObject]))
	{
		GeniusAtom * aSourceAtom = [association valueForKey:GeniusAssociationSourceAtomKey];
		GeniusAtom * aTargetAtom = [association valueForKey:GeniusAssociationTargetAtomKey];
		if ([aSourceAtom isEqual:sourceAtom] && [aTargetAtom isEqual:targetAtom])
			return association;
	}
	return nil;
}

- (GeniusAssociation *) associationAB
{
	GeniusAtom * atomA = [self valueForKey:GeniusItemAtomAKey];
	GeniusAtom * atomB = [self valueForKey:GeniusItemAtomBKey];
	return [self _associationForSourceAtom:atomA targetAtom:atomB];
}

- (GeniusAssociation *) associationBA
{
	GeniusAtom * atomA = [self valueForKey:GeniusItemAtomAKey];
	GeniusAtom * atomB = [self valueForKey:GeniusItemAtomBKey];
	return [self _associationForSourceAtom:atomB targetAtom:atomA];
}


- (NSArray *) _activeAssociations
{	
	// XXX: yuck
	GeniusDocument * document = [[NSDocumentController sharedDocumentController] currentDocument];
	int quizDirectionMode = [[document documentInfo] quizDirectionMode];
	
	if (quizDirectionMode == 1)
		return [NSArray arrayWithObject:[self associationAB]];
	else
	{
		return [NSArray arrayWithObjects:[self associationAB], [self associationBA], NULL];
	}
}


- (void) touchLastModifiedDate
{
	[self setPrimitiveValue:[NSDate date] forKey:GeniusItemLastModifiedDateKey];
}

- (void) touchLastTestedDate
{
	NSDate * lastTestedDate = nil;
	
	NSArray * activeAssociations = [self _activeAssociations];
	NSEnumerator * associationEnumerator = [activeAssociations objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
	{
		NSDate * assocDate = [association valueForKey:GeniusAssociationLastDataPointDateKey];
		lastTestedDate = (lastTestedDate ? [lastTestedDate laterDate:assocDate] : assocDate);
	}

	[self setPrimitiveValue:lastTestedDate forKey:GeniusItemLastTestedDateKey];

		[self _recalculateGrade];
		[self flushCache];
}


- (void) _recalculateGrade
{
	float sum = 0.0;
	
	NSArray * activeAssociations = [self _activeAssociations];	
	NSEnumerator * associationEnumerator = [activeAssociations objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
	{
		float predictedScore = [[association valueForKey:GeniusAssociationPredictedScoreKey] floatValue];
		if (predictedScore != -1.0)
			sum += predictedScore;
	}
	
	float grade;
	if (sum == 0.0)
		grade = -1.0;
	else
		grade = sum / [activeAssociations count];
		
	[self setPrimitiveValue:[NSNumber numberWithFloat:grade] forKey:@"grade"];
}

- (NSString *) displayGrade
{
	if (_displayGrade == nil)
	{
		float grade = [[self valueForKey:@"grade"] floatValue];
		if (grade == -1.0)
			_displayGrade = @"";
		else if (grade > 0.9)
			_displayGrade = @"A";
		else if (grade > 0.8)
			_displayGrade = @"B";
		else if (grade > 0.7)
			_displayGrade = @"C";
		else if (grade > 0.6)
			_displayGrade = @"D";
		else
			_displayGrade = @"F";
//			[[NSString alloc] initWithFormat:@"%.0f", grade * 100.0];
	}
	return (_displayGrade == @"" ? nil : _displayGrade);
}


- (void) swapAtoms
{
	GeniusAtom * atomA = [self valueForKey:GeniusItemAtomAKey];
	GeniusAtom * atomB = [self valueForKey:GeniusItemAtomBKey];

	[self setValue:atomB forKey:GeniusItemAtomAKey];
	[self setValue:atomA forKey:GeniusItemAtomBKey];

	[self touchLastModifiedDate];
}

- (BOOL) usesDefaultTextAttributes
{
	NSArray * allAtoms = [self allAtoms];
	NSEnumerator * atomEnumerator = [allAtoms objectEnumerator];
	GeniusAtom * atom;
	while ((atom = [atomEnumerator nextObject]))
		if ([atom usesDefaultTextAttributes] == NO)
			return NO;
	return YES;
}

- (void) clearTextAttributes
{
	NSArray * allAtoms = [self allAtoms];
	[allAtoms makeObjectsPerformSelector:@selector(clearTextAttributes)];
}

- (void) resetAssociations
{
	NSSet * associationSet = [self valueForKey:GeniusItemAssociationsKey];
	[associationSet makeObjectsPerformSelector:@selector(reset)];
}


- (void) flushCache
{
	//NSLog(@"flushCache");
	
	//[_displayGrade release];
	_displayGrade = nil;
}

@end


@implementation GeniusItem (TextImportExport)

- (NSString *) tabularText
{
	NSArray * keyPaths = [NSArray arrayWithObjects:@"atomA.string", @"atomB.string", nil];

    NSMutableString * outputString = [NSMutableString string];
    int i, count = [keyPaths count];
    for (i=0; i<count; i++)
    {
        NSString * keyPath = [keyPaths objectAtIndex:i];
        id value = [self valueForKeyPath:keyPath];
        if (value)
        {
            // Escape any embedded special characters
            NSMutableString * encodedString = [NSMutableString stringWithString:[value description]];
            [encodedString replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
            [encodedString replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
            [encodedString replaceOccurrencesOfString:@"\r" withString:@"\\n" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];

            [outputString appendString:encodedString];
        }
        if (i<count-1)
            [outputString appendString:@"\t"];
    }

    return outputString;	
}

+ (NSString *) tabularTextFromItems:(NSArray *)items
{
    NSMutableString * outputString = [NSMutableString string];    
    NSEnumerator * itemEnumerator = [items objectEnumerator];
    GeniusItem * item;
    while ((item = [itemEnumerator nextObject]))
        [outputString appendFormat:@"%@\n", [item tabularText]];
    return outputString;
}

@end
