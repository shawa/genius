//
//  GeniusAssociationDataPoint.h
//  Genius2
//
//  Created by John R Chang on 2005-10-15.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GeniusAssociationDataPoint : NSObject <NSCoding> {
	NSDate * _date;
	float _value;
}

- (id) initWithDate:(NSDate *)date value:(float)value;

- (NSDate *) date;
- (BOOL) value;

@end


@interface GeniusAssociationDataPoint (GradePrediction)

+ (float) predictedValueWithDataPoints:(NSArray *)dataPoints;

+ (NSTimeInterval) timeIntervalForCount:(unsigned int)count;	// XXX: used by GeniusAssociationEnumerator

@end
