//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusAssociation.h"

#import "GeniusAssociationDataPoint.h"
#import "GeniusItem.h"	// GeniusItemLastTestedDateKey


NSString * GeniusAssociationDueDateKey = @"dueDate";
NSString * GeniusAssociationDataPointArrayDataKey = @"dataPointArrayData";
NSString * GeniusAssociationHandicapKey = @"handicap";

static NSString * GeniusAssociationDataPointsKey = @"dataPoints";
static NSString * GeniusAssociationCorrectCountKey = @"correctCount";
NSString * GeniusAssociationPredictedValueKey = @"predictedValue";

NSString * GeniusAssociationParentItemKey = @"parentItem";
NSString * GeniusAssociationSourceAtomKey = @"sourceAtom";
NSString * GeniusAssociationTargetAtomKey = @"targetAtom";


@implementation GeniusAssociation

+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObjects:GeniusAssociationDataPointsKey, GeniusAssociationHandicapKey,nil]
		triggerChangeNotificationsForDependentKey:GeniusAssociationCorrectCountKey];
    [self setKeys:[NSArray arrayWithObjects:GeniusAssociationDataPointsKey, GeniusAssociationHandicapKey,nil]
		triggerChangeNotificationsForDependentKey:GeniusAssociationPredictedValueKey];
}

- (GeniusAtom *) sourceAtom
{
	[self willAccessValueForKey:GeniusAssociationSourceAtomKey];
	id result = [self primitiveValueForKey:GeniusAssociationSourceAtomKey];
	[self didAccessValueForKey:GeniusAssociationSourceAtomKey];
	return result;
}

- (GeniusAtom *) targetAtom
{
	[self willAccessValueForKey:GeniusAssociationTargetAtomKey];
	id result = [self primitiveValueForKey:GeniusAssociationTargetAtomKey];
	[self didAccessValueForKey:GeniusAssociationTargetAtomKey];
	return result;
}

@end


@implementation GeniusAssociation (Results)

- (NSArray *) dataPoints
{
	[self willAccessValueForKey:GeniusAssociationDataPointsKey];
	NSArray * dataPoints = nil; 
    NSData * data = [self valueForKey:GeniusAssociationDataPointArrayDataKey];	// persistent
	if (data)
		dataPoints = [NSUnarchiver unarchiveObjectWithData:data];	
	[self didAccessValueForKey:GeniusAssociationDataPointsKey];
	return dataPoints;
}

- (void) setDataPoints:(NSArray *)dataPoints
{
	[self willChangeValueForKey:GeniusAssociationDataPointsKey];
    NSData * data = nil;
	if (dataPoints)
		data = [NSArchiver archivedDataWithRootObject:dataPoints];
    [self setValue:data forKey:GeniusAssociationDataPointArrayDataKey];	
	[self didChangeValueForKey:GeniusAssociationDataPointsKey];

	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:GeniusItemScoreHasChangedNotification object:[self valueForKey:GeniusAssociationParentItemKey]];
}


- (unsigned int) correctCount
{
	[self willAccessValueForKey:GeniusAssociationCorrectCountKey];
	
	unsigned int correctCount = 0;
	NSArray * dataPoints = [self dataPoints];
	NSEnumerator * dataPointEnumerator = [dataPoints objectEnumerator];
	GeniusAssociationDataPoint * dataPoint;
	while ((dataPoint = [dataPointEnumerator nextObject]))
		if ([dataPoint value] == YES)
			correctCount++;
			
	NSNumber * handicapNumber = [self valueForKey:GeniusAssociationHandicapKey];
	correctCount += [handicapNumber unsignedIntValue];

	[self didAccessValueForKey:GeniusAssociationCorrectCountKey];
	
	return correctCount;
}

- (void) setCorrectCount:(NSNumber *)countNumber
{
	int count = [countNumber intValue];
	if (count < 0)
		count = 0;
		
	[self willChangeValueForKey:GeniusAssociationCorrectCountKey];
	
	unsigned int oldCount = [[self dataPoints] count];
	int delta = count - oldCount;
	if (delta <= 0)
	{
		[self setDataPoints:nil];
		[self setValue:[NSNumber numberWithUnsignedInt:count] forKey:GeniusAssociationHandicapKey];
	}
	else if (delta > 0)
	{
		[self setValue:[NSNumber numberWithUnsignedInt:delta] forKey:GeniusAssociationHandicapKey];
	}
	
	[self didChangeValueForKey:GeniusAssociationCorrectCountKey];

	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:GeniusItemScoreHasChangedNotification object:[self valueForKey:GeniusAssociationParentItemKey]];
}


- (void) addResult:(BOOL)value
{
	// update dataPointArrayData
	NSDate * nowDate = [NSDate date];
	GeniusAssociationDataPoint * dataPoint = [[GeniusAssociationDataPoint alloc] initWithDate:nowDate value:(float)value];

	NSArray * dataPoints = [self dataPoints];
	NSArray * tmpDataPoints = [dataPoints arrayByAddingObject:dataPoint];
	[self setDataPoints:tmpDataPoints];
	
	// dueDate is updated in -[GeniusAssociationEnumerator _rescheduleCurrentAssociation]
	
	// update derived values
/*	[self _recalculatePredictedScore];
	[self setValue:nowDate forKey:GeniusAssociationLastDataPointDateKey];*/
	
	GeniusItem * parentItem = [self valueForKey:GeniusAssociationParentItemKey];
	[parentItem setValue:[NSDate date] forKey:GeniusItemLastTestedDateKey];
}


+ (float) _handicapToPercentValue:(unsigned int)handicap
{
	float result = handicap * 0.2;
	return MIN(result, 1.0);
}

- (float) predictedValue
{
	[self willAccessValueForKey:GeniusAssociationPredictedValueKey];

	NSArray * dataPoints = [self dataPoints];
	float result = [GeniusAssociationDataPoint predictedValueWithDataPoints:dataPoints];
	unsigned int handicap = [[self valueForKey:GeniusAssociationHandicapKey] unsignedIntValue];
	if (result == -1.0 && handicap > 0)
		result = 0.0;
	result += [GeniusAssociation _handicapToPercentValue:handicap];
	
	[self willAccessValueForKey:GeniusAssociationPredictedValueKey];

	if (result == -1.0)
		return -1.0;
	return MIN(result, 1.0);
}


- (unsigned int) resultCount
{
	NSArray * dataPoints = [self dataPoints];
	return [dataPoints count];
}

- (GeniusAssociationDataPoint *) lastDataPoint
{
	NSArray * dataPoints = [self dataPoints];
	return [dataPoints lastObject];
}


- (void) reset
{
    [self setValue:nil forKey:GeniusAssociationDataPointArrayDataKey];	// persistent
	[self setValue:nil forKey:GeniusAssociationDueDateKey];			// persistent

/*	[self setPrimitiveValue:nil forKey:GeniusAssociationPredictedScoreKey];	// persistent, derived
    [self setValue:nil forKey:GeniusAssociationLastDataPointDateKey];	// persistent, derived */
}

- (BOOL) isReset
{
	return ([self valueForKey:GeniusAssociationDataPointArrayDataKey] == nil
		&& [self valueForKey:GeniusAssociationDueDateKey] == nil);
}

@end
