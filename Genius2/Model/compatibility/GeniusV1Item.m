//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusV1Item.h"


//! A GeniusItem models one or more representations of a memorizable atom of information.
/*! Example atoms of information include strings, images, web links, or sounds. A GeniusItem represents one of these atomic types of information. */
//! @todo Delete dead code. 
@implementation GeniusV1Item

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
    GeniusV1Item * newItem = [[[self class] allocWithZone:zone] init];
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
    [nc postNotificationName:GeniusV1DocumentHasChanged object:
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

/*- (void) setSoundURL:(NSURL *)soundURL
{
    [_soundURL release];
    _soundURL = [soundURL copy];

    [self _setDirty];
}*/

@end
