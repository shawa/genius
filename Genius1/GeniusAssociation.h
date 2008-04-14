//
//  GeniusAssociation.h
//  Genius
//
//  Created by Chris Miner on 12.11.07.
//  Copyright 2007 Chris Miner. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GeniusItem;
@class GeniusPair;

//! A directed association between two GeniusItem instances, with score-keeping data.
/*!
A GeniusAssociation is the basic unit of memorization in Genius.  A GeniusAssociation instance
 represents a directional relationship between a que and an answer.  If que and answer are reversed,
 a new GeniusAssociation is needed.  This is important for scoreing and due date calculations which
 are dependent on the user recalling the correct answer given a particular cue.
 
 Never create directly; always create through GeniusPair.
 */
@interface GeniusAssociation : NSObject {
    GeniusItem * _cueItem; //!< Item acting as question or prompt.
    GeniusItem * _answerItem;  //!< Item expected as response to the que.
    GeniusPair * _parentPair; //!< The GeniusPair to which this GeniusAssociation belongs.
    
    //! performance info dictionary
    /*! contains scoreNumber and dueDate for this GeniusAssociation. */
    NSMutableDictionary * _perfDict;
}

- (id) _initWithCueItem:(GeniusItem *)cueItem answerItem:(GeniusItem *)answerItem parentPair:(GeniusPair *)parentPair performanceDict:(NSDictionary *)performanceDict;

- (void) addObserver: (id) observer;
- (void) removeObserver: (id) observer;

- (GeniusItem *) cueItem;
- (GeniusItem *) answerItem;
- (GeniusPair *) parentPair;
- (NSDictionary *) performanceDictionary;

- (void) reset;

- (int) score;
- (void) setScore:(int)score;

    // Equivalent object-based methods used by key bindings. 
- (NSNumber *) scoreNumber;
- (void) setScoreNumber:(id)scoreNumber;

- (BOOL) isFirstTime;

- (NSDate *) dueDate;
- (void) setDueDate:(NSDate *)dueDate;

@end
