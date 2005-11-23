// 
//  GeniusAssociation.m
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAssociation.h"

#import "GeniusItem.h"	// -touchLastTestedDate
#import "GeniusAssociationDataPoint.h"


static NSString * GeniusAssociationParentItemKey = @"parentItem";	// XXX should be exported?
NSString * GeniusAssociationSourceAtomKeyKey = @"sourceAtomKey";
NSString * GeniusAssociationTargetAtomKeyKey = @"targetAtomKey";

NSString * GeniusAssociationDueDateKey = @"dueDate";
NSString * GeniusAssociationDataPointArrayDataKey = @"dataPointArrayData";
NSString * GeniusAssociationLastDataPointDateKey = @"lastDataPointDate";
NSString * GeniusAssociationPredictedScoreKey = @"predictedScore";


@interface GeniusAssociation (Private)

- (void) _recacheResultsArray;

- (void) _recalculatePredictedScore;
- (void) _recalculateLastDataPointDate;

@end


@implementation GeniusAssociation 

- (void) commonAwake
{
	_dataPoints = nil;
	[self _recacheResultsArray];
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	[self commonAwake];
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	[self commonAwake];
}

- (void) didTurnIntoFault
{
	// Remove observers	
	[_dataPoints release];

    [super didTurnIntoFault];
}


- (void)didChangeValueForKey:(NSString *)key
{
	if ([key isEqualToString:GeniusAssociationDataPointArrayDataKey])
	{
		[self _recacheResultsArray];

		[self _recalculatePredictedScore];
		[self _recalculateLastDataPointDate];

		GeniusItem * item = [self valueForKey:GeniusAssociationParentItemKey];
		[item touchLastTestedDate];
	}
	
	[super didChangeValueForKey:key];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:GeniusAssociationDataPointArrayDataKey])
	{
		[self _recacheResultsArray];

		[self _recalculatePredictedScore];
		[self _recalculateLastDataPointDate];
	}
}


- (void) _setDataPointsArray:(NSArray *)resultDicts
{
	[_dataPoints release];
    _dataPoints = [resultDicts retain];

    NSData * data = nil;
	if (resultDicts)
		data = [NSArchiver archivedDataWithRootObject:resultDicts];
    [self willChangeValueForKey:GeniusAssociationDataPointArrayDataKey];
    [self setPrimitiveValue:data forKey:GeniusAssociationDataPointArrayDataKey];
    [self didChangeValueForKey:GeniusAssociationDataPointArrayDataKey];
}

- (void) _recacheResultsArray
{
	[_dataPoints release];

    [self willAccessValueForKey:GeniusAssociationDataPointArrayDataKey];
    NSData * data = [self primitiveValueForKey:GeniusAssociationDataPointArrayDataKey];	// persistent
    [self didAccessValueForKey:GeniusAssociationDataPointArrayDataKey];
	if (data == nil)
		return;
    _dataPoints = [[NSUnarchiver unarchiveObjectWithData:data] retain];
}


- (void) _recalculatePredictedScore
{
	int n = [_dataPoints count];
	if (n == 0)
	{
		[self setPrimitiveValue:nil forKey:GeniusAssociationPredictedScoreKey];	// persistent
		return;
	}
	
	float predictedScore = [GeniusAssociationDataPoint predictedGradeWithDataPoints:_dataPoints];
	[self setPrimitiveValue:[NSNumber numberWithFloat:predictedScore] forKey:GeniusAssociationPredictedScoreKey];	// persistent
}

- (void) _recalculateLastDataPointDate
{
	GeniusAssociationDataPoint * dataPoint = [_dataPoints lastObject];	// persistent
	NSDate * lastDate = [dataPoint date];
	[self setValue:lastDate forKey:GeniusAssociationLastDataPointDateKey];
}


- (GeniusAtom *) sourceAtom
{
	GeniusItem * item = [self valueForKey:GeniusAssociationParentItemKey];
	NSString * atomKey = [self valueForKey:GeniusAssociationSourceAtomKeyKey];
	return [item valueForKey:atomKey];
}

- (GeniusAtom *) targetAtom
{
	GeniusItem * item = [self valueForKey:GeniusAssociationParentItemKey];
	NSString * atomKey = [self valueForKey:GeniusAssociationTargetAtomKeyKey];
	return [item valueForKey:atomKey];
}


- (BOOL) lastDataPointValue
{
	GeniusAssociationDataPoint * dataPoint = [_dataPoints lastObject];
	if (dataPoint == nil)
		return NO;
	return ([dataPoint value] >= 0.5);
}

- (unsigned int) resultCount
{
	return [_dataPoints count];
}

- (void) addResult:(BOOL)value
{
	// update dataPointArrayData
	NSDate * nowDate = [NSDate date];
	GeniusAssociationDataPoint * dataPoint = [[GeniusAssociationDataPoint alloc] initWithDate:nowDate value:(float)value];
	[self _setDataPointsArray:[_dataPoints arrayByAddingObject:dataPoint]];
	
	// dueDate is updated in -[GeniusAssociationEnumerator _rescheduleCurrentAssociation]
	
	// update derived values
	[self _recalculatePredictedScore];
	[self setValue:nowDate forKey:GeniusAssociationLastDataPointDateKey];

}

- (void) reset
{
    [self setValue:nil forKey:GeniusAssociationDataPointArrayDataKey];	// persistent
	[self setValue:nil forKey:GeniusAssociationDueDateKey];			// persistent

	[self setPrimitiveValue:nil forKey:GeniusAssociationPredictedScoreKey];	// persistent, derived
    [self setValue:nil forKey:GeniusAssociationLastDataPointDateKey];	// persistent, derived
}

- (BOOL) isReset
{
	return ([self valueForKey:GeniusAssociationLastDataPointDateKey] == nil
		&& [self valueForKey:GeniusAssociationDueDateKey] == nil);
}

@end
