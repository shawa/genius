//
//  ParagraphStyleFormatter.m
//
//  Created by John R Chang on Thu Feb 05 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "ParagraphStyleFormatter.h"


//! Combines a NSFormatter with an NSParagraphStyle to generate shortened text.
/*!
    Relies on a NSParagraphStyle to do the formatting.  The front and end text is displayed
    and the middle part is replaced with elipses.
    @todo check if there is a better way to do this.
*/
@implementation ParagraphStyleFormatter

//! Initializes #_paragraphStyle with NSLineBreakByTruncatingMiddle line break mode.
- (id) init
{
    self = [super init];
    _paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [self setLineBreakMode:NSLineBreakByTruncatingMiddle];
    return self;
}

//! Releases _paragraphStyle and deallocates memory
- (void) dealloc
{
    [_paragraphStyle release];
    [super dealloc];
}

//! Sets line break mode of #_paragraphStyle
- (void)setLineBreakMode:(NSLineBreakMode)mode
{
    [_paragraphStyle setLineBreakMode:mode];
}

//! Returns @a anObject formatted as a string.
/*!
    Returns nil if @a anObject is neither a NSString nor an NSURL.
*/
- (NSString *)stringForObjectValue:(id)anObject
{
    if ([anObject isKindOfClass:[NSString class]])
        return anObject;
    if ([anObject isKindOfClass:[NSURL class]])
        return [anObject absoluteString];
    return nil;
}

//! Returns @a string as @a anObject.
/*!
    An NSFormatter converts between object and string values for a text field.  In this case our 'object' is
    simply a string that we'd like to display shortened in the middle.  So no 'conversion' is actually done.
*/
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
	*anObject = string;
	return YES;
}

//! Uses our #_paragraphStyle to format longer strings.
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
