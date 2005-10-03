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
#import "GeniusDocumentInfo.h"	// -documentInfo
@interface GeniusDocumentInfo (Private)
- (int) quizDirectionMode;
@end


@interface GeniusItem (Private)

- (void) _recalculateLastModifiedDate;
- (void) _recalculateLastTestedDate;
- (void) _recalculateGrade;

@end


@implementation GeniusItem 

+ (void) initialize {
	NSArray * atomKeys = [GeniusItem allAtomKeys];
	NSArray * keys = [atomKeys arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:@"isEnabled",
		@"myRating", @"myGroup", @"myType", @"myNotes", nil]];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"lastModifiedDate"];
}

+ (NSArray *) allAtomKeys
{
	return [NSArray arrayWithObjects:@"atomA", @"atomB", nil];
}


- (void)awakeFromInsert
{
	[super awakeFromInsert];

	[self flushCache];

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
	[self setPrimitiveValue:atomA forKey:@"atomA"];	// transient
	[self setPrimitiveValue:atomB forKey:@"atomB"];	// transient

	NSMutableSet * atomSet = [self mutableSetValueForKey:@"atoms"];	// persistent
	[atomSet addObject:atomA];
	[atomSet addObject:atomB];

	// Create associations
	NSManagedObject * assocAB = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[assocAB setPrimitiveValue:@"atomA" forKey:@"sourceAtomKey"];
	[assocAB setPrimitiveValue:@"atomB" forKey:@"targetAtomKey"];

	NSManagedObject * assocBA = [NSEntityDescription insertNewObjectForEntityForName:@"GeniusAssociation" inManagedObjectContext:context];
	[assocBA setPrimitiveValue:@"atomB" forKey:@"sourceAtomKey"];
	[assocBA setPrimitiveValue:@"atomA" forKey:@"targetAtomKey"];

	[self setPrimitiveValue:assocAB forKey:@"association_atomA_atomB"];	// transient
	[self setPrimitiveValue:assocBA forKey:@"association_atomB_atomA"];	// transient

	NSMutableSet * associationSet = [self mutableSetValueForKey:@"associations"];	// persistent
	[associationSet addObject:assocAB];
	[associationSet addObject:assocBA];

	// Set up observers
	[self setPrimitiveValue:[NSDate date] forKey:@"lastModifiedDate"];
	[atomA addObserver:self forKeyPath:@"dirty" options:0L context:NULL];
	[atomB addObserver:self forKeyPath:@"dirty" options:0L context:NULL];

	[assocAB addObserver:self forKeyPath:@"lastDataPointDate" options:0L context:NULL];
	[assocBA addObserver:self forKeyPath:@"lastDataPointDate" options:0L context:NULL];

	[self addObserver:self forKeyPath:@"lastModifiedDate" options:0L context:NULL];
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];

	[self flushCache];

	// Set up transient atoms
	NSSet * atomSet = [self valueForKey:@"atoms"];
	NSEnumerator * atomSetEnumerator = [atomSet objectEnumerator];
	NSManagedObject * atom;
	while ((atom = [atomSetEnumerator nextObject]))
	{
		NSString * key = [atom valueForKey:@"key"];
		if (key)
		{
			[self setPrimitiveValue:atom forKey:key];
			[atom addObserver:self forKeyPath:@"dirty" options:0L context:NULL];
		}
	}

	// Set up transient associations
	NSSet * associationSet = [self valueForKey:@"associations"];
	NSEnumerator * associationSetEnumerator = [associationSet objectEnumerator];
	NSManagedObject * association;
	while ((association = [associationSetEnumerator nextObject]))
	{
		NSString * sourceAtomKey = [association valueForKey:@"sourceAtomKey"];
		NSString * targetAtomKey = [association valueForKey:@"targetAtomKey"];
		if (sourceAtomKey && targetAtomKey)
		{
			NSString * key = [NSString stringWithFormat:@"association_%@_%@", sourceAtomKey, targetAtomKey];
			[self setPrimitiveValue:association forKey:key];

			[association addObserver:self forKeyPath:@"lastDataPointDate" options:0L context:NULL];
		}
	}

	// Set up observers
	[self addObserver:self forKeyPath:@"lastModifiedDate" options:0L context:NULL];
}

- (void) dealloc
{
	// Remove observers
	NSSet * atomSet = [self valueForKey:@"atoms"];
	NSEnumerator * atomSetEnumerator = [atomSet objectEnumerator];
	NSManagedObject * atom;
	while ((atom = [atomSetEnumerator nextObject]))
		[atom removeObserver:self forKeyPath:@"dirty"];

	NSSet * associationSet = [self valueForKey:@"associations"];
	NSEnumerator * associationSetEnumerator = [associationSet objectEnumerator];
	NSManagedObject * association;
	while ((association = [associationSetEnumerator nextObject]))
		[association removeObserver:self forKeyPath:@"lastDataPointDate"];
	
    [self removeObserver:self forKeyPath:@"lastModifiedDate"];
	
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"lastModifiedDate"] || [keyPath isEqual:@"dirty"])	// item or atom info changed
	{
		[self _recalculateLastModifiedDate];
	}
	else if ([keyPath isEqual:@"lastDataPointDate"])	// association changed
	{
		[self _recalculateLastTestedDate];
		[self _recalculateGrade];
		[self flushCache];
	}
}


- (NSString *) description
{
	return [NSString stringWithFormat:@"<GeniusItem %#X: (\"%@\", \"%@\")>", self,
		[[self valueForKey:@"atomA"] description], [[self valueForKey:@"atomB"] description]];
}


- (NSArray *) _activeAssociations
{	
	// XXX: yuck
	GeniusDocument * document = [[NSDocumentController sharedDocumentController] currentDocument];
	int quizDirectionMode = [[document documentInfo] quizDirectionMode];
	
	if (quizDirectionMode == 1)
		return [NSArray arrayWithObject:[self valueForKey:@"association_atomA_atomB"]];
	else
		return [NSArray arrayWithObjects:
			[self valueForKey:@"association_atomA_atomB"], [self valueForKey:@"association_atomB_atomA"], NULL];
}


- (void) _recalculateLastModifiedDate
{
	[self setPrimitiveValue:[NSDate date] forKey:@"lastModifiedDate"];
}

- (void) _recalculateLastTestedDate
{
	NSDate * lastTestedDate = nil;
	
	NSArray * activeAssociations = [self _activeAssociations];
	NSEnumerator * associationEnumerator = [activeAssociations objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
	{
		NSDate * assocDate = [association valueForKey:@"lastDataPointDate"];
		lastTestedDate = (lastTestedDate ? [lastTestedDate laterDate:assocDate] : assocDate);
	}

	[self setPrimitiveValue:lastTestedDate forKey:@"lastTestedDate"];
}

- (void) _recalculateGrade
{
	float sum = 0.0;
	
	NSArray * activeAssociations = [self _activeAssociations];	
	NSEnumerator * associationEnumerator = [activeAssociations objectEnumerator];
	GeniusAssociation * association;
	while ((association = [associationEnumerator nextObject]))
	{
		float predictedScore = [[association valueForKey:@"predictedScore"] floatValue];
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


- (void) setUsesRichText:(BOOL)flag forAtomAtIndex:(int)atomIndex
{
	NSString * atomKey = [[GeniusItem allAtomKeys] objectAtIndex:atomIndex];
	GeniusAtom * atom = [self valueForKey:atomKey];
	[atom setUsesRTFData:flag];
}


- (void) resetAssociations
{
	NSSet * associationSet = [self valueForKey:@"associations"];
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
