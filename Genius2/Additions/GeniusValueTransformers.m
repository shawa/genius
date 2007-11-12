//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusValueTransformers.h"


//! Value transformer for binding to percentages.
@implementation GeniusFloatPercentTransformer

//! we return an NSNumber.
+ (Class) transformedValueClass
{
	return [NSNumber self];
}

//! Not for handling user input.
+ (BOOL) allowsReverseTransformation
{
	return NO;
}

//! Multiply the original value by 100 for display.
- (id) transformedValue:(id)value
{
	if (value == nil)
		return nil;
	float x = [value floatValue];
	x *= 100.0;
	return [NSNumber numberWithFloat:x];
}

@end


@implementation GeniusImageStringTransformer

+ (Class) transformedValueClass
{
	return [NSString self];
}

+ (BOOL) allowsReverseTransformation
{
	return YES;
}

- (id) transformedValue:(id)value
{
	if (value == nil)
		return nil;
	
	unichar ch = 0xFFFC;	// Unicode object replacement character
	NSString * objectReplacementString = [NSString stringWithCharacters:&ch length:1];

	NSMutableString * tmpString = [value mutableCopy];
	NSString * imagePlaceholderString = NSLocalizedString(@"[Image]", nil);

	[tmpString replaceOccurrencesOfString:objectReplacementString withString:imagePlaceholderString options:nil range:NSMakeRange(0, [tmpString length])];
	return [tmpString autorelease];
}

@end


@implementation GeniusEnabledBooleanToTextColorTransformer

+ (Class) transformedValueClass
{
	return [NSColor self];
}

+ (BOOL) allowsReverseTransformation
{
	return NO;
}

- (id) transformedValue:(id)value
{
	if (value == nil)
		return nil;
	
	return ([value boolValue] ? [NSColor blackColor] : [NSColor grayColor]);
}

@end


//! standard binding value tranformer for diplaying boolean as "no" or "yes"
@implementation GeniusBooleanToStringTransformer

//! we return a string.
+ (Class) transformedValueClass
{
	return [NSString self];
}

//! for display only.
+ (BOOL) allowsReverseTransformation
{
	return NO;
}

//! If value can be converted to boolean, then return "YES" or "NO"
- (id) transformedValue:(id)value
{
	if (value == nil)
		return nil;
	
	return ([value boolValue] ? NSLocalizedString(@"YES", nil) : NSLocalizedString(@"NO", nil));
}

@end


@implementation GeniusFloatValueTransformer

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
	if (x == -1.0)
		return @"--";
	return [NSNumber numberWithFloat:x];
}

@end
