//
//  GeniusValueTransformers.m
//  Genius2
//
//  Created by John R Chang on 2005-09-26.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusValueTransformers.h"


@implementation GeniusFloatPercentTransformer

+ (Class) transformedValueClass
{
	return [NSNumber self];
}

+ (BOOL) allowsReverseTransformation
{
	return NO;
}

- (id) transformedValue:(id)value
{
	if (value == nil)
		return nil;
	float x = [value floatValue];
	x *= 100.0;
	return [NSNumber numberWithFloat:x];
}

@end
