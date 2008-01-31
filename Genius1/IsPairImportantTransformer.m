//
//  IsPairImportantTransformer.m
//  Genius
//
//  Created by Chris Miner on 17.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "IsPairImportantTransformer.h"
#import "GeniusPair.h"

//! A read only NSValueTransformer for displaying importance as simple boolean
@implementation IsPairImportantTransformer

//! We return an NSNumber.
+ (Class) transformedValueClass
{
    return [NSNumber class];
}

//! Don't support reverse transformation.
+ (BOOL)supportsReverseTransformation
{
    return NO;
}

//! Returns 1 for values greater than kGeniusPairNormalImportance.
- (id) transformedValue: (id) value
{
    int importance = [value intValue];
    
    return [NSNumber numberWithBool:(importance > kGeniusPairNormalImportance) ? YES : NO];
}

@end
