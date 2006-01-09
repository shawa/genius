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


NSString * GeniusItemIsEnabledKey = @"isEnabled";
NSString * GeniusItemAtomAKey = @"atomA";
NSString * GeniusItemAtomBKey = @"atomB";
NSString * GeniusItemMyGroupKey = @"myGroup";
NSString * GeniusItemMyTypeKey = @"myType";
NSString * GeniusItemMyRatingKey = @"myRating";
NSString * GeniusItemDisplayGradeKey = @"displayGrade";
NSString * GeniusItemLastTestedDateKey = @"lastTestedDate";
NSString * GeniusItemLastModifiedDateKey = @"lastModifiedDate";

NSString * GeniusItemMyNotesKey = @"myNotes";

static NSString * GeniusItemAssociationsKey = @"associations";


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
	GeniusAtom * atomA = [[self valueForKey:GeniusItemAtomAKey] retain];
	GeniusAtom * atomB = [[self valueForKey:GeniusItemAtomBKey] retain];
	[self setValue:atomB forKey:GeniusItemAtomAKey];
	[self setValue:atomA forKey:GeniusItemAtomBKey];
	[atomA release];
	[atomB release];

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

- (BOOL) isAssociationsReset
{
	NSMutableSet * associationSet = [self valueForKey:GeniusItemAssociationsKey];
	NSEnumerator * associationEnumerator = [associationSet objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
		if ([association isReset] == NO)
			return NO;
	return YES;
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
		float predictedValue = [association predictedValue]; // valueForKey:GeniusAssociationPredictedScoreKey] floatValue];
		if (predictedValue != -1.0)
			sum += predictedValue;
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

+ (NSArray *) keyPathOrderForTextRepresentation
{
	return [NSArray arrayWithObjects:@"atomA.string", @"atomB.string",
		GeniusItemMyGroupKey, GeniusItemMyTypeKey, GeniusItemMyRatingKey,
		@"associationAB.predictedValue", @"associationBA.predictedValue",
		GeniusItemLastTestedDateKey, GeniusItemLastModifiedDateKey, GeniusItemMyNotesKey, nil];
}


- (NSString *) tabularText
{
	NSArray * keyPaths = [GeniusItem keyPathOrderForTextRepresentation];

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


+ (NSArray *) _linesFromString:(NSString *)string
{
    NSMutableArray * lines = [NSMutableArray array];
    unsigned int startIndex, lineEndIndex, contentsEndIndex = 0;
    unsigned int length = [string length];
    NSRange range = NSMakeRange(0, 0);
    while (contentsEndIndex < length)
    {
        [string getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:range];
        unsigned int rangeLength = contentsEndIndex - startIndex;
        if (rangeLength > 0)    // don't include empty lines
        {
            NSString * line = [string substringWithRange:NSMakeRange(startIndex, rangeLength)];
            [lines addObject:line];
        }
        range.location = lineEndIndex;
    }
    return lines;
}

+ (NSArray *) itemsFromTabularText:(NSString *)string order:(NSArray *)keyPaths
{
    //Can't use lines = [string componentsSeparatedByString:@"\n"];
    // because it doesn't handle carriage returns.
    NSArray * lines = [self _linesFromString:string];

    NSMutableArray * items = [NSMutableArray array];
    NSEnumerator * lineEnumerator = [lines objectEnumerator];
    NSString * line;
    while ((line = [lineEnumerator nextObject]))
    {
        GeniusItem * item = [[GeniusItem alloc] initWithTabularText:line order:keyPaths];
        [items addObject:item];
        [item release];
    }
    return (NSArray *)items;	
}

- (id) initWithTabularText:(NSString *)line order:(NSArray *)keyPaths
{
    NSDocumentController * dc = [NSDocumentController sharedDocumentController];
    GeniusDocument * document = (GeniusDocument *)[dc currentDocument];
	
	NSManagedObjectContext * context = [document managedObjectContext];
	self = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusItem" inManagedObjectContext:context];

    NSArray * fields = [line componentsSeparatedByString:@"\t"];
    int i, count=MIN([fields count], [keyPaths count]);
    for (i=0; i<count; i++)
    {
        NSString * field = [fields objectAtIndex:i];
        NSString * keyPath = [keyPaths objectAtIndex:i];

        // Unescape any embedded special characters
        NSMutableString * decodedString = [NSMutableString stringWithString:field];
        [decodedString replaceOccurrencesOfString:@"\\t" withString:@"\t" options:NSLiteralSearch range:NSMakeRange(0, [decodedString length])];
        [decodedString replaceOccurrencesOfString:@"\\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [decodedString length])];

		if ([keyPath isEqual:GeniusItemMyRatingKey])
			[self setValue:[NSNumber numberWithInt:[decodedString intValue]] forKeyPath:keyPath];
		else if ([keyPath isEqual:@"associationAB.predictedValue"] || [keyPath isEqual:@"associationBA.predictedValue"])
			; // XXX: do nothing
		else if ([keyPath isEqual:GeniusItemLastTestedDateKey] || [keyPath isEqual:GeniusItemLastModifiedDateKey])
			[self setValue:[NSDate dateWithString:decodedString] forKeyPath:keyPath];
		else
			[self setValue:decodedString forKeyPath:keyPath];
    }
    
    return self;	
}

@end
