// 
//  GeniusAssociation.m
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAssociation.h"

#import "GeniusAssociationDataPoint.h"
#import "GeniusItem.h"	// GeniusItemLastTestedDateKey


//NSString * GeniusAssociationPredictedScoreKey = @"predictedScore";
NSString * GeniusAssociationDueDateKey = @"dueDate";
NSString * GeniusAssociationDataPointArrayDataKey = @"dataPointArrayData";

NSString * GeniusAssociationParentItemKey = @"parentItem";
NSString * GeniusAssociationSourceAtomKey = @"sourceAtom";
NSString * GeniusAssociationTargetAtomKey = @"targetAtom";


@implementation GeniusAssociation

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
    NSData * data = [self valueForKey:GeniusAssociationDataPointArrayDataKey];	// persistent
	if (data == nil)
		return nil;
    return [NSUnarchiver unarchiveObjectWithData:data];	
}

- (void) setDataPoints:(NSArray *)dataPoints
{
    NSData * data = nil;
	if (dataPoints)
		data = [NSArchiver archivedDataWithRootObject:dataPoints];
    [self setValue:data forKey:GeniusAssociationDataPointArrayDataKey];	
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


- (float) predictedScore
{
	NSArray * dataPoints = [self dataPoints];
	int n = [dataPoints count];
	if (n == 0)
		return -1.0;
	
	return [GeniusAssociationDataPoint predictedGradeWithDataPoints:dataPoints];
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
	return (/*[self valueForKey:GeniusAssociationLastDataPointDateKey] == nil
		&&*/ [self valueForKey:GeniusAssociationDueDateKey] == nil);
}

@end
