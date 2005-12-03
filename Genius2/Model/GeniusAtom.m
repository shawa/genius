// 
//  GeniusAtom.m
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAtom.h"
#import "GeniusItem.h"


static NSString * GeniusAtomParentItemKey = @"parentItem";

NSString * GeniusAtomStringKey = @"string";
NSString * GeniusAtomRTFDDataKey = @"rtfdData";


@implementation GeniusAtom 

- (void)didChangeValueForKey:(NSString *)key
{
	if ([key isEqualToString:GeniusAtomParentItemKey] == NO)
	{
		GeniusItem * item = [self valueForKey:GeniusAtomParentItemKey];
		[item touchLastModifiedDate];
	}
	[super didChangeValueForKey:key];
}


+ (NSDictionary *) defaultTextAttributes
{
	static NSDictionary * sDefaultAttribs = nil;
	if (sDefaultAttribs == nil)
	{
		NSMutableParagraphStyle * parStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[parStyle setAlignment:NSCenterTextAlignment];

		sDefaultAttribs = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:24.0], NSFontAttributeName,
			parStyle, NSParagraphStyleAttributeName,
			NULL];

		[parStyle release];
	}
	return sDefaultAttribs;
}

+ (BOOL) _isDefaultTextAttributes:(NSDictionary *)attributes
{
	if (attributes == nil)
		return YES;
	if ([attributes count] == 0)
		return YES;
	if ([attributes count] > [[self defaultTextAttributes] count])
		return NO;

	NSEnumerator * keyEnumerator = [attributes keyEnumerator];
	NSString * key;
	while ((key = [keyEnumerator nextObject]))
	{
		id defaultValue = [[self defaultTextAttributes] objectForKey:key];
		if (defaultValue == nil)
			return NO;

		id value = [attributes objectForKey:key];
		if ([defaultValue isEqual:value] == NO)
			return NO;
	}
	return YES;
}

+ (BOOL) _attributedStringUsesDefaultTextAttributes:(NSAttributedString *)attrString
{
	if ([attrString length] > 0)
	{
		NSRange fullRange = NSMakeRange(0, [attrString length]);
		NSRange effectiveRange;
		NSDictionary * attribs = [attrString attributesAtIndex:0 longestEffectiveRange:&effectiveRange inRange:fullRange];
		if ([GeniusAtom _isDefaultTextAttributes:attribs] == NO)
			return NO;

		if (NSEqualRanges(fullRange, effectiveRange) == NO)
			return NO;
	}
	
	return YES;
}

- (BOOL) usesDefaultTextAttributes
{
	NSData * rtfdData = [self primitiveValueForKey:GeniusAtomRTFDDataKey];
	return (rtfdData == nil);
}

- (void)clearTextAttributes
{
	[self willChangeValueForKey:GeniusAtomRTFDDataKey];
	[self setPrimitiveValue:nil forKey:GeniusAtomRTFDDataKey];
	[self didChangeValueForKey:GeniusAtomRTFDDataKey];
}


- (void) setRtfdData:(NSData *)rtfdData
{
//	_isImageOnly = NO;

	// rtfdData -> attrString
	NSString * string = nil;
	NSAttributedString * attrString = [[NSAttributedString alloc] initWithRTFD:rtfdData documentAttributes:nil];
	if (attrString)
	{
		// attrString -> string
		string = [attrString string];
		
		// It's plain text
		if ([GeniusAtom _attributedStringUsesDefaultTextAttributes:attrString])
			rtfdData = nil;
	}
	
	NSLog(@"string=%X, rtfdData=%X", string, rtfdData);

	[self willChangeValueForKey:GeniusAtomRTFDDataKey];
	[self setPrimitiveValue:rtfdData forKey:GeniusAtomRTFDDataKey];
	[self didChangeValueForKey:GeniusAtomRTFDDataKey];
	
	[self willChangeValueForKey:GeniusAtomStringKey];
	[self setPrimitiveValue:string forKey:GeniusAtomStringKey];
	[self didChangeValueForKey:GeniusAtomStringKey];
}


- (NSData *) rtfdData	// falls back to string
{
	[self willAccessValueForKey:GeniusAtomRTFDDataKey];
	NSData * rtfdData = [self primitiveValueForKey:GeniusAtomRTFDDataKey];	
	if (rtfdData == nil)
	{
		NSString * string = [self primitiveValueForKey:GeniusAtomStringKey];
		if (string)
		{
			// string -> rtfdData
			NSAttributedString * attrString = [[[NSAttributedString alloc] initWithString:string attributes:[GeniusAtom defaultTextAttributes]] autorelease];
			if (attrString)
			{
				NSRange range = NSMakeRange(0, [attrString length]);
				rtfdData = [attrString RTFDFromRange:range documentAttributes:nil];
			}
		}
	}
	[self didAccessValueForKey:GeniusAtomRTFDDataKey];
	return rtfdData;
}

@end
