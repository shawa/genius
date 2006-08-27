//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Foundation/Foundation.h>
#import "GeniusV1Item.h"


// A directed association between two items, with score-keeping data.
// Like an axon between two neurons.
@class GeniusV1Pair;

@interface GeniusV1Association : NSObject {
    GeniusV1Item * _cueItem, * _answerItem;
    GeniusV1Pair * _parentPair;
    NSMutableDictionary * _perfDict;

    // Transient
    BOOL _dirty;    // used by key-value observing
}

// Never create directly; always create through GeniusV1Pair.

- (GeniusV1Item *) cueItem;
- (GeniusV1Item *) answerItem;

- (GeniusV1Pair *) parentPair;


- (NSDictionary *) performanceDictionary;

- (void) reset;
    // Resets the following fields

- (int) score;          // -1 means never been quizzed
- (void) setScore:(int)score;

// Equivalent object-based methods used by key bindings
- (NSNumber *) scoreNumber; // nil means never been quizzed
- (void) setScoreNumber:(id)scoreNumber;

/*- (unsigned int) right;
- (void) setRight:(unsigned int)right;

- (unsigned int) wrong;
- (void) setWrong:(unsigned int)wrong;*/

- (NSDate *) dueDate;
- (void) setDueDate:(NSDate *)dueDate;

@end


extern const int kGeniusV1PairDisabledImportance;
extern const int kGeniusV1PairMinimumImportance;
extern const int kGeniusV1PairNormalImportance;
extern const int kGeniusV1PairMaximumImportance;

@interface GeniusV1Pair : NSObject <NSCoding, NSCopying> {
    GeniusV1Association * _associationAB, * _associationBA;
    NSMutableDictionary * _userDict;
    
    // Transient
    BOOL _dirty;    // used by key-value observing
}

+ (NSArray *) associationsForPairs:(NSArray *)pairs useAB:(BOOL)useAB useBA:(BOOL)useBA;

- (id) init;


- (GeniusV1Item *) itemA;
- (GeniusV1Item *) itemB;

- (GeniusV1Association *) associationAB;
- (GeniusV1Association *) associationBA;


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


@interface GeniusV1Pair (GeniusV1DocumentAdditions)
- (BOOL) disabled;
- (void) setDisabled:(BOOL)disabled;
@end


@interface GeniusV1Pair (TextImportExport)

+ (NSString *) tabularTextFromPairs:(NSArray *)pairs order:(NSArray *)keyPaths;
- (NSString *) tabularTextByOrder:(NSArray *)keyPaths;

+ (NSArray *) pairsFromTabularText:(NSString *)string order:(NSArray *)keyPaths;
- (id) initWithTabularText:(NSString *)line order:(NSArray *)keyPaths;

@end
