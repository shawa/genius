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

#import <Foundation/Foundation.h>
#import "GeniusItem.h"


// A directed association between two items, with score-keeping data.
// Like an axon between two neurons.
@class GeniusPair;

@interface GeniusAssociation : NSObject {
    GeniusItem * _cueItem, * _answerItem;
    GeniusPair * _parentPair;
    NSMutableDictionary * _perfDict;

    // Transient
    BOOL _dirty;    // used by key-value observing
}

// Never create directly; always create through GeniusPair.

- (GeniusItem *) cueItem;
- (GeniusItem *) answerItem;

- (GeniusPair *) parentPair;


- (NSDictionary *) performanceDictionary;

- (void) reset;
    // Resets the following fields

- (int) score;          // -1 means never been quizzed
- (void) setScore:(int)score;

// Equivalent object-based methods used by key bindings
- (NSNumber *) scoreNumber; // nil means never been quizzed
- (void) setScoreNumber:(NSNumber *)scoreNumber;

/*- (unsigned int) right;
- (void) setRight:(unsigned int)right;

- (unsigned int) wrong;
- (void) setWrong:(unsigned int)wrong;*/

- (NSDate *) dueDate;
- (void) setDueDate:(NSDate *)dueDate;

@end


extern const int kGeniusPairDisabledImportance;
extern const int kGeniusPairMinimumImportance;
extern const int kGeniusPairNormalImportance;
extern const int kGeniusPairMaximumImportance;

@interface GeniusPair : NSObject <NSCoding, NSCopying> {
    GeniusAssociation * _associationAB, * _associationBA;
    NSMutableDictionary * _userDict;
    
    // Transient
    BOOL _dirty;    // used by key-value observing
}

+ (NSArray *) associationsForPairs:(NSArray *)pairs useAB:(BOOL)useAB useBA:(BOOL)useBA;

- (id) init;


- (GeniusItem *) itemA;
- (GeniusItem *) itemB;

- (GeniusAssociation *) associationAB;
- (GeniusAssociation *) associationBA;


- (int) importance;    // 0-10; 5=normal; -1=disabled
- (void) setImportance:(int)importance;


// Optional user-defined tags
- (NSString *) customGroupString;
- (void) setCustomGroupString:(NSString *)customGroup;

- (NSString *) customTypeString;
- (void) setCustomTypeString:(NSString *)customType;

- (NSString *) notesString;
- (void) setNotesString:(NSString *)notesString;

@end


@interface GeniusPair (GeniusDocumentAdditions)
- (BOOL) disabled;
- (void) setDisabled:(BOOL)disabled;
@end


@interface GeniusPair (TextImportExport)

+ (NSString *) tabularTextFromPairs:(NSArray *)pairs order:(NSArray *)keyPaths;
- (NSString *) tabularTextByOrder:(NSArray *)keyPaths;

+ (NSArray *) pairsFromTabularText:(NSString *)string order:(NSArray *)keyPaths;
- (id) initWithTabularText:(NSString *)line order:(NSArray *)keyPaths;

@end
