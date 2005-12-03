//
//  ImageStringFormatter.m
//  Genius2
//
//  Created by John R Chang on 2005-12-03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ImageStringFormatter.h"


@implementation ImageStringFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass:[NSString class]]) {
        return nil;
    }
	
	unichar ch = 0xFFFC;	// Unicode object replacement character
	NSString * objectReplacementString = [NSString stringWithCharacters:&ch length:1];

	NSMutableString * tmpString = [anObject mutableCopy];
	NSString * imagePlaceholderString = NSLocalizedString(@"[Image]", nil);

	[tmpString replaceOccurrencesOfString:objectReplacementString withString:imagePlaceholderString options:nil range:NSMakeRange(0, [tmpString length])];
	return [tmpString autorelease];
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	*anObject = string;
	return YES;
}

@end
