//
//  ParagraphStyleFormatter.m
//
//  Created by John R Chang on Thu Feb 05 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "ParagraphStyleFormatter.h"


@implementation ParagraphStyleFormatter

- (id) init
{
    self = [super init];
    _paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [self setLineBreakMode:NSLineBreakByTruncatingMiddle];
    return self;
}

- (void) dealloc
{
    [_paragraphStyle release];
    [super dealloc];
}

- (void)setLineBreakMode:(NSLineBreakMode)mode
{
    [_paragraphStyle setLineBreakMode:mode];
}

- (NSString *)stringForObjectValue:(id)anObject
{
    if ([anObject isKindOfClass:[NSString class]])
        return anObject;
    if ([anObject isKindOfClass:[NSURL class]])
        return [anObject absoluteString];
    return nil;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	*anObject = string;
	return YES;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
    NSString * string = [self stringForObjectValue:anObject];
    if (string == nil)
        return nil;
    NSMutableAttributedString * mutAttrString = [[[NSMutableAttributedString alloc] initWithString:string attributes:attributes] autorelease];
    NSRange range = NSMakeRange(0, [mutAttrString length]);
    [mutAttrString addAttribute:NSParagraphStyleAttributeName value:_paragraphStyle range:range];
    return (NSAttributedString *)mutAttrString;
}

@end
