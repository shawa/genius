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

#import "GeniusPair.h"


NSString * GeniusAssociationScoreNumberKey = @"scoreNumber"; //!< accessor key for score in _perfDict
NSString * GeniusAssociationDueDateKey = @"dueDate"; //!< accessor key for due date in _perfDict

NSString * GeniusPairImportanceNumberKey = @"importanceNumber";
NSString * GeniusPairCustomTypeStringKey = @"customTypeString";
NSString * GeniusPairCustomGroupStringKey = @"customGroupString";
NSString * GeniusPairNotesStringKey = @"notesString";


@interface GeniusAssociation (Private)
- (id) _initWithCueItem:(GeniusItem *)cueItem answerItem:(GeniusItem *)answerItem parentPair:(GeniusPair *)parentPair performanceDict:(NSDictionary *)performanceDict;
@end

@implementation GeniusAssociation

//! sets up dummy _dirty property as dependent property of other instance properties.
/*! @todo Track changes differently. */
+ (void)initialize
{
    [super initialize];
    [self setKeys:[NSArray arrayWithObjects:@"scoreNumber", @"dueDate", nil] triggerChangeNotificationsForDependentKey:@"dirty"];
}

/*+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    return NO;
}*/

//! Private initializer used by GeniusPair
/*! Creates copy of the provided @a performanceDict.
    @todo Check into why the performance dictionary is copied.
*/
- (id) _initWithCueItem:(GeniusItem *)cueItem answerItem:(GeniusItem *)answerItem parentPair:(GeniusPair *)parentPair performanceDict:(NSDictionary *)performanceDict
{
    self = [super init];
    _cueItem = [cueItem retain];
    _answerItem = [answerItem retain];
    _parentPair = [parentPair retain];
    
    if (performanceDict)
        _perfDict = [performanceDict mutableCopy];
    else
        _perfDict = [NSMutableDictionary new];
    return self;
}

//! Deallocates the memory occupied by the receiver after releasing ivars.
- (void) dealloc
{
    [_cueItem release];
    [_answerItem release];
    [_parentPair release];
    
    [_perfDict release];
    [super dealloc];
}

//! _cueItem getter
- (GeniusItem *) cueItem
{
    return _cueItem;
}

//! _answerItem getter
- (GeniusItem *) answerItem
{
    return _answerItem;
}

//! _parentPair getter
- (GeniusPair *) parentPair
{
    return _parentPair;
}

//! _perfDict getter
/*! @todo change variable name from @a _perfDict to @a _performanceData.  Or perhaps drop @a _perfData and add a dueDate and score ivar. */
- (NSDictionary *) performanceDictionary
{
    return _perfDict;
}

//! Resets all performance data. (ie scoreNumber and dueDate)
/*! Posts notifications for changing values @c GeniusAssociationScoreNumberKey and @c GeniusAssociationDueDateKey
and deletes all entries from _perfDict.
*/
- (void) reset
{
    [self willChangeValueForKey:GeniusAssociationScoreNumberKey];
    [self willChangeValueForKey:GeniusAssociationDueDateKey];
    [_perfDict removeAllObjects];
    [self didChangeValueForKey:GeniusAssociationScoreNumberKey];
    [self didChangeValueForKey:GeniusAssociationDueDateKey];
}

//! Convenience method for getting scoreNumber as an integer.
- (int) score
{
    NSNumber * scoreNumber = [self scoreNumber];
    if (scoreNumber == nil)
        return -1;
    else
        return [scoreNumber intValue];
}

//! Convenience method for setting scoreNumber as an integer.
- (void) setScore:(int)score
{
    NSNumber * scoreNumber;
    if (score == -1)
        scoreNumber = nil;
    else
        scoreNumber = [NSNumber numberWithInt:score];

    [self setScoreNumber:scoreNumber];
}

//! scoreNumber getter. Returns object in @a _perfDict for GeniusAssociationScoreNumberKey
- (NSNumber *) scoreNumber
{
    id scoreNumber = [_perfDict objectForKey:GeniusAssociationScoreNumberKey];
    if ([scoreNumber isKindOfClass:[NSNumber class]])
        return scoreNumber;
    return nil;
}

//! scoreNumber setter. Stores @a scoreObject in @a _perfDict under GeniusAssociationScoreNumberKey 
/*! Converts NSString to NSNumber.   Stores other objects as is. */
- (void) setScoreNumber:(id)scoreObject
{
    // WORKAROUND: -initWithTabularText:order: passes us strings, so NSString -> NSNumber
    NSNumber * scoreNumber = scoreObject;
    if (scoreObject && [scoreObject isKindOfClass:[NSString class]] && [scoreObject isEqualToString:@""] == NO)
        scoreNumber = [NSNumber numberWithInt:[scoreObject intValue]];

    [_perfDict setValue:scoreNumber forKey:GeniusAssociationScoreNumberKey];
}

//! @todo remove dead code
/*- (unsigned int) right
{
    NSNumber * rightNumber = [_perfDict objectForKey:@"right"];
    return (rightNumber ? [rightNumber unsignedIntValue] : 0);
}

- (void) setRight:(unsigned int)right
{
    [_perfDict setObject:[NSNumber numberWithUnsignedInt:right] forKey:@"right"];

    [self _setDirty];
}

- (unsigned int) wrong
{
    NSNumber * wrongNumber = [_perfDict objectForKey:@"wrong"];
    return (wrongNumber ? [wrongNumber unsignedIntValue] : 0);
}

- (void) setWrong:(unsigned int)wrong
{
    [_perfDict setObject:[NSNumber numberWithUnsignedInt:wrong] forKey:@"wrong"];

    [self _setDirty];
}*/

//! dueDate getter. Returns object in _perfDict for GeniusAssociationDueDateKey
- (NSDate *) dueDate
{
    return [_perfDict objectForKey:GeniusAssociationDueDateKey];
}

//! dueDate setter. Stores @p dueDate in _perfDict under GeniusAssociationDueDateKey 
- (void) setDueDate:(NSDate *)dueDate
{
    [_perfDict setValue:dueDate forKey:GeniusAssociationDueDateKey];
}

//! Compare to @a association based on @a dueDate.
/*! For comparison purposes a missing @a dueDate is treated the same as +[NSDate distantPast]. */
- (NSComparisonResult) compareByDate:(GeniusAssociation *)association
{
    NSDate * date1 = [self dueDate];
    NSDate * date2 = [association dueDate];
    if (date1 == nil)
        return NSOrderedAscending;  // 0 <
    if (date2 == nil)
        return NSOrderedDescending; // > 0
    return [date1 compare:date2];
}

//! Compare to @a association based on @a scoreNumber.
/*! For comparison purposes a missing @a scoreNumber is treated the same as the largest possible negative number. */
- (NSComparisonResult) compareByScore:(GeniusAssociation *)association
{
    NSNumber * scoreNumber1 = [self scoreNumber];
    NSNumber * scoreNumber2 = [association scoreNumber];
    if (scoreNumber1 == nil)
        return NSOrderedAscending;  // 0 <
    if (scoreNumber2 == nil)
        return NSOrderedDescending; // > 0
    return [scoreNumber1 compare:scoreNumber2];
}

@end


const int kGeniusPairDisabledImportance = -1;
const int kGeniusPairMinimumImportance = 0;
const int kGeniusPairNormalImportance = 5;
const int kGeniusPairMaximumImportance = 10;

@interface GeniusPair (Private)
//! @todo Determine if this is a private informal protocol or just leftover.
- (id) _initWithCueItem:(GeniusItem *)cueItem answerItem:(GeniusItem *)answerItem;
@end

@implementation GeniusPair

//! Set up @a importance and @a dirty as dependent properties.
+ (void)initialize
{
    [super initialize];
    [self setKeys:[NSArray arrayWithObjects:@"disabled", nil] triggerChangeNotificationsForDependentKey:@"importance"];
    [self setKeys:[NSArray arrayWithObjects:@"importance", @"customGroupString", @"customTypeString", @"notesString", nil] triggerChangeNotificationsForDependentKey:@"dirty"];
}

/*+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    return NO;
    if ([theKey isEqualToString:@"itemA"])
        return NO;
    else if ([theKey isEqualToString:@"itemB"])
        return NO;
    else
        return [super automaticallyNotifiesObserversForKey:theKey];
}*/

/*!
    Collects GeniusAssociations from the GeniusPair intances found in @a pairs into an array. 
    Excluded from the returned array are disabled items and items excluded by @a useAB and @a useBA
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
    This @a init method allocates two GeniusAssociation objects as well as the related two GeniusItem objects and connects
    them together.  The returned intance is setup as an observer of these four objects.  Specifically it watches for changes to
    their 'dirty' attribute in order to track changes.
    @todo Pick a designated initializer and organize the varous init methods as needed.
*/
- (id) init
{
    self = [super init];

    GeniusItem * itemA = [GeniusItem new];
    GeniusItem * itemB = [GeniusItem new];
    _associationAB = [[GeniusAssociation alloc] _initWithCueItem:itemA answerItem:itemB parentPair:self performanceDict:nil];
    _associationBA = [[GeniusAssociation alloc] _initWithCueItem:itemB answerItem:itemA parentPair:self performanceDict:nil];
    [itemA release];
    [itemB release];
    _userDict = [NSMutableDictionary new];

    [itemA addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [itemB addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [_associationAB addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [_associationBA addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];

    return self;
}

//! Deallocates the memory occupied by the receiver.
/*!
    Releases ivars and removes self as observer of the four objects created at initialization.
    @see init
*/
- (void) dealloc
{
    //! @todo seems like these should be released after we stop observing them
    [_associationAB release];
    [_associationBA release];
    [_userDict release];

    [[self itemA] removeObserver:self forKeyPath:@"dirty"];
    [[self itemB] removeObserver:self forKeyPath:@"dirty"];
    [_associationAB removeObserver:self forKeyPath:@"dirty"];
    [_associationBA removeObserver:self forKeyPath:@"dirty"];

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

    [itemA addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [itemB addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [_associationAB addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [_associationBA addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];

    return self;
}

//! Packs up instance with help of the provided coder.
/*! @exception NSInternalInconsistencyException when <tt>[coder allowsKeyedCoding]</tt> returns @p NO. */ 
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
- (id) _initWithItemA:(GeniusItem *)itemA itemB:(GeniusItem *)itemB userDict:(NSMutableDictionary *)userDict
{
    self = [super init];
    _associationAB = [[GeniusAssociation alloc] _initWithCueItem:itemA answerItem:itemB parentPair:self performanceDict:nil];
    _associationBA = [[GeniusAssociation alloc] _initWithCueItem:itemB answerItem:itemA parentPair:self performanceDict:nil];
    _userDict = [userDict retain];

    [itemA addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [itemB addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [_associationAB addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [_associationBA addObserver:self forKeyPath:@"dirty" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];

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
    return [[[self class] allocWithZone:zone] _initWithItemA:newItemA itemB:newItemB userDict:newUserDict];
}

//! Catches changes to observed instances of GeniusItem and GeniusAssociation.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"GeniusPair observeValueForKeyPath:%@", keyPath);
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"dirty"];
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

//! Convenience method for getting @a importanceNumber as @c int.
- (int) importance
{
    NSNumber * importanceNumber = [_userDict objectForKey:GeniusPairImportanceNumberKey];
    if (importanceNumber == nil)
        return kGeniusPairNormalImportance;
    return [importanceNumber intValue];
}

//! Convenience method for setting @a importanceNumber as @c int.
- (void) setImportance:(int)importance
{
    NSNumber * importanceNumber = [NSNumber numberWithInt:importance];
    [_userDict setObject:importanceNumber forKey:GeniusPairImportanceNumberKey];

//    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:GeniusPairFieldHasChanged object:GeniusPairImportanceNumberKey];
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

//    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:GeniusPairFieldHasChanged object:GeniusPairCustomGroupStringKey];
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

//    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:GeniusPairFieldHasChanged object:GeniusPairCustomTypeStringKey];
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

//    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:GeniusPairFieldHasChanged object:GeniusPairNotesStringKey];
}

@end


@implementation GeniusPair (GeniusDocumentAdditions)

//! Convenience method for evaluating importance.
/*! Compare importance to @c kGeniusPairDisabledImportance */
- (BOOL) disabled
{
    return ([self importance] == kGeniusPairDisabledImportance);
}

//! Convenience method for setting importance.
/*! Toggles @a importance between @a kGeniusPairDisabledImportance and @a kGeniusPairNormalImportance */
- (void) setDisabled:(BOOL)disabled
{
    [self setImportance:(disabled ? kGeniusPairDisabledImportance : kGeniusPairNormalImportance)];
}

@end


@implementation GeniusPair (TextImportExport)

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
    The resultant string only includes values for the requested keyPaths.
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
*/
+ (NSArray *) pairsFromTabularText:(NSString *)string order:(NSArray *)keyPaths;
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
    return (NSArray *)pairs;
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
