//
//  GeniusAssociationDataPoint.m
//  Genius2
//
//  Created by John R Chang on 2005-10-15.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAssociationDataPoint.h"


@implementation GeniusAssociationDataPoint

- (id) initWithDate:(NSDate *)date value:(float)value
{
	self = [super init];
	_date = [date copy];
	_value = value;
	return self;
}

- (void) dealloc
{
	[_date release];
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
	_date = [[coder decodeObject] retain];	
	[coder decodeValueOfObjCType:@encode(float) at:&_value];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:_date];
	[coder encodeValueOfObjCType:@encode(float) at:&_value];
}

	
- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@: %.1f>", [_date description], _value];
}

- (NSDate *) date
{
	return _date;
}

- (BOOL) value
{
	return _value >= 0.5;
}

@end


@implementation GeniusAssociationDataPoint (GradePrediction)

+ (float) _calculateLeastSquaresFit:(NSArray *)dataPoints
{
	// Compute least squares fit
	// http://people.hofstra.edu/faculty/Stefan_Waner/RealWorld/calctopic1/regression.html

	double sum_x = 0.0, sum_y = 0.0, sum_xy = 0.0, sum_xx = 0.0;	
	int i, n = [dataPoints count];
	for (i=0; i<n; i++)
	{
		GeniusAssociationDataPoint * dataPoint = [dataPoints objectAtIndex:i];

		NSTimeInterval t = [[dataPoint date] timeIntervalSinceReferenceDate];
		float q = [dataPoint value];
		
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
	NSTimeInterval t = [[NSDate date] timeIntervalSinceReferenceDate];	// now

	// Linear regression ("y = m * y + b")
	float y = m * t + b;

	return MIN(y, 1.0);
}


+ (NSArray *) _padDataPoints:(NSArray *)dataPoints
{
	NSMutableArray * tmpDataPoints = [[dataPoints mutableCopy] autorelease];

	NSDate * firstDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0.0];
	GeniusAssociationDataPoint * dataPoint = [[GeniusAssociationDataPoint alloc] initWithDate:firstDate value:0.0];
	[tmpDataPoints insertObject:dataPoint atIndex:0];
	[dataPoint release];

	NSDate * nowDate = [NSDate date];
	dataPoint = [[GeniusAssociationDataPoint alloc] initWithDate:nowDate value:0.333];	// tuning
	[tmpDataPoints addObject:dataPoint];
	[dataPoint release];

	return tmpDataPoints;
}


+ (float) predictedGradeWithDataPoints:(NSArray *)dataPoints
{
	NSArray * paddedDataPoints = [self _padDataPoints:dataPoints];
//	NSLog(@"%@", [paddedDataPoints description]);
	return [self _calculateLeastSquaresFit:paddedDataPoints];
}


/*
	0: 1 s
	1: 5 s
	2: 25 s
	3: 2.1 m
	4: 10.4 m
	5: 52.1 m
	6: 0.2 d
	7: 0.9 d
	8: 4.5 d
	9: 22.6 d
	10: 0.3 y
	11: 1.5 y
	12: 7.7 y
	13: 38.7 y
	14: 193.4 y
*/
+ (NSTimeInterval) timeIntervalForScore:(unsigned int)score
{
	const int maxN = 10;
	
	int n = MIN(score,maxN);
	NSTimeInterval interval = pow(5.0,n);
	
	int extraN = score - maxN;
	if (extraN > 0)
		interval += extraN * pow(5.0, maxN);
	
	return interval;
}

@end
