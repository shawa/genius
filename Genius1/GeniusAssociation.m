//
//  GeniusAssociation.m
//  Genius
//
//  Created by Chris Miner on 12.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GeniusAssociation.h"
#import "GeniusPair.h"

NSString * GeniusAssociationScoreNumberKey = @"scoreNumber"; //!< accessor key for score in _perfDict
NSString * GeniusAssociationDueDateKey = @"dueDate"; //!< accessor key for due date in _perfDict

@implementation GeniusAssociation
/*! 
Creates copy of the provided @a performanceDict.
*/
- (id) _initWithCueItem:(GeniusItem *)cueItem answerItem:(GeniusItem *)answerItem parentPair:(GeniusPair *)parentPair performanceDict:(NSDictionary *)performanceDict
{
    self = [super init];
    _cueItem = [cueItem retain];
    _answerItem = [answerItem retain];
    _parentPair = parentPair;           // not retained since we're the dependent entity
    
    if (performanceDict)
        _perfDict = [performanceDict mutableCopy];
    else
        _perfDict = [[NSMutableDictionary alloc] init];
    return self;
}

/*+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    return NO;
}*/

//! Deallocates the memory occupied by the receiver after releasing ivars.
- (void) dealloc
{
    [_cueItem release];
    [_answerItem release];
    [_perfDict release];
    [super dealloc];
}

//! registers an observer for the relevent fields of this object
- (void) addObserver: (id) observer
{
    [self addObserver:observer forKeyPath:@"scoreNumber" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self addObserver:observer forKeyPath:@"dueDate" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
}

//! un-registers an observer for the relevent fields of this object
- (void) removeObserver: (id) observer
{
    [self removeObserver:observer forKeyPath:@"scoreNumber"];
    [self removeObserver:observer forKeyPath:@"dueDate"];
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
/*!
@todo change variable name from GeniusAssociation#_perfDict to @c _performanceData.
 Or perhaps drop GeniusAssociation#_perfDict and add a @c dueDate and @c score ivar.
 */
- (NSDictionary *) performanceDictionary
{
    return _perfDict;
}

//! Resets all performance data. (ie scoreNumber and dueDate)
/*! 
Posts notifications for changing values @c GeniusAssociationScoreNumberKey and @c GeniusAssociationDueDateKey
and deletes all entries from GeniusAssociation#_perfDict.
*/
- (void) reset
{
    [self willChangeValueForKey:GeniusAssociationScoreNumberKey];
    [self willChangeValueForKey:GeniusAssociationDueDateKey];
    [_perfDict removeAllObjects];
    [self didChangeValueForKey:GeniusAssociationDueDateKey];
    [self didChangeValueForKey:GeniusAssociationScoreNumberKey];
}

//! Convenience method for getting GeniusAssociation#scoreNumber as an integer.
/*! -1 means never been quizzed. */
- (int) score
{
    NSNumber * scoreNumber = [self scoreNumber];
    if (scoreNumber == nil)
        return -1;
    else
        return [scoreNumber intValue];
}

//! Convenience method for setting #scoreNumber as an integer.
- (void) setScore:(int)score
{
    NSNumber * scoreNumber;
    if (score == -1)
        scoreNumber = nil;
    else
        scoreNumber = [NSNumber numberWithInt:score];
    
    [self setScoreNumber:scoreNumber];
}

//! First time items have no scoreNumber.
- (BOOL) isFirstTime
{
    return ([self scoreNumber] == nil);
}

//! scoreNumber getter. Returns object in GeniusAssociation#_perfDict for GeniusAssociationScoreNumberKey
/*! @todo Remove one of score or scoreNumber and friends. */
- (NSNumber *) scoreNumber
{
    id scoreNumber = [_perfDict objectForKey:GeniusAssociationScoreNumberKey];
    if ([scoreNumber isKindOfClass:[NSNumber class]])
        return scoreNumber;
    return nil;
}

//! scoreNumber setter. Stores @a scoreObject in GeniusAssociation#_perfDict under GeniusAssociationScoreNumberKey 
/*! Converts NSString to NSNumber.   Stores other objects as is. */
- (void) setScoreNumber:(id)scoreObject
{
    // WORKAROUND: -initWithTabularText:order: passes us strings, so NSString -> NSNumber
    NSNumber * scoreNumber = scoreObject;
    if (scoreObject && [scoreObject isKindOfClass:[NSString class]] && [scoreObject isEqualToString:@""] == NO)
        scoreNumber = [NSNumber numberWithInt:[scoreObject intValue]];
    
    [_perfDict setValue:scoreNumber forKey:GeniusAssociationScoreNumberKey];
}

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

//! Compare to @a association based on #dueDate.
/*! For comparison purposes a missing #dueDate is treated the same as +[NSDate distantPast]. */
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

//! Compare to @a association based on #scoreNumber.
/*! For comparison purposes a missing #scoreNumber is treated the same as the largest possible negative number. */
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
