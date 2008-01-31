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

@class GeniusItem;
@class GeniusAssociation;

extern const int kGeniusPairDisabledImportance;
extern const int kGeniusPairMinimumImportance;
extern const int kGeniusPairNormalImportance;
extern const int kGeniusPairMaximumImportance;

//! Relates two GeniusAssociation instances and some meta info.
/*!
A GeniusPair is conceptually like a two sided index card.  Through its two instances
 of GeniusAssociation it has access two two GeniusItem intances.  One for the 'front' of
 the card and one for the 'back'.  In addition a GeniusPair maintains information about
 the users classification of the card, such as importance, group, type, and notes.
 */
@interface GeniusPair : NSObject <NSCoding, NSCopying> {
    GeniusAssociation * _associationAB; //!< Stats for standard learning mode directional relationship. 
    GeniusAssociation * _associationBA; //!< Stats for Jepardy style learning mode directional relationship.
    
    //! Stores user entered properties related to this GeniusPair.
    /*! Variable storage for info such as group, importance, and type */
    NSMutableDictionary * _userDict;
}

+ (NSArray *) associationsForPairs:(NSArray *)pairs useAB:(BOOL)useAB useBA:(BOOL)useBA;

- (id) initWithItemA:(GeniusItem *)itemA itemB:(GeniusItem *)itemB userDict:(NSMutableDictionary *)userDict;

- (void) addObserver: (id) observer;
- (void) removeObserver: (id) observer;

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

+ (NSMutableArray *) pairsFromTabularText:(NSString *)string order:(NSArray *)keyPaths;
- (id) initWithTabularText:(NSString *)line order:(NSArray *)keyPaths;

@end
