/*
	Genius
	Copyright (C) 2003-2006 John R Chang

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.	

	http://www.gnu.org/licenses/gpl.txt
*/

#import "GeniusItem.h"


@implementation GeniusItem

//! sets up dummy _dirty property as dependent property of other instance properties.
/*! @todo Track changes differently. */
+ (void)initialize
{
    [super initialize];
    [self setKeys:[NSArray arrayWithObjects:@"stringValue", @"imageURL", @"webResourceURL", @"speakableStringValue", @"soundURL", nil] triggerChangeNotificationsForDependentKey:@"dirty"];
}

//! Initializes new instance with all properties set to nil.
/*! @todo Remove code that sets everything to nil because it isn't needed. */
- (id) init
{
    self = [super init];
    _stringValue = nil;
    _imageURL = nil;
    _webResourceURL = nil;
    _speakableStringValue = nil;
    _soundURL = nil;
    return self;
}

//! Releases instance vars and deallocates instance.
- (void) dealloc
{
    [_stringValue release];
    [_imageURL release];
    [_webResourceURL release];
    [_speakableStringValue release];
    [_soundURL release];
    [super dealloc];
}

//! Creates and returns a copy of this instance in the new zone.
/*! @todo Replace calls to @c copy with @c copyWithZone: for the instance variables. */
- (id)copyWithZone:(NSZone *)zone
{
    GeniusItem * newItem = [[[self class] allocWithZone:zone] init];
    newItem->_stringValue = [_stringValue copy];
    newItem->_imageURL = [_imageURL copy];
    newItem->_webResourceURL = [_webResourceURL copy];
    newItem->_speakableStringValue = [_speakableStringValue copy];
    newItem->_soundURL = [_soundURL copy];
    return newItem;
}

//! Unpacks instance with help of the provided coder.
/*! @exception NSInternalInconsistencyException when <tt>[coder allowsKeyedCoding]</tt> returns @p NO. */ 
- (id)initWithCoder:(NSCoder *)coder
{
    NSAssert([coder allowsKeyedCoding], @"allowsKeyedCoding");

    self = [super init];
    _stringValue = [[coder decodeObjectForKey:@"stringValue"] retain];
    _imageURL = [[coder decodeObjectForKey:@"imageURL"] retain];
    _webResourceURL = [[coder decodeObjectForKey:@"webResourceURL"] retain];
    _speakableStringValue = [[coder decodeObjectForKey:@"speakableStringValue"] retain];
    _soundURL = [[coder decodeObjectForKey:@"soundURL"] retain];
    return self;
}

//! Packs up instance with help of the provided coder.
/*! @exception NSInternalInconsistencyException when <tt>[coder allowsKeyedCoding]</tt> returns @p NO. */ 
- (void)encodeWithCoder:(NSCoder *)coder
{
    NSAssert([coder allowsKeyedCoding], @"allowsKeyedCoding");

    if (_stringValue) [coder encodeObject:_stringValue forKey:@"stringValue"];
    if (_imageURL) [coder encodeObject:_imageURL forKey:@"imageURL"];
    if (_webResourceURL) [coder encodeObject:_webResourceURL forKey:@"webResourceURL"];
    if (_speakableStringValue) [coder encodeObject:_speakableStringValue forKey:@"speakableStringValue"];
    if (_soundURL) [coder encodeObject:_soundURL forKey:@"soundURL"];
}

//! Same as calling @c stringValue
- (NSString *) description
{
    return [self stringValue];
}

/*- (void) _setDirty
{
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:GeniusDocumentHasChanged object:
        [[NSDocumentController sharedDocumentController] currentDocument]]; // HACK
}*/


//! _stringValue getter
- (NSString *) stringValue
{
    return _stringValue;
}

/*- (void) setStringValue:(NSString *)string
{
    [_stringValue release];
    _stringValue = [string copy];

    [self _setDirty];
}*/

//! _imageURL getter
- (NSURL *) imageURL
{
    return _imageURL;
}

/*- (void) setImageURL:(NSURL *)imageURL
{
    [_imageURL release];
    _imageURL = [imageURL copy];

    [self _setDirty];
}*/


//! _webResourceURL getter
- (NSURL *) webResourceURL
{
    return _webResourceURL;
}

//! @todo dead code
/*- (void) setWebResourceURL:(NSURL *)webResourceURL
{
    [_webResourceURL release];
    _webResourceURL = [webResourceURL copy];

    [self _setDirty];
}*/


//! _speakableStringValue getter
- (NSString *) speakableStringValue
{
    return _speakableStringValue;
}

//! @todo dead code
/*- (void) setSpeakableStringValue:(NSString *)speakableString
{
    [_dict setObject:speakableString forKey:@"speakableString"];

    [self _setDirty];
}*/

//! _soundURL getter
- (NSURL *) soundURL
{
    return _soundURL;
}

//! @todo dead code
/*- (void) setSoundURL:(NSURL *)soundURL
{
    [_soundURL release];
    _soundURL = [soundURL copy];

    [self _setDirty];
}*/

@end
