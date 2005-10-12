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


- (void) setUsesRTFDData:(BOOL)flag
{
	if (flag)
	{
		NSString * string = [self primitiveValueForKey:GeniusAtomStringKey];
		if (string)
		{
			// string -> rtfdData
			NSAttributedString * attrString = [[[NSAttributedString alloc] initWithString:string] autorelease];
			if (attrString)
			{
				NSRange range = NSMakeRange(0, [attrString length]);
				NSData * rtfdData = [attrString RTFDFromRange:range documentAttributes:nil];

				[self willChangeValueForKey:GeniusAtomRTFDDataKey];
				[self setPrimitiveValue:rtfdData forKey:GeniusAtomRTFDDataKey];
				[self didChangeValueForKey:GeniusAtomRTFDDataKey];
			}
		}
	}
	else
	{
		[self setPrimitiveValue:nil forKey:GeniusAtomRTFDDataKey];
	}
}


- (void) setString:(NSString *)string
{
	[self willChangeValueForKey:GeniusAtomStringKey];
    [self setPrimitiveValue:string forKey:GeniusAtomStringKey];
    [self didChangeValueForKey:GeniusAtomStringKey];

    [self setPrimitiveValue:nil forKey:GeniusAtomRTFDDataKey];
}

/*- (NSData *) rtfdData	// falls back to string
{
	[self willAccessValueForKey:GeniusAtomRTFDDataKey];
	NSData * rtfdData = [self primitiveValueForKey:GeniusAtomRTFDDataKey];
	[self didAccessValueForKey:GeniusAtomRTFDDataKey];
	
	if (rtfdData == nil)
	{
		NSString * string = [self primitiveValueForKey:GeniusAtomStringKey];
		if (string)
		{
			// string -> rtfdData
			NSAttributedString * attrString = [[[NSAttributedString alloc] initWithString:string] autorelease];
			if (attrString)
			{
				NSRange range = NSMakeRange(0, [attrString length]);
				rtfdData = [attrString RTFDFromRange:range documentAttributes:nil];
			}
		}
	}
	
	return rtfdData;
}*/

- (void) setRtfdData:(NSData *)rtfdData
{
	[self willChangeValueForKey:GeniusAtomRTFDDataKey];
    [self setPrimitiveValue:rtfdData forKey:GeniusAtomRTFDDataKey];
    [self didChangeValueForKey:GeniusAtomRTFDDataKey];

	// rtfdData -> string	
	NSAttributedString * attrString = [[NSAttributedString alloc] initWithRTFD:rtfdData documentAttributes:nil];
	if (attrString)
	{
		NSString * string = [[attrString string] copy];
		[self willChangeValueForKey:GeniusAtomStringKey];
		[self setPrimitiveValue:string forKey:GeniusAtomStringKey];
		[self didChangeValueForKey:GeniusAtomStringKey];
		[string release];
	}
}

@end
