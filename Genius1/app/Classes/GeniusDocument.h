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

#import <Cocoa/Cocoa.h>

@class GeniusArrayController;
@class GeniusPair;
@class MyQuizController;
@class GSTableView;

//! Standard NSDocument subclass for controlling interaction between UI and GeniusPair list.
@interface GeniusDocument : NSDocument
{
    IBOutlet GSTableView *tableView;                    //!< The main table showing the GeniusPair items.
    IBOutlet GeniusArrayController *arrayController;    //!< The controller holding the displayed items.
    IBOutlet NSTextField  *statusField;                 //!< Shows selection count and total items.
    IBOutlet NSTextField *levelField;                   //!< Displays percentage of items with any score.
    IBOutlet NSLevelIndicator *levelIndicator;          //!< Displays level information as bar.
    IBOutlet NSDrawer *infoDrawer;                      //!< Drawer where you can set group and type info.
    IBOutlet NSDrawer *notesDrawer;                     //!< Drawer at bottom of window with GeniusPair notes.
    IBOutlet NSWindow *deckPreferences;                 //!< Sheet for enter card side titles.
    
    IBOutlet NSSlider *learnReviewSlider;               //!< Slider used to setup Quiz mode between Learn and Review.
    IBOutlet NSView *helpTextOverlay;                   //!< Help text displayed when table contents empty.
    NSSearchField *_searchField;                        //!< Text field top right used for searching through GeniusPair items.
    
    // Data model
    NSMutableArray *_visibleColumnIdentifiers;          //!< Identifiers of the columns that should be displayed on loading a file.
    NSMutableDictionary *_columnHeadersDict;            //!< Labels used for column header names.
    NSMutableArray *_pairs;                             //!< The GeniusPair items that make up a GeniusDocument.
    NSDate *_cumulativeStudyTime;                       //!< Not sure this is used anymore.
    NSNumber *probabilityCenter;                        //!< balance between learning and reviewing.

    BOOL _shouldShowImportWarningOnSave;                //!< Flag indicating the GeniusDocument was loaded from an older version.
    NSArray *_pairsDuringDrag;                          //!< Temporary array of items being dragged and dropped.
    NSMutableSet *_customTypeStringCache;               //!< Cache of all types used in deck.
    
    MyQuizController *quizController;                   //!< The current quiz controller if there is one.
    NSArray *_sortedCustomTypeStrings;                  //!< Sorted array of custom types cached from Genius Pairs.
}

- (NSArray*) pairs;
- (void) setPairs: (NSMutableArray*) values;
- (void) removeObjectFromPairsAtIndex:(int) index;
- (void) insertObject:(GeniusPair*) pair inPairsAtIndex:(int)index;

- (NSSearchField *) searchField;    // in toolbar

- (void) _reloadCustomTypeCacheSet;

@end

@interface GeniusDocument(IBActions)

// View menu
- (IBAction) toggleGroupColumn: (id) sender;
- (IBAction) toggleTypeColumn: (id) sender;
- (IBAction) toggleABScoreColumn: (id) sender;
- (IBAction) toggleBAScoreColumn: (id) sender;
- (IBAction) showInfo: (id) sender;

- (IBAction) showDeckPreferences: (id) sender;
- (IBAction) endDeckPreferences: (id) sender;

- (IBAction) add: (id) sender;
- (IBAction) duplicate: (id) sender;

- (IBAction) resetScore: (id) sender;
- (IBAction) setItemImportance: (id) sender;

- (IBAction) search: (id) sender;

- (IBAction) quizAutoPick: (id) sender;
- (IBAction) quizReview: (id) sender;
- (IBAction) quizSelection: (id) sender;

@end

@interface GeniusArrayController : NSArrayController {
    IBOutlet id geniusDocument;  //!< Provides access to columnBindings
    NSString * _filterString; //!< The string for which we are filtering.
}

- (NSString *) filterString;
- (void) setFilterString:(NSString *)string;
- (NSArray *)arrangeObjects:(NSArray *)objects;
@end

@interface GeniusDocument(UndoRedoSupport)
- (void) addObserver: (id) observer;
- (void) removeObserver: (id) observer;
@end

@interface NSWindowController(UndoRedoSupport)
- (void) setValue:(id)value forKeyPath:(NSString*)keyPath inObject:(id)object;
@end
