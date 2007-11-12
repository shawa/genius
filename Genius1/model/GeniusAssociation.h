//
//  GeniusAssociation.h
//  Genius
//
//  Created by Chris Miner on 12.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
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
 
 @todo Create standalone GeniusAssociation.[h,m] files.
 */
@interface GeniusAssociation : NSObject {
    GeniusItem * _cueItem; //!< Item acting as question or prompt.
    GeniusItem * _answerItem;  //!< Item expected as response to the que.
    GeniusPair * _parentPair; //!< The GeniusPair to which this GeniusAssociation belongs.
    
    //! performance info dictionary
    /*! contains scoreNumber and dueDate for this GeniusAssociation. */
    NSMutableDictionary * _perfDict;
    
    // Transient
    BOOL _dirty;    //!< dummy property to ensure key value compliance for the key dirty
}

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

    //! @todo dead code.
    /*- (unsigned int) right;
- (void) setRight:(unsigned int)right;

- (unsigned int) wrong;
- (void) setWrong:(unsigned int)wrong;*/

- (NSDate *) dueDate;
- (void) setDueDate:(NSDate *)dueDate;

@end
