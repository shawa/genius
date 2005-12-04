//
//  IntegerFormatter.m
//  Genius2
//
//  Created by John R Chang on 2005-12-04.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "IntegerFormatter.h"


@implementation IntegerFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    return [anObject stringValue];
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	int intValue = [string intValue];
	if (intValue == 0)
		return NO;
	
	*anObject = [NSNumber numberWithInt:intValue];
	return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error
{
	*newString = nil;

	unichar c;
	int i, length = [partialString length];
	NSCharacterSet * charSet = [NSCharacterSet decimalDigitCharacterSet];
	for (i=0; i<length; i++)
	{
		c = [partialString characterAtIndex:i];
		if ([charSet characterIsMember:c] == NO)
		{
			NSBeep();
			return NO;
		}
	}
	
	return YES;
}

@end
