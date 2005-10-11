// 
//  GeniusAssociation.m
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAssociation.h"

#import "GeniusItem.h"	// -touchLastTestedDate


static NSString * GeniusAssociationParentItemKey = @"parentItem";	// XXX should be exported?
NSString * GeniusAssociationSourceAtomKeyKey = @"sourceAtomKey";
NSString * GeniusAssociationTargetAtomKeyKey = @"targetAtomKey";

NSString * GeniusAssociationLastResultDateKey = @"lastResultDate";
NSString * GeniusAssociationDueDateKey = @"dueDate";
NSString * GeniusAssociationPredictedScoreKey = @"predictedScore";
NSString * GeniusAssociationResultDictsKey = @"resultDictArrayData";

NSString * GeniusAssociationResultDictDateKey = @"date";
NSString * GeniusAssociationResultDictValueKey = @"value";


@interface GeniusAssociation (Private)

- (void) _recacheResultsArray;

- (void) _recalculatePredictedScore;
- (void) _recalculateLastResultDate;

@end


@implementation GeniusAssociation 

- (void) commonAwake
{
	_resultDicts = nil;
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
	[_resultDicts release];

    [super didTurnIntoFault];
}


- (void)didChangeValueForKey:(NSString *)key
{
	if ([key isEqualToString:GeniusAssociationResultDictsKey])
	{
		[self _recacheResultsArray];

		[self _recalculatePredictedScore];
		[self _recalculateLastResultDate];

		GeniusItem * item = [self valueForKey:GeniusAssociationParentItemKey];
		[item touchLastTestedDate];
	}
	
	[super didChangeValueForKey:key];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:GeniusAssociationResultDictsKey])
	{
		[self _recacheResultsArray];

		[self _recalculatePredictedScore];
		[self _recalculateLastResultDate];
	}
}


- (void) _setDataPointsArray:(NSArray *)dataPoints
{
	[_resultDicts release];
    _resultDicts = [dataPoints retain];

    NSData * data = nil;
	if (dataPoints)
		data = [NSArchiver archivedDataWithRootObject:dataPoints];
    [self willChangeValueForKey:GeniusAssociationResultDictsKey];
    [self setPrimitiveValue:data forKey:GeniusAssociationResultDictsKey];
    [self didChangeValueForKey:GeniusAssociationResultDictsKey];
}

- (void) _recacheResultsArray
{
	[_resultDicts release];

    [self willAccessValueForKey:GeniusAssociationResultDictsKey];
    NSData * data = [self primitiveValueForKey:GeniusAssociationResultDictsKey];	// persistent
    [self didAccessValueForKey:GeniusAssociationResultDictsKey];
	if (data == nil)
		return;
    _resultDicts = [[NSUnarchiver unarchiveObjectWithData:data] retain];
}

- (void) _recalculatePredictedScore
{
	int n = [_resultDicts count];
	if (n == 0)
	{
		[self setPrimitiveValue:nil forKey:GeniusAssociationPredictedScoreKey];	// persistent
		return;
	}
	
	id firstDataPoint = [_resultDicts objectAtIndex:0];
	NSDate * firstDate = [firstDataPoint valueForKey:GeniusAssociationResultDictDateKey];
	
	// Compute least squares fit
	// http://people.hofstra.edu/faculty/Stefan_Waner/RealWorld/calctopic1/regression.html

	double sum_x = 0.0, sum_y = 0.0, sum_xy = 0.0, sum_xx = 0.0;	
	int i;
	for (i=0; i<n; i++)
	{
		id resultDict = [_resultDicts objectAtIndex:i];
		
		NSDate * date = [resultDict valueForKey:GeniusAssociationResultDictDateKey];
		BOOL result = [[resultDict valueForKey:GeniusAssociationResultDictValueKey] boolValue];		

		NSTimeInterval t = [date timeIntervalSinceDate:firstDate];
		int q = (int)result;
		
		// Set x and y
		double x = t;
		float y = q; //log(q);
		
		sum_x += x;
		sum_y += y;
		sum_xy += x * y;
		sum_xx += x * x;
	}

	double m = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x);	// slope
	double b = (sum_y - m * sum_x) / n;										// intercept
	
	// The t to be used for prediction
	id lastDataPoint = [_resultDicts lastObject];
	NSDate * lastResultDate = [lastDataPoint valueForKey:GeniusAssociationResultDictDateKey];
	NSTimeInterval t_delta = [lastResultDate timeIntervalSinceDate:firstDate];
	NSTimeInterval t_mean = t_delta / n;
	NSTimeInterval t = [[lastResultDate addTimeInterval:t_mean] timeIntervalSinceDate:firstDate];

	// Logarithmic regression ("q = A * r^t")
	/*float r = pow(10, m);
	float A = pow(10, b);
	float q = A * pow(r, t_now);	
	return q;*/

	// Linear regression ("y = m * y + b")
	float y = m * t + b;

	float predictedScore = MIN(y, 1.0);
	[self setPrimitiveValue:[NSNumber numberWithFloat:predictedScore] forKey:GeniusAssociationPredictedScoreKey];	// persistent
}

- (void) _recalculateLastResultDate
{
	NSDictionary * resultDict = [_resultDicts lastObject];	// persistent
	NSDate * lastResultDate = [resultDict valueForKey:GeniusAssociationResultDictDateKey];	
	[self setValue:lastResultDate forKey:GeniusAssociationLastResultDateKey];
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


- (BOOL) lastResult
{
	NSDictionary * resultDict = [_resultDicts lastObject];
	if (resultDict == nil)
		return NO;
	return [[resultDict objectForKey:GeniusAssociationResultDictValueKey] boolValue];
}

- (unsigned int) resultCount
{
	return [_resultDicts count];
}

- (void) addResult:(BOOL)value
{
	// update resultDictArrayData
	NSDate * nowDate = [NSDate date];
	NSDictionary * resultDict = [NSDictionary dictionaryWithObjectsAndKeys:
		nowDate, GeniusAssociationResultDictDateKey,
		[NSNumber numberWithBool:value], GeniusAssociationResultDictValueKey, NULL];
	[self _setDataPointsArray:[_resultDicts arrayByAddingObject:resultDict]];
	
	// dueDate is updated in -[GeniusAssociationEnumerator _rescheduleCurrentAssociation]
	
	// update derived values
	[self _recalculatePredictedScore];
	[self setValue:nowDate forKey:GeniusAssociationLastResultDateKey];

}

- (void) reset
{
    [self setValue:nil forKey:GeniusAssociationResultDictsKey];	// persistent
	[self setValue:nil forKey:GeniusAssociationDueDateKey];			// persistent

	[self setPrimitiveValue:nil forKey:GeniusAssociationPredictedScoreKey];	// persistent, derived
    [self setValue:nil forKey:GeniusAssociationLastResultDateKey];	// persistent, derived
}

@end
