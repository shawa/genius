// 
//  GeniusAtom.m
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusAtom.h"
#import "GeniusItem.h"


@implementation GeniusAtom 

- (void)didChangeValueForKey:(NSString *)key
{
	if ([key isEqualToString:@"parentItem"] == NO)
	{
		GeniusItem * item = [self valueForKey:@"parentItem"];
		[item touchLastModifiedDate];
	}
	[super didChangeValueForKey:key];
}


- (void) setUsesRTFData:(BOOL)flag
{
	if (flag)
	{
		NSString * string = [self primitiveValueForKey:@"string"];
		if (string)
		{
			// string -> rtfData
			NSAttributedString * attrString = [[[NSAttributedString alloc] initWithString:string] autorelease];
			if (attrString)
			{
				NSRange range = NSMakeRange(0, [attrString length]);
				NSData * rtfData = [attrString RTFDFromRange:range documentAttributes:nil];

				[self willChangeValueForKey:@"rtfData"];
				[self setPrimitiveValue:rtfData forKey:@"rtfData"];
				[self didChangeValueForKey:@"rtfData"];
			}
		}
	}
	else
	{
		[self setPrimitiveValue:nil forKey:@"rtfData"];
	}
}


- (void) setString:(NSString *)string
{
	[self willChangeValueForKey:@"string"];
    [self setPrimitiveValue:string forKey:@"string"];
    [self didChangeValueForKey:@"string"];

    [self setPrimitiveValue:nil forKey:@"rtfData"];
}

/*- (NSData *) rtfData	// falls back to string
{
	[self willAccessValueForKey:@"rtfData"];
	NSData * rtfData = [self primitiveValueForKey:@"rtfData"];
	[self didAccessValueForKey:@"rtfData"];
	
	if (rtfData == nil)
	{
		NSString * string = [self primitiveValueForKey:@"string"];
		if (string)
		{
			// string -> rtfData
			NSAttributedString * attrString = [[[NSAttributedString alloc] initWithString:string] autorelease];
			if (attrString)
			{
				NSRange range = NSMakeRange(0, [attrString length]);
				rtfData = [attrString RTFDFromRange:range documentAttributes:nil];
			}
		}
	}
	
	return rtfData;
}*/

- (void) setRtfData:(NSData *)rtfData
{
	[self willChangeValueForKey:@"rtfData"];
    [self setPrimitiveValue:rtfData forKey:@"rtfData"];
    [self didChangeValueForKey:@"rtfData"];

	// rtfData -> string	
	NSAttributedString * attrString = [[NSAttributedString alloc] initWithRTFD:rtfData documentAttributes:nil];
	if (attrString)
	{
		NSString * string = [[attrString string] copy];
		[self willChangeValueForKey:@"string"];
		[self setPrimitiveValue:string forKey:@"string"];
		[self didChangeValueForKey:@"string"];
		[string release];
	}
}

@end
