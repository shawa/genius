// 
//  GeniusItem.m
//  Genius2
//
//  Created by John R Chang on 2005-09-23.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusItem.h"

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


- (void) _attachAtomA:(GeniusAtom *)atomA atomB:(GeniusAtom *)atomB
{
	NSMutableSet * atomSet = [self mutableSetValueForKey:GeniusItemAtomsKey];	// persistent
	[atomSet addObject:atomA];
	[atomSet addObject:atomB];
}

- (void) _detachAtoms
{
	NSMutableSet * atomSet = [self mutableSetValueForKey:GeniusItemAtomsKey];	// persistent
	[atomSet removeAllObjects];

	[_atomA release];
	_atomA = nil;
	
	[_atomB release];
	_atomB = nil;
}

- (void) _addSelfAsObserverToChildAtoms
{
	NSSet * atomSet = [self valueForKey:GeniusItemAtomsKey];	// persistent
	NSEnumerator * atomSetEnumerator = [atomSet objectEnumerator];
	NSManagedObject * atom;
	while ((atom = [atomSetEnumerator nextObject]))
		[atom addObserver:self forKeyPath:GeniusAtomModifiedDateKey options:0 context:NULL];
}

- (void) _removeSelfAsObserverToChildAtoms
{
	NSSet * atomSet = [self valueForKey:GeniusItemAtomsKey];	// persistent
	NSEnumerator * atomSetEnumerator = [atomSet objectEnumerator];
	NSManagedObject * atom;
	while ((atom = [atomSetEnumerator nextObject]))
		[atom removeObserver:self forKeyPath:GeniusAtomModifiedDateKey];
}


- (id)copyWithZone:(NSZone *)zone
{
	NSManagedObjectContext * context = [self managedObjectContext];

	// Create new item
	GeniusItem * newObject = [[[self class] allocWithZone:zone] initWithEntity:[self entity] insertIntoManagedObjectContext:context];

	// Remove new atoms
	[newObject _detachAtoms];
	[newObject _removeSelfAsObserverToChildAtoms];
	
	// Use old atoms
	GeniusAtom * newAtomA = [[[self atomA] copy] autorelease];
	GeniusAtom * newAtomB = [[[self atomB] copy] autorelease];
	[newObject _attachAtomA:newAtomA atomB:newAtomB];

	[newObject _addSelfAsObserverToChildAtoms];

    return newObject;
}

- (void) commonAwake
{
	[self _addSelfAsObserverToChildAtoms];

//	[self flushCache];
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];

	NSManagedObjectContext * context = [self managedObjectContext];

	// Create atoms
	GeniusAtom * atomA = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	
	[atomA setPrimitiveValue:GeniusItemAtomAKey forKey:GeniusAtomKeyKey];

	GeniusAtom * atomB = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAtom" inManagedObjectContext:context];	
	[atomB setPrimitiveValue:GeniusItemAtomBKey forKey:GeniusAtomKeyKey];

	// Link new atoms to self
	[self _attachAtomA:atomA atomB:atomB];

	// Create associations
	NSManagedObject * assocAB = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[assocAB setPrimitiveValue:GeniusAssociationAtomAKeyValue forKey:GeniusAssociationSourceAtomKeyKey];
	[assocAB setPrimitiveValue:GeniusAssociationAtomBKeyValue forKey:GeniusAssociationTargetAtomKeyKey];

	NSManagedObject * assocBA = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[assocBA setPrimitiveValue:GeniusAssociationAtomBKeyValue forKey:GeniusAssociationSourceAtomKeyKey];
	[assocBA setPrimitiveValue:GeniusAssociationAtomAKeyValue forKey:GeniusAssociationTargetAtomKeyKey];

	[self setPrimitiveValue:assocAB forKey:GeniusItemAssociationABKey];	// transient
	[self setPrimitiveValue:assocBA forKey:GeniusItemAssociationBAKey];	// transient

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

/*	// Set up transient atoms
	NSSet * atomSet = [self valueForKey:GeniusItemAtomsKey];
	NSEnumerator * atomSetEnumerator = [atomSet objectEnumerator];
	NSManagedObject * atom;
	while ((atom = [atomSetEnumerator nextObject]))
	{
		NSString * key = [atom valueForKey:GeniusAtomKeyKey];
		if (key)
			[self setPrimitiveValue:atom forKey:key];
	}*/

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
	
	[self commonAwake];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:GeniusAtomModifiedDateKey])
	{
		[self touchLastModifiedDate];
	}
}


- (GeniusAtom *) _atomForKey:(NSString *)aKey
{
	// is NSFetchRequest faster?

	NSSet * atomSet = [self valueForKey:GeniusItemAtomsKey];
	NSEnumerator * atomSetEnumerator = [atomSet objectEnumerator];
	GeniusAtom * atom;
	while ((atom = [atomSetEnumerator nextObject]))
	{
		NSString * key = [atom valueForKey:GeniusAtomKeyKey];
		if ([key isEqualToString:aKey])
			return atom;
	}
	return nil;
}

- (GeniusAtom *) atomA
{
	if (_atomA == nil)
		_atomA = [[self _atomForKey:GeniusItemAtomAKey] retain];
	return _atomA;
}

- (GeniusAtom *) atomB
{
	if (_atomB == nil)
		_atomB = [[self _atomForKey:GeniusItemAtomBKey] retain];
	return _atomB;
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
	GeniusAtom * atomA = [self atomA];
	GeniusAtom * atomB = [self atomB];

	[atomA setPrimitiveValue:GeniusItemAtomBKey forKey:GeniusAtomKeyKey];
	[atomB setPrimitiveValue:GeniusItemAtomAKey forKey:GeniusAtomKeyKey];

	[_atomA release];
	_atomA = nil;
	
	[_atomB release];
	_atomB = nil;

	[self touchLastModifiedDate];
}

- (BOOL) usesDefaultTextAttributes
{
	NSSet * atomSet = [self valueForKey:GeniusItemAtomsKey]; 
	NSEnumerator * atomEnumerator = [atomSet objectEnumerator];
	GeniusAtom * atom;
	while ((atom = [atomEnumerator nextObject]))
		if ([atom usesDefaultTextAttributes] == NO)
			return NO;
	return YES;
}

- (void) clearTextAttributes
{
	NSSet * atomSet = [self valueForKey:GeniusItemAtomsKey]; 
	[atomSet makeObjectsPerformSelector:@selector(clearTextAttributes)];
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
