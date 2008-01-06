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

//! registers an observer for the relevent fields of this object
- (void) addObserver: (id) observer
{
    [self addObserver:observer forKeyPath:@"stringValue" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:observer forKeyPath:@"imageURL" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:observer forKeyPath:@"webResourceURL" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:observer forKeyPath:@"speakableStringValue" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:observer forKeyPath:@"soundURL" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
}

//! un-registers an observer for the relevent fields of this object
- (void) removeObserver: (id) observer
{
    [self removeObserver:observer forKeyPath:@"stringValue"];
    [self removeObserver:observer forKeyPath:@"imageURL"];
    [self removeObserver:observer forKeyPath:@"webResourceURL"];
    [self removeObserver:observer forKeyPath:@"speakableStringValue"];
    [self removeObserver:observer forKeyPath:@"soundURL"];
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

//! _stringValue getter
- (NSString *) stringValue
{
    return _stringValue;
}

//! _imageURL getter
- (NSURL *) imageURL
{
    return _imageURL;
}

//! _webResourceURL getter
- (NSURL *) webResourceURL
{
    return _webResourceURL;
}

//! _speakableStringValue getter
- (NSString *) speakableStringValue
{
    return _speakableStringValue;
}

//! _soundURL getter
- (NSURL *) soundURL
{
    return _soundURL;
}

@end
