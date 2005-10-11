// 
//  GeniusItem.m
//  Genius2
//
//  Created by John R Chang on 2005-09-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusItem.h"

#import "GeniusAtom.h"
#import "GeniusAssociation.h"

// XXX
#import "GeniusDocument.h"	// -documentInfo
#import "GeniusDocumentInfo.h"	// -quizDirectionMode


NSString * GeniusItemAssociationsKey = @"associations";
NSString * GeniusItemAssociationABKey = @"association_atomA_atomB";
NSString * GeniusItemAssociationBAKey = @"association_atomB_atomA";

static NSString * GeniusItemAtomsKey = @"atoms";	// ???
NSString * GeniusItemAtomAKey = @"atomA";
NSString * GeniusItemAtomBKey = @"atomB";

static NSString * GeniusAssociationAtomAKeyValue = @"atomA";
static NSString * GeniusAssociationAtomBKeyValue = @"atomB";

NSString * GeniusItemIsEnabledKey = @"isEnabled";
NSString * GeniusItemMyGroupKey = @"myGroup";
NSString * GeniusItemMyTypeKey = @"myType";
NSString * GeniusItemMyNotesKey = @"myNotes";
NSString * GeniusItemMyRatingKey = @"myRating";
NSString * GeniusItemLastTestedDateKey = @"lastTestedDate";
NSString * GeniusItemLastModifiedDateKey = @"lastModifiedDate";


@interface GeniusItem (Private)

- (void) _recalculateGrade;

@end


@implementation GeniusItem 

+ (NSArray *) allAtomKeys
{
	return [NSArray arrayWithObjects:GeniusItemAtomAKey, GeniusItemAtomBKey, nil];
}


- (void) commonAwake
{
	[self flushCache];
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];

	NSManagedObjectContext * context = [self managedObjectContext];

	// Create atoms
	NSManagedObject * atomA = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	
	[atomA setPrimitiveValue:@"atomA" forKey:@"key"];

	NSManagedObject * atomB = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	
	[atomB setPrimitiveValue:@"atomB" forKey:@"key"];

/*	NSManagedObject * atomC = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	
	[atomC setValue:@"atomC" forKey:@"key"];
	[self setPrimitiveValue:atomC forKey:@"atomC"];
*/
	[self setPrimitiveValue:atomA forKey:GeniusItemAtomAKey];	// transient
	[self setPrimitiveValue:atomB forKey:GeniusItemAtomBKey];	// transient

	NSMutableSet * atomSet = [self mutableSetValueForKey:GeniusItemAtomsKey];	// persistent
	[atomSet addObject:atomA];
	[atomSet addObject:atomB];

	// Create associations
	NSManagedObject * assocAB = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[assocAB setPrimitiveValue:GeniusAssociationAtomAKeyValue forKey:GeniusAssociationSourceAtomKeyKey];
	[assocAB setPrimitiveValue:GeniusAssociationAtomBKeyValue forKey:GeniusAssociationTargetAtomKeyKey];

	NSManagedObject * assocBA = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[assocBA setPrimitiveValue:GeniusAssociationAtomBKeyValue forKey:GeniusAssociationSourceAtomKeyKey];
	[assocBA setPrimitiveValue:GeniusAssociationAtomAKeyValue forKey:GeniusAssociationTargetAtomKeyKey];

	[self setPrimitiveValue:assocAB forKey:GeniusItemAssociationABKey];	// transient
	[self setPrimitiveValue:assocBA forKey:GeniusItemAssociationBAKey];	// transient

	NSMutableSet * associationSet = [self mutableSetValueForKey:GeniusItemAssociationsKey];	// persistent
	[associationSet addObject:assocAB];
	[associationSet addObject:assocBA];

	// Initialize lastModifiedDate
	[self setPrimitiveValue:[NSDate date] forKey:GeniusItemLastModifiedDateKey];
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];

	[self flushCache];

	// Set up transient atoms
	NSSet * atomSet = [self valueForKey:GeniusItemAtomsKey];
	NSEnumerator * atomSetEnumerator = [atomSet objectEnumerator];
	NSManagedObject * atom;
	while ((atom = [atomSetEnumerator nextObject]))
	{
		NSString * key = [atom valueForKey:@"key"];
		if (key)
		{
			[self setPrimitiveValue:atom forKey:key];
		}
	}

	// Set up transient associations
	NSSet * associationSet = [self valueForKey:GeniusItemAssociationsKey];
	NSEnumerator * associationSetEnumerator = [associationSet objectEnumerator];
	NSManagedObject * association;
	while ((association = [associationSetEnumerator nextObject]))
	{
		NSString * sourceAtomKey = [association valueForKey:GeniusAssociationSourceAtomKeyKey];
		NSString * targetAtomKey = [association valueForKey:GeniusAssociationTargetAtomKeyKey];
		if (sourceAtomKey && targetAtomKey)
		{
			NSString * key = [NSString stringWithFormat:@"association_%@_%@", sourceAtomKey, targetAtomKey];
			[self setPrimitiveValue:association forKey:key];
		}
	}
}


- (NSArray *) _activeAssociations
{	
	// XXX: yuck
	GeniusDocument * document = [[NSDocumentController sharedDocumentController] currentDocument];
	int quizDirectionMode = [[document documentInfo] quizDirectionMode];
	
	if (quizDirectionMode == 1)
		return [NSArray arrayWithObject:[self valueForKey:GeniusItemAssociationABKey]];
	else
		return [NSArray arrayWithObjects:
			[self valueForKey:GeniusItemAssociationABKey], [self valueForKey:GeniusItemAssociationBAKey], NULL];
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
		NSDate * assocDate = [association valueForKey:GeniusAssociationLastResultDateKey];
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


- (void) resetAssociations
{
	NSSet * associationSet = [self valueForKey:GeniusItemAssociationsKey];
	NSEnumerator * associationEnumerator = [associationSet objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
		[association reset];
}


- (void) flushCache
{
	//NSLog(@"flushCache");
	
	//[_displayGrade release];
	_displayGrade = nil;
}

@end
