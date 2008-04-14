//
//  ColorFromPairImportanceTransformer.m
//  Genius
//
//  Created by Chris Miner on 17.01.08.
//  Copyright 2008 Chris Miner. All rights reserved.
//

#import "ColorFromPairImportanceTransformer.h"
#import "GeniusPair.h"

//! NSValueTransformer for displaying importance as simple color value
@implementation ColorFromPairImportanceTransformer
//! We return an NSColor
+ (Class) transformedValueClass
{
    return [NSColor class];
}

//! Do not support writing the value back.
+ (BOOL)supportsReverseTransformation
{
    return NO;
}

//! Return red for max importance, gray for 'normal', and black for everything else.
- (id) transformedValue: (id) value
{
    int importance = [value intValue];
    
    if (importance == kGeniusPairMaximumImportance)
    {
        return [NSColor redColor];
    }    
    else if (importance < kGeniusPairNormalImportance)
    {
        return [NSColor darkGrayColor];
    }
    else {
        return [NSColor blackColor];
    }
}

@end
