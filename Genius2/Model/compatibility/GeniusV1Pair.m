//
//  GeniusV1Pair.m
//  Genius
//
//  Created by John R Chang on Thu Nov 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GeniusV1Pair.h"


NSString * GeniusV1AssociationScoreNumberKey = @"scoreNumber";
NSString * GeniusV1AssociationDueDateKey = @"dueDate";

NSString * GeniusV1PairImportanceNumberKey = @"importanceNumber";
NSString * GeniusV1PairCustomTypeStringKey = @"customTypeString";
NSString * GeniusV1PairCustomGroupStringKey = @"customGroupString";
NSString * GeniusV1PairNotesStringKey = @"notesString";


@interface GeniusV1Association (Private)
- (id) _initWithCueItem:(GeniusV1Item *)cueItem answerItem:(GeniusV1Item *)answerItem parentPair:(GeniusV1Pair *)parentPair performanceDict:(NSDictionary *)performanceDict;
@end

@implementation GeniusV1Association

- (id) _initWithCueItem:(GeniusV1Item *)cueItem answerItem:(GeniusV1Item *)answerItem parentPair:(GeniusV1Pair *)parentPair performanceDict:(NSDictionary *)performanceDict
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

- (void) dealloc
{
    [_cueItem release];
    [_answerItem release];
    [_parentPair release];
    
    [_perfDict release];
    [super dealloc];
}


- (GeniusV1Item *) cueItem
{
    return _cueItem;
}

- (GeniusV1Item *) answerItem
{
    return _answerItem;
}

- (GeniusV1Pair *) parentPair
{
    return _parentPair;
}


- (NSDictionary *) performanceDictionary
{
    return _perfDict;
}

- (void) reset
{
    [self willChangeValueForKey:GeniusV1AssociationScoreNumberKey];
    [self willChangeValueForKey:GeniusV1AssociationDueDateKey];
    [_perfDict removeAllObjects];
    [self didChangeValueForKey:GeniusV1AssociationScoreNumberKey];
    [self didChangeValueForKey:GeniusV1AssociationDueDateKey];
}

// Resets the following fields
- (int) score
{
    NSNumber * scoreNumber = [self scoreNumber];
    if (scoreNumber == nil)
        return -1;
    else
        return [scoreNumber intValue];
}

- (void) setScore:(int)score
{
    NSNumber * scoreNumber;
    if (score == -1)
        scoreNumber = nil;
    else
        scoreNumber = [NSNumber numberWithInt:score];

    [self setScoreNumber:scoreNumber];
}

// Equivalent object-based methods used by key bindings
- (NSNumber *) scoreNumber
{
    id scoreNumber = [_perfDict objectForKey:GeniusV1AssociationScoreNumberKey];
    if ([scoreNumber isKindOfClass:[NSNumber class]])
        return scoreNumber;
    return nil;
}

- (void) setScoreNumber:(id)scoreObject
{
    // WORKAROUND: -initWithTabularText:order: passes us strings, so NSString -> NSNumber
    NSNumber * scoreNumber = scoreObject;
    if (scoreObject && [scoreObject isKindOfClass:[NSString class]] && [scoreObject isEqualToString:@""] == NO)
        scoreNumber = [NSNumber numberWithInt:[scoreObject intValue]];

    [_perfDict setValue:scoreNumber forKey:GeniusV1AssociationScoreNumberKey];
}

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

- (NSDate *) dueDate
{
    return [_perfDict objectForKey:GeniusV1AssociationDueDateKey];
}

- (void) setDueDate:(NSDate *)dueDate
{
    [_perfDict setValue:dueDate forKey:GeniusV1AssociationDueDateKey];
}


- (NSComparisonResult) compareByDate:(GeniusV1Association *)association
{
    NSDate * date1 = [self dueDate];
    NSDate * date2 = [association dueDate];
    if (date1 == nil)
        return NSOrderedAscending;  // 0 <
    if (date2 == nil)
        return NSOrderedDescending; // > 0
    return [date1 compare:date2];
}

- (NSComparisonResult) compareByScore:(GeniusV1Association *)association
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


const int kGeniusV1PairDisabledImportance = -1;
const int kGeniusV1PairMinimumImportance = 0;
const int kGeniusV1PairNormalImportance = 5;
const int kGeniusV1PairMaximumImportance = 10;

@interface GeniusV1Pair (Private)
- (id) _initWithCueItem:(GeniusV1Item *)cueItem answerItem:(GeniusV1Item *)answerItem;
@end

@implementation GeniusV1Pair

+ (NSArray *) associationsForPairs:(NSArray *)pairs useAB:(BOOL)useAB useBA:(BOOL)useBA
{
    NSMutableArray * allPairs = [NSMutableArray array];
    NSEnumerator * pairEnumerator = [pairs objectEnumerator];
    GeniusV1Pair * pair;
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


- (id) init
{
    self = [super init];

    GeniusV1Item * itemA = [GeniusV1Item new];
    GeniusV1Item * itemB = [GeniusV1Item new];
    _associationAB = [[GeniusV1Association alloc] _initWithCueItem:itemA answerItem:itemB parentPair:self performanceDict:nil];
    _associationBA = [[GeniusV1Association alloc] _initWithCueItem:itemB answerItem:itemA parentPair:self performanceDict:nil];
    [itemA release];
    [itemB release];
    _userDict = [NSMutableDictionary new];

    return self;
}

- (void) dealloc
{
    [_associationAB release];
    [_associationBA release];
    [_userDict release];

    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder
{
    NSAssert([coder allowsKeyedCoding], @"allowsKeyedCoding");
        
    self = [super init];
    GeniusV1Item * itemA = [coder decodeObjectForKey:@"itemA"];
    GeniusV1Item * itemB  = [coder decodeObjectForKey:@"itemB"];
    NSDictionary * performanceDictAB = [coder decodeObjectForKey:@"performanceDictAB"];
    NSDictionary * performanceDictBA = [coder decodeObjectForKey:@"performanceDictBA"];
    _associationAB = [[GeniusV1Association alloc] _initWithCueItem:itemA answerItem:itemB parentPair:self performanceDict:performanceDictAB];
    _associationBA = [[GeniusV1Association alloc] _initWithCueItem:itemB answerItem:itemA parentPair:self performanceDict:performanceDictBA];
    _userDict = [[coder decodeObjectForKey:@"userDict"] retain];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    NSAssert([coder allowsKeyedCoding], @"allowsKeyedCoding");

    [coder encodeObject:[self itemA] forKey:@"itemA"];
    [coder encodeObject:[self itemB] forKey:@"itemB"];
    [coder encodeObject:[_associationAB performanceDictionary] forKey:@"performanceDictAB"];
    [coder encodeObject:[_associationBA performanceDictionary] forKey:@"performanceDictBA"];
    [coder encodeObject:_userDict forKey:@"userDict"];
}

- (id) _initWithItemA:(GeniusV1Item *)itemA itemB:(GeniusV1Item *)itemB userDict:(NSMutableDictionary *)userDict
{
    self = [super init];
    _associationAB = [[GeniusV1Association alloc] _initWithCueItem:itemA answerItem:itemB parentPair:self performanceDict:nil];
    _associationBA = [[GeniusV1Association alloc] _initWithCueItem:itemB answerItem:itemA parentPair:self performanceDict:nil];
    _userDict = [userDict retain];

    return self;
}
- (id)copyWithZone:(NSZone *)zone
{
    GeniusV1Item * newItemA = [[[self itemA] copy] autorelease];
    GeniusV1Item * newItemB = [[[self itemB] copy] autorelease];
    NSMutableDictionary * newUserDict = [[_userDict mutableCopy] autorelease];
    return [[[self class] allocWithZone:zone] _initWithItemA:newItemA itemB:newItemB userDict:newUserDict];
}


- (NSString *) description
{
    return [NSString stringWithFormat:@"(%@, %@)", [[self itemA] description], [[self itemB] description]];
}


- (GeniusV1Item *) itemA
{
    return [[self associationAB] cueItem];
}

- (GeniusV1Item *) itemB
{
    return [[self associationBA] cueItem];
}

- (GeniusV1Association *) associationAB
{
    return _associationAB;
}

- (GeniusV1Association *) associationBA
{
    return _associationBA;
}


- (int) importance
{
    NSNumber * importanceNumber = [_userDict objectForKey:GeniusV1PairImportanceNumberKey];
    if (importanceNumber == nil)
        return kGeniusV1PairNormalImportance;
    return [importanceNumber intValue];
}

- (void) setImportance:(int)importance
{
    NSNumber * importanceNumber = [NSNumber numberWithInt:importance];
    [_userDict setObject:importanceNumber forKey:GeniusV1PairImportanceNumberKey];

//    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:GeniusV1PairFieldHasChanged object:GeniusV1PairImportanceNumberKey];
}


// Optional user-defined tags
- (NSString *) customGroupString
{
    return [_userDict objectForKey:GeniusV1PairCustomGroupStringKey];
}

- (void) setCustomGroupString:(NSString *)customGroup
{
    if (customGroup)
        [_userDict setObject:customGroup forKey:GeniusV1PairCustomGroupStringKey];
    else
        [_userDict removeObjectForKey:GeniusV1PairCustomGroupStringKey];

//    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:GeniusV1PairFieldHasChanged object:GeniusV1PairCustomGroupStringKey];
}

- (NSString *) customTypeString
{
    return [_userDict objectForKey:GeniusV1PairCustomTypeStringKey];
}

- (void) setCustomTypeString:(NSString *)customType
{
    if (customType)
        [_userDict setObject:customType forKey:GeniusV1PairCustomTypeStringKey];
    else
        [_userDict removeObjectForKey:GeniusV1PairCustomTypeStringKey];

//    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:GeniusV1PairFieldHasChanged object:GeniusV1PairCustomTypeStringKey];
}

- (NSString *) notesString
{
    return [_userDict objectForKey:GeniusV1PairNotesStringKey];
}

- (void) setNotesString:(NSString *)notesString
{
    if (notesString)
        [_userDict setObject:notesString forKey:GeniusV1PairNotesStringKey];
    else
        [_userDict removeObjectForKey:GeniusV1PairNotesStringKey];

//    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:GeniusV1PairFieldHasChanged object:GeniusV1PairNotesStringKey];
}

@end


@implementation GeniusV1Pair (GeniusV1DocumentAdditions)

- (BOOL) disabled
{
    return ([self importance] == kGeniusV1PairDisabledImportance);
}

- (void) setDisabled:(BOOL)disabled
{
    [self setImportance:(disabled ? kGeniusV1PairDisabledImportance : kGeniusV1PairNormalImportance)];
}

@end


@implementation GeniusV1Pair (TextImportExport)

+ (NSString *) tabularTextFromPairs:(NSArray *)pairs order:(NSArray *)keyPaths
{
    NSMutableString * outputString = [NSMutableString string];    
    NSEnumerator * pairEnumerator = [pairs objectEnumerator];
    GeniusV1Pair * pair;
    while ((pair = [pairEnumerator nextObject]))
        [outputString appendFormat:@"%@\n", [pair tabularTextByOrder:keyPaths]];
    return (NSString *)outputString;
}

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
        GeniusV1Pair * pair = [[GeniusV1Pair alloc] initWithTabularText:line order:keyPaths];
        [pairs addObject:pair];
        [pair release];
    }
    return (NSArray *)pairs;
}

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
