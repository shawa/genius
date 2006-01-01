// 
//  GeniusItem.m
//  Genius2
//
//  Created by John R Chang on 2005-09-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusItem.h"

#import "GeniusAtom.h"
#import "GeniusAssociation.h"	// GeniusAssociationSourceAtomKey, ...

#import "GeniusDocument.h"		-documentInfo
#import "GeniusDocumentInfo.h"	-quizDirectionMode


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


@interface GeniusItem (Internal)
- (void) touchLastModifiedDate;
@end


@implementation GeniusItem 

- (void)awakeFromInsert
{
	[super awakeFromInsert];

	// Create child atoms
	NSManagedObjectContext * context = [self managedObjectContext];

	GeniusAtom * atomA = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	
	GeniusAtom * atomB = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	
	[self setValue:atomA forKey:GeniusItemAtomAKey];
	[self setValue:atomB forKey:GeniusItemAtomBKey];
	[atomA setDelegate:self];
	[atomB setDelegate:self];

	[self touchLastModifiedDate];
}


- (void)didTurnIntoFault
{
	[_associationAB release];
	_associationAB = nil;
	[_associationBA release];
	_associationBA = nil;
	
	[super didTurnIntoFault];
}


#pragma mark Atoms / Last modified date

- (NSArray *) _atoms
{
	return [NSArray arrayWithObjects:
		[self valueForKey:GeniusItemAtomAKey],
		[self valueForKey:GeniusItemAtomBKey],
		nil];
}

- (void) touchLastModifiedDate
{
	[self setValue:[NSDate date] forKey:GeniusItemLastModifiedDateKey];
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
			//GeniusItemAtomsKey, GeniusItemAssociationsKey,
			GeniusItemAtomAKey, GeniusItemAtomBKey,
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

	// Fill in data
	[newObject setValuesForKeysWithDictionary:[self dictionaryRepresentation]];
	
	// Use old atoms
	GeniusAtom * newAtomA = [[[self valueForKey:GeniusItemAtomAKey] copy] autorelease];
	[newObject setValue:newAtomA forKey:GeniusItemAtomAKey];
	[newAtomA setDelegate:newObject];

	GeniusAtom * newAtomB = [[[self valueForKey:GeniusItemAtomBKey] copy] autorelease];
	[newObject setValue:newAtomB forKey:GeniusItemAtomBKey];
	[newAtomB setDelegate:newObject];

	[newObject touchLastModifiedDate];

    return newObject;
}


#pragma mark -

- (BOOL) usesDefaultTextAttributes
{
	NSArray * atoms = [self _atoms]; //valueForKey:GeniusItemAtomsKey];
	NSEnumerator * atomEnumerator = [atoms objectEnumerator];
	GeniusAtom * atom;
	while ((atom = [atomEnumerator nextObject]))
		if ([atom usesDefaultTextAttributes] == NO)
			return NO;
	return YES;
}

- (void) clearTextAttributes
{
	NSArray * atoms = [self _atoms]; //valueForKey:GeniusItemAtomsKey];
	[atoms makeObjectsPerformSelector:@selector(clearTextAttributes)];
}


#pragma mark -

- (void) swapAtoms
{
	GeniusAtom * atomA = [self valueForKey:GeniusItemAtomAKey];
	GeniusAtom * atomB = [self valueForKey:GeniusItemAtomBKey];

	[self setValue:atomB forKey:GeniusItemAtomAKey];
	[self setValue:atomA forKey:GeniusItemAtomBKey];

	[self touchLastModifiedDate];
	
	[_associationAB release];
	_associationAB = nil;
	[_associationBA release];
	_associationBA = nil;
}

@end


@implementation GeniusItem (ScoreKeeping)

- (GeniusAssociation *) _associationWithSourceAtom:(GeniusAtom *)sourceAtom targetAtom:(GeniusAtom *)targetAtom
{
	NSMutableSet * associationSet = [self valueForKey:GeniusItemAssociationsKey];
	NSEnumerator * associationEnumerator = [associationSet objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
	{
		GeniusAtom * aSourceAtom = [association valueForKey:GeniusAssociationSourceAtomKey];
		GeniusAtom * aTargetAtom = [association valueForKey:GeniusAssociationTargetAtomKey];
		if ([aSourceAtom isEqual:sourceAtom] && [aTargetAtom isEqual:targetAtom])
			return association;
	}
	
	NSManagedObjectContext * context = [self managedObjectContext];
	association = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[association setValue:self forKey:GeniusAssociationParentItemKey];
	[association setValue:sourceAtom forKey:GeniusAssociationSourceAtomKey];
	[association setValue:targetAtom forKey:GeniusAssociationTargetAtomKey];
	[associationSet addObject:association];
	return association;
}

- (GeniusAssociation *) associationAB
{
	if (_associationAB == nil)
	{
		GeniusAtom * atomA = [self valueForKey:GeniusItemAtomAKey];
		GeniusAtom * atomB = [self valueForKey:GeniusItemAtomBKey];
		_associationAB = [[self _associationWithSourceAtom:atomA targetAtom:atomB] retain];
	}
	return _associationAB;
}

- (GeniusAssociation *) associationBA
{
	if (_associationBA == nil)
	{
		GeniusAtom * atomA = [self valueForKey:GeniusItemAtomAKey];
		GeniusAtom * atomB = [self valueForKey:GeniusItemAtomBKey];
		_associationBA = [[self _associationWithSourceAtom:atomB targetAtom:atomA] retain];
	}
	return _associationBA;
}

- (void) resetAssociations
{
	NSMutableSet * associationSet = [self valueForKey:GeniusItemAssociationsKey];
	[associationSet makeObjectsPerformSelector:@selector(reset)];
}


#pragma mark -

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

- (float) grade
{
	float sum = 0.0;
	NSArray * activeAssociations = [self _activeAssociations];	
	NSEnumerator * associationEnumerator = [activeAssociations objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
	{
		float predictedScore = [association predictedScore]; // valueForKey:GeniusAssociationPredictedScoreKey] floatValue];
		if (predictedScore != -1.0)
			sum += predictedScore;
	}
	
	float grade;
	if (sum == 0.0)
		grade = -1.0;
	else
		grade = sum / [activeAssociations count];

	return grade;
}

- (NSString *) displayGrade
{
	float grade = [self grade];

	NSString * displayGrade = nil;
	if (grade == -1.0)
		displayGrade = @"--";
	else if (grade > 0.9)
		displayGrade = @"A";
	else if (grade > 0.8)
		displayGrade = @"B";
	else if (grade > 0.7)
		displayGrade = @"C";
	else if (grade > 0.6)
		displayGrade = @"D";
	else
		displayGrade = @"F";
		
	return displayGrade;
}

- (NSImage *) gradeIcon
{
	float grade = [self grade];

	NSImage * image = nil;
	if (grade == -1.0)
		image = [NSImage imageNamed:@"status-red"];
	else if (grade < 0.9)
		image = [NSImage imageNamed:@"status-yellow"];
	else
		image = [NSImage imageNamed:@"status-green"];
	return image;
}

@end


@implementation GeniusItem (GeniusAtomDelegate)

- (void) atomHasChanged:(GeniusAtom *)atom
{
	[self touchLastModifiedDate];
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
