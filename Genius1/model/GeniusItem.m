//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusItem.h"


@implementation GeniusItem

+ (void)initialize
{
    [super initialize];
    [self setKeys:[NSArray arrayWithObjects:@"stringValue", @"imageURL", @"webResourceURL", @"speakableStringValue", @"soundURL", nil] triggerChangeNotificationsForDependentKey:@"dirty"];
}


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

- (void) dealloc
{
    [_stringValue release];
    [_imageURL release];
    [_webResourceURL release];
    [_speakableStringValue release];
    [_soundURL release];
    [super dealloc];
}

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

- (void)encodeWithCoder:(NSCoder *)coder
{
    NSAssert([coder allowsKeyedCoding], @"allowsKeyedCoding");

    if (_stringValue) [coder encodeObject:_stringValue forKey:@"stringValue"];
    if (_imageURL) [coder encodeObject:_imageURL forKey:@"imageURL"];
    if (_webResourceURL) [coder encodeObject:_webResourceURL forKey:@"webResourceURL"];
    if (_speakableStringValue) [coder encodeObject:_speakableStringValue forKey:@"speakableStringValue"];
    if (_soundURL) [coder encodeObject:_soundURL forKey:@"soundURL"];
}

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


// Visual
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


// Audio
- (NSString *) speakableStringValue
{
    return _speakableStringValue;
}

/*- (void) setSpeakableStringValue:(NSString *)speakableString
{
    [_dict setObject:speakableString forKey:@"speakableString"];

    [self _setDirty];
}*/

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
