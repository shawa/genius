//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

#import "GeniusAtom.h"


//NSString * GeniusAtomNameKey = @"name";

NSString * GeniusAtomStringKey = @"string";
NSString * GeniusAtomRTFDDataKey = @"rtfdData";
NSString * GeniusAtomStringRTDDataKey = @"stringRTFDData";


@implementation GeniusAtom 

#pragma mark <NSCopying>

+ (NSArray *)copyKeys {
    static NSArray *copyKeys = nil;
    if (copyKeys == nil) {
        copyKeys = [[NSArray alloc] initWithObjects:
            GeniusAtomStringKey, GeniusAtomRTFDDataKey, nil];
    }
    return copyKeys;
}

- (NSDictionary *)dictionaryRepresentation
{
    return [self dictionaryWithValuesForKeys:[[self class] copyKeys]];
}

- (id)copyWithZone:(NSZone *)zone
{
	NSManagedObjectContext * context = [self managedObjectContext];
	GeniusAtom * newObject = [[[self class] allocWithZone:zone] initWithEntity:[self entity] insertIntoManagedObjectContext:context];
	[newObject setValuesForKeysWithDictionary:[self dictionaryRepresentation]];
    return newObject;
}


#pragma mark -

+ (NSSet *)_userModifiableKeySet {
    static NSSet *userModifiableKeySet = nil;
    if (userModifiableKeySet == nil) {
        userModifiableKeySet = [[NSSet alloc] initWithObjects:
            GeniusAtomStringKey, GeniusAtomStringRTDDataKey, nil];
    }
    return userModifiableKeySet;
}

- (void)didChangeValueForKey:(NSString *)key
{
	if ([[GeniusAtom _userModifiableKeySet] containsObject:key])
	{
		if (_delegate && [_delegate respondsToSelector:@selector(atomHasChanged:)])
			[_delegate atomHasChanged:self];
	}
	
	[super didChangeValueForKey:key];
}


#pragma mark -

+ (NSDictionary *) defaultTextAttributes
{
	static NSDictionary * sDefaultAttribs = nil;
	if (sDefaultAttribs == nil)
	{
		NSMutableParagraphStyle * parStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[parStyle setAlignment:NSCenterTextAlignment];

		sDefaultAttribs = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:24.0], NSFontAttributeName,
/*			[NSColor blackColor], NSForegroundColorAttributeName,*/
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


#pragma mark -

- (void) setString:(NSString *)string
{
	[self willChangeValueForKey:GeniusAtomStringKey];
	[self setPrimitiveValue:string forKey:GeniusAtomStringKey];
	[self didChangeValueForKey:GeniusAtomStringKey];

	[self willChangeValueForKey:GeniusAtomStringRTDDataKey];
	[self didChangeValueForKey:GeniusAtomStringRTDDataKey];
}

- (void) setStringRTFDData:(NSData *)rtfdData
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
	
	//NSLog(@"string=%X, rtfdData=%X", string, rtfdData);

	[self willChangeValueForKey:GeniusAtomRTFDDataKey];
	[self setPrimitiveValue:rtfdData forKey:GeniusAtomRTFDDataKey];
	[self didChangeValueForKey:GeniusAtomRTFDDataKey];
	
	[self willChangeValueForKey:GeniusAtomStringKey];
	[self setPrimitiveValue:string forKey:GeniusAtomStringKey];
	[self didChangeValueForKey:GeniusAtomStringKey];

	[self willChangeValueForKey:GeniusAtomStringRTDDataKey];
	[self didChangeValueForKey:GeniusAtomStringRTDDataKey];
}


- (NSData *) stringRTFDData	// falls back to string
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


- (void) setDelegate:(id)delegate
{
	_delegate = delegate;
}

@end
