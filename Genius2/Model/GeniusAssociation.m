// 
//  GeniusAssociation.m
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAssociation.h"

#import "GeniusItem.h"


@interface GeniusAssociation (Private)

- (void) _recacheDataPointsArray;

- (void) _recalculatePredictedScore;
- (void) _recalculateLastDataPointDate;

@end


@implementation GeniusAssociation 

- (void) commonAwake
{
	_dataPoints = nil;
	[self _recacheDataPointsArray];
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
	if ([key isEqualToString:@"dataPointsData"])
	{
		[self _recacheDataPointsArray];

		[self _recalculatePredictedScore];
		[self _recalculateLastDataPointDate];

		GeniusItem * item = [self valueForKey:@"parentItem"];
		[item touchLastTestedDate];
	}
	
	[super didChangeValueForKey:key];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"dataPointsData"])
	{
		[self _recacheDataPointsArray];

		[self _recalculatePredictedScore];
		[self _recalculateLastDataPointDate];
	}
}

- (void) _setDataPointsArray:(NSArray *)dataPoints
{
	[_dataPoints release];
    _dataPoints = [dataPoints retain];

    NSData * data = nil;
	if (dataPoints)
		data = [NSArchiver archivedDataWithRootObject:dataPoints];
    [self willChangeValueForKey:@"dataPointsData"];
    [self setPrimitiveValue:data forKey:@"dataPointsData"];
    [self didChangeValueForKey:@"dataPointsData"];
}

- (void) _recacheDataPointsArray
{
	[_dataPoints release];

    [self willAccessValueForKey:@"dataPointsData"];
    NSData * data = [self primitiveValueForKey:@"dataPointsData"];	// persistent
    [self didAccessValueForKey:@"dataPointsData"];
	if (data == nil)
		return;
    _dataPoints = [[NSUnarchiver unarchiveObjectWithData:data] retain];
}

- (void) _recalculatePredictedScore
{
	int n = [_dataPoints count];
	if (n == 0)
	{
		[self setPrimitiveValue:nil forKey:@"predictedScore"];	// persistent
		return;
	}
	
	id firstDataPoint = [_dataPoints objectAtIndex:0];
	NSDate * firstDate = [firstDataPoint valueForKey:@"date"];
	
	// Compute least squares fit
	// http://people.hofstra.edu/faculty/Stefan_Waner/RealWorld/calctopic1/regression.html

	double sum_x = 0.0, sum_y = 0.0, sum_xy = 0.0, sum_xx = 0.0;	
	int i;
	for (i=0; i<n; i++)
	{
		id dataPoint = [_dataPoints objectAtIndex:i];
		
		NSDate * date = [dataPoint valueForKey:@"date"];
		BOOL didAnswerCorrect = [[dataPoint valueForKey:@"didAnswerCorrect"] boolValue];		

		NSTimeInterval t = [date timeIntervalSinceDate:firstDate];
		int q = (int)didAnswerCorrect;
		
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
	id lastDataPoint = [_dataPoints lastObject];
	NSDate * lastDataPointDate = [lastDataPoint valueForKey:@"date"];
	NSTimeInterval t_delta = [lastDataPointDate timeIntervalSinceDate:firstDate];
	NSTimeInterval t_mean = t_delta / n;
	NSTimeInterval t = [[lastDataPointDate addTimeInterval:t_mean] timeIntervalSinceDate:firstDate];

	// Logarithmic regression ("q = A * r^t")
	/*float r = pow(10, m);
	float A = pow(10, b);
	float q = A * pow(r, t_now);	
	return q;*/

	// Linear regression ("y = m * y + b")
	float y = m * t + b;

	float predictedScore = MIN(y, 1.0);
	[self setPrimitiveValue:[NSNumber numberWithFloat:predictedScore] forKey:@"predictedScore"];	// persistent
}

- (void) _recalculateLastDataPointDate
{
	NSDictionary * dataPoint = [_dataPoints lastObject];	// persistent
	NSDate * lastDataPointDate = [dataPoint valueForKey:@"date"];	
	[self setValue:lastDataPointDate forKey:@"lastDataPointDate"];
}


- (void) addBoolValue:(BOOL)value
{
	// update dataPointsData
	NSDate * nowDate = [NSDate date];
	NSDictionary * dataPoint = [NSDictionary dictionaryWithObjectsAndKeys:
		nowDate, @"date", [NSNumber numberWithBool:value], @"didAnswerCorrect", NULL];
	[self _setDataPointsArray:[_dataPoints arrayByAddingObject:dataPoint]];
	
	// update dueDate
	// XXX: TO DO
#warning need to recalculate dueDate

	// update derived values
	[self _recalculatePredictedScore];
	[self setValue:nowDate forKey:@"lastDataPointDate"];

}

- (void) reset
{
    [self setValue:nil forKey:@"dataPointsData"];	// persistent
	[self setValue:nil forKey:@"dueDate"];			// persistent

	[self setPrimitiveValue:nil forKey:@"predictedScore"];	// persistent, derived
    [self setValue:nil forKey:@"lastDataPointDate"];	// persistent, derived
}

@end
