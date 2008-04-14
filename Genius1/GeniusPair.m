/*
	Genius
	Copyright (C) 2003-2006 John R Chang
	Copyright (C) 2007-2008 Chris Miner

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

#import "GeniusPair.h"
#import "GeniusAssociation.h"
#import "GeniusItem.h"

NSString * GeniusPairImportanceNumberKey = @"importanceNumber";
NSString * GeniusPairCustomTypeStringKey = @"customTypeString";
NSString * GeniusPairCustomGroupStringKey = @"customGroupString";
NSString * GeniusPairNotesStringKey = @"notesString";

//! The GeniusItem is not used.
const int kGeniusPairDisabledImportance = -1;
//! The GeniusItem is minimally relevant.
const int kGeniusPairMinimumImportance = 0;
//! The GeniusItem is averagely relevant.
const int kGeniusPairNormalImportance = 5;
//! The GeniusItem is maximally relevant.
const int kGeniusPairMaximumImportance = 10;

//! Relates two GeniusAssociation instances and some meta info.
/*!
A GeniusPair is conceptually like a two sided index card.  Through its two instances
 of GeniusAssociation it has access two two GeniusItem intances.  One for the 'front' of
 the card and one for the 'back'.  In addition a GeniusPair maintains information about
 the users classification of the card, such as importance, group, type, and notes.
 */
@implementation GeniusPair

//! Set up #importance as dependent properties.
+ (void)initialize
{
    [super initialize];
    [self setKeys:[NSArray arrayWithObjects:@"disabled", nil] triggerChangeNotificationsForDependentKey:@"importance"];
}

/*!
    Collects GeniusAssociations from the GeniusPair intances found in @a pairs into an array. 
    Excluded from the returned array are disabled items and items excluded by @a useAB and @a useBA.
*/
+ (NSArray *) associationsForPairs:(NSArray *)pairs useAB:(BOOL)useAB useBA:(BOOL)useBA
{
    NSMutableArray * allPairs = [NSMutableArray array];
    NSEnumerator * pairEnumerator = [pairs objectEnumerator];
    GeniusPair * pair;
    while ((pair = [pairEnumerator nextObject]))
    {
        if ([pair disabled])
            continue;
            
        if (useAB)
            [allPairs addObject:[pair associationAB]];
        if (useBA)
            [allPairs addObject:[pair associationBA]];
    }
    return allPairs;
}

//! Initializes new GeniusPair and allocates storage.
/*!
    This #init method allocates two GeniusItem objects and connects them together.
 */
- (id) init {
    self = [super init];
    if (self != nil) {
        GeniusItem * itemA = [[[GeniusItem alloc] init] autorelease];
        GeniusItem * itemB = [[[GeniusItem alloc] init] autorelease];
        [self initWithItemA:itemA itemB:itemB userDict:[NSMutableDictionary dictionary]];
    }
    return self;
}

//! Deallocates the memory occupied by the receiver.
/*!
    Releases ivars and removes self as observer of the four objects created at initialization.
    @see GeniusPair#init
*/
- (void) dealloc
{
    [_associationAB release];
    [_associationBA release];
    [_userDict release];
    [super dealloc];
}

//! Unpacks instance with help of the provided coder.
/*! @exception NSInternalInconsistencyException when <tt>[coder allowsKeyedCoding]</tt> returns @p NO. */ 
- (id)initWithCoder:(NSCoder *)coder
{
    NSAssert([coder allowsKeyedCoding], @"allowsKeyedCoding");
        
    self = [super init];
    GeniusItem * itemA = [coder decodeObjectForKey:@"itemA"];
    GeniusItem * itemB  = [coder decodeObjectForKey:@"itemB"];
    NSDictionary * performanceDictAB = [coder decodeObjectForKey:@"performanceDictAB"];
    NSDictionary * performanceDictBA = [coder decodeObjectForKey:@"performanceDictBA"];
    _associationAB = [[GeniusAssociation alloc] _initWithCueItem:itemA answerItem:itemB parentPair:self performanceDict:performanceDictAB];
    _associationBA = [[GeniusAssociation alloc] _initWithCueItem:itemB answerItem:itemA parentPair:self performanceDict:performanceDictBA];
    _userDict = [[coder decodeObjectForKey:@"userDict"] retain];

    return self;
}

//! Packs up instance with help of the provided coder.
/*!
    @exception NSInternalInconsistencyException when <tt>[coder allowsKeyedCoding]</tt> returns @p NO.
    Takes care to pack up the GeniusItem and the performance dictionaries of the GeniusAssociation objects.
 */ 
- (void)encodeWithCoder:(NSCoder *)coder
{
    NSAssert([coder allowsKeyedCoding], @"allowsKeyedCoding");

    [coder encodeObject:[self itemA] forKey:@"itemA"];
    [coder encodeObject:[self itemB] forKey:@"itemB"];
    [coder encodeObject:[_associationAB performanceDictionary] forKey:@"performanceDictAB"];
    [coder encodeObject:[_associationBA performanceDictionary] forKey:@"performanceDictBA"];
    [coder encodeObject:_userDict forKey:@"userDict"];
}

//! Convenience method used by <tt>copyWithZone:</tt>
/*!
    Intstanciates two instances of GeniusAssocation and connects them with @a itemA and @a itemB.  Retains the @a userDict
    which is expected to carry the 'card' realted group, importance, and type information.  Finally as is the case with @c init,
    self is set up as an observer of the two GeniusAssociation objects as well as @a itemA and @a itemB.
*/
- (id) initWithItemA:(GeniusItem *)itemA itemB:(GeniusItem *)itemB userDict:(NSMutableDictionary *)userDict
{
    self = [super init];
    _associationAB = [[GeniusAssociation alloc] _initWithCueItem:itemA answerItem:itemB parentPair:self performanceDict:nil];
    _associationBA = [[GeniusAssociation alloc] _initWithCueItem:itemB answerItem:itemA parentPair:self performanceDict:nil];
    _userDict = [userDict retain];
    return self;
}

//! returns a newly allocated mutable copy.
/*!
    The copy created here is not perfect.  The related GeniusItem objects are copied, but the GeniusAssociation objects
    are only partially duplicated.  Specifically the performance information such as score and due date are not copied.
    As such the returned GeniusPair copy has none of the history information related to the original
*/
- (id)copyWithZone:(NSZone *)zone
{
    GeniusItem * newItemA = [[[self itemA] copy] autorelease];
    GeniusItem * newItemB = [[[self itemB] copy] autorelease];
    NSMutableDictionary * newUserDict = [[_userDict mutableCopy] autorelease];
    return [[[self class] allocWithZone:zone] initWithItemA:newItemA itemB:newItemB userDict:newUserDict];
}

//! registers an observer for the relevent fields of this object
- (void) addObserver: (id) observer
{
    [self addObserver:observer forKeyPath:@"importance" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:observer forKeyPath:@"customGroupString" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:observer forKeyPath:@"customTypeString" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:observer forKeyPath:@"notesString" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [_associationAB addObserver:observer];
    [_associationBA addObserver:observer];
    [[self itemA] addObserver:observer];
    [[self itemB] addObserver:observer];
}

//! un-registers an observer for the relevent fields of this object
- (void) removeObserver: (id) observer
{
    [self removeObserver:observer forKeyPath:@"importance"];
    [self removeObserver:observer forKeyPath:@"customGroupString"];
    [self removeObserver:observer forKeyPath:@"customTypeString"];
    [self removeObserver:observer forKeyPath:@"notesString"];
    [_associationAB removeObserver:observer];
    [_associationBA removeObserver:observer];
    [[self itemA] removeObserver:observer];
    [[self itemB] removeObserver:observer];
}

//! Returns string with description of items.
- (NSString *) description
{
    return [NSString stringWithFormat:@"(%@, %@)", [[self itemA] description], [[self itemB] description]];
}

//! Convenience method for accessing the GeniusItem representing the 'front' of the card.
- (GeniusItem *) itemA
{
    return [[self associationAB] cueItem];
}

//! Convenience method for accessing the GeniusItem representing the 'back' of the card.
- (GeniusItem *) itemB
{
    return [[self associationBA] cueItem];
}

//! associationAB getter
- (GeniusAssociation *) associationAB
{
    return _associationAB;
}

//! associationBA getter
- (GeniusAssociation *) associationBA
{
    return _associationBA;
}

//! Convenience method for getting value for GeniusPairImportanceNumberKey from _userDict as @c int.
- (int) importance
{
    NSNumber * importanceNumber = [_userDict objectForKey:GeniusPairImportanceNumberKey];
    if (importanceNumber == nil)
        return kGeniusPairNormalImportance;
    return [importanceNumber intValue];
}

//! Convenience method for setting value for GeniusPairImportanceNumberKey in _userDict as @c int.
- (void) setImportance:(int)importance
{
    NSNumber * importanceNumber = [NSNumber numberWithInt:importance];
    [_userDict setObject:importanceNumber forKey:GeniusPairImportanceNumberKey];
}


//! customGroupString getter
/*! Optional user-defined tags */
- (NSString *) customGroupString
{
    return [_userDict objectForKey:GeniusPairCustomGroupStringKey];
}

//! customGroupString setter
- (void) setCustomGroupString:(NSString *)customGroup
{
    if (customGroup)
        [_userDict setObject:customGroup forKey:GeniusPairCustomGroupStringKey];
    else
        [_userDict removeObjectForKey:GeniusPairCustomGroupStringKey];
}

//! customTypeString getter
- (NSString *) customTypeString
{
    return [_userDict objectForKey:GeniusPairCustomTypeStringKey];
}

//! customTypeString setter
- (void) setCustomTypeString:(NSString *)customType
{
    if (customType)
        [_userDict setObject:customType forKey:GeniusPairCustomTypeStringKey];
    else
        [_userDict removeObjectForKey:GeniusPairCustomTypeStringKey];
}

//! notesString getter
- (NSString *) notesString
{
    return [_userDict objectForKey:GeniusPairNotesStringKey];
}

//! notesString setter
- (void) setNotesString:(NSString *)notesString
{
    if (notesString)
        [_userDict setObject:notesString forKey:GeniusPairNotesStringKey];
    else
        [_userDict removeObjectForKey:GeniusPairNotesStringKey];
}

@end

/*!
    @category GeniusPair(GeniusDocumentAdditions)
    @abstract Support for simply disabling and enabling a GeniusPair.
*/
@implementation GeniusPair(GeniusDocumentAdditions)

//! Convenience method for evaluating importance.
/*! Compare importance to @c kGeniusPairDisabledImportance */
- (BOOL) disabled
{
    return ([self importance] == kGeniusPairDisabledImportance);
}

//! Convenience method for setting importance.
/*! Toggles GeniusPair#importance between kGeniusPairDisabledImportance and kGeniusPairNormalImportance */
- (void) setDisabled:(BOOL)disabled
{
    [self setImportance:(disabled ? kGeniusPairDisabledImportance : kGeniusPairNormalImportance)];
}

@end

/*!
    @category GeniusPair(TextImportExport)
    @abstract Support related to copy / paste and drag & drop based on text.
 */
@implementation GeniusPair(TextImportExport)

//! Serialize an array of GeniusPair objects as delimited text
/*!
    Each entry is written out as a line of text.  see tabularTextByOrder:
*/
+ (NSString *) tabularTextFromPairs:(NSArray *)pairs order:(NSArray *)keyPaths
{
    NSMutableString * outputString = [NSMutableString string];    
    NSEnumerator * pairEnumerator = [pairs objectEnumerator];
    GeniusPair * pair;
    while ((pair = [pairEnumerator nextObject]))
        [outputString appendFormat:@"%@\n", [pair tabularTextByOrder:keyPaths]];
    return (NSString *)outputString;
}

//! Serialize as tab delimited string
/*!
    The resultant string only includes values for the requested keyPaths.  Used for both export
    and searching.
 */
- (NSString *) tabularTextByOrder:(NSArray *)keyPaths
{
    NSMutableString * outputString = [NSMutableString string];
    int i, count = [keyPaths count];
    for (i=0; i<count; i++)
    {
        NSString * keyPath = [keyPaths objectAtIndex:i];
        id value = [self valueForKeyPath:keyPath];
        if (value)
        {
            // Escape any embedded special characters
            NSMutableString * encodedString = [NSMutableString stringWithString:[value description]];
            [encodedString replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
            [encodedString replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
            [encodedString replaceOccurrencesOfString:@"\r" withString:@"\\n" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];

            [outputString appendString:encodedString];
        }
        if (i<count-1)
            [outputString appendString:@"\t"];
    }

    return outputString;
}


//! Convenience method to subdivide @a string into lines.
+ (NSArray *) _linesFromString:(NSString *)string
{
    NSMutableArray * lines = [NSMutableArray array];
    unsigned int startIndex, lineEndIndex, contentsEndIndex = 0;
    unsigned int length = [string length];
    NSRange range = NSMakeRange(0, 0);
    while (contentsEndIndex < length)
    {
        [string getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:range];
        unsigned int rangeLength = contentsEndIndex - startIndex;
        if (rangeLength > 0)    // don't include empty lines
        {
            NSString * line = [string substringWithRange:NSMakeRange(startIndex, rangeLength)];
            [lines addObject:line];
        }
        range.location = lineEndIndex;
    }
    return lines;
}

//! Generates an array of GeniusPair instances from a delimited string.
/*!
    The provided @a string is separated into lines based.  Each line is used to create a new GeniusPair
    instance that is initialized by the delimited line.
    @todo Maybe this code belongs in GeniusDocument(FileFormat)
 */
+ (NSMutableArray *) pairsFromTabularText:(NSString *)string order:(NSArray *)keyPaths
{
    //Can't use lines = [string componentsSeparatedByString:@"\n"];
    // because it doesn't handle carriage returns.
    NSArray * lines = [self _linesFromString:string];

    NSMutableArray * pairs = [NSMutableArray array];
    NSEnumerator * lineEnumerator = [lines objectEnumerator];
    NSString * line;
    while ((line = [lineEnumerator nextObject]))
    {
        GeniusPair * pair = [[GeniusPair alloc] initWithTabularText:line order:keyPaths];
        [pairs addObject:pair];
        [pair release];
    }
    return pairs;
}

//! Initializes a GeniusPair from a tab delimited string.
/*!
    The provided @a line is separated into values which are interpreted based on the values provided in
    @a keyPaths.  They should have the same number of entries, but when that isn't the extra keys or values
    are ignored.  Values are stripped of tabs and newlines.
 */
- (id) initWithTabularText:(NSString *)line order:(NSArray *)keyPaths
{
    self = [self init];

    NSArray * fields = [line componentsSeparatedByString:@"\t"];
    int i, count=MIN([fields count], [keyPaths count]);
    for (i=0; i<count; i++)
    {
        NSString * field = [fields objectAtIndex:i];
        NSString * keyPath = [keyPaths objectAtIndex:i];

        // Unescape any embedded special characters
        NSMutableString * decodedString = [NSMutableString stringWithString:field];
        [decodedString replaceOccurrencesOfString:@"\\t" withString:@"\t" options:NSLiteralSearch range:NSMakeRange(0, [decodedString length])];
        [decodedString replaceOccurrencesOfString:@"\\n" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [decodedString length])];

        [self setValue:decodedString forKeyPath:keyPath];
    }
    
    return self;
}

@end
