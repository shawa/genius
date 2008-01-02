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

@class MyTableView;
@class GeniusArrayController;

//! Standard NSDocument subclass for controlling interaction between UI and GeniusPair list.
@interface GeniusDocument : NSDocument
{
    IBOutlet MyTableView *tableView;                    //!< The main table showing the GeniusPair items.
    IBOutlet GeniusArrayController *arrayController;    //!< The controller holding the displayed items.
    IBOutlet NSTextField  *statusField;                 //!< Shows selection count and total items.
    IBOutlet NSTextField *levelField;                   //!< Displays percentage of items with any score.
    IBOutlet NSLevelIndicator *levelIndicator;          //!< Displays level information as bar.
    IBOutlet NSDrawer *infoDrawer;                      //!< Drawer where you can set group and type info.
    IBOutlet NSDrawer *notesDrawer;                     //!< Drawer at bottom of window with GeniusPair notes.
    IBOutlet NSView *initialWatermarkView;              //!< Help text displayed over the table in empty documents.
    IBOutlet NSWindow *deckPreferences;                 //!< Sheet for enter card side titles.
    
    IBOutlet NSSlider *learnReviewSlider;               //!< Slider used to setup Quiz mode between Learn and Review.
    NSSearchField *_searchField;                        //!< Text field top right used for searching through GeniusPair items.
    NSMutableDictionary *_tableColumns;                 //!< Cache of all table columns for hiding and displaying them.
    
    // Data model
    NSMutableArray *_visibleColumnIdentifiersBeforeNibLoaded;    //!< ???
    float _learnVsReviewWeightBeforeNibLoaded;                   //!< ???
    NSMutableDictionary *_columnHeadersDict;                     //!< Labels used for column header names.
    NSMutableArray *_pairs;                                      //!< The GeniusPair items that make up a GeniusDocument.
    NSDate *_cumulativeStudyTime;                                //!< Not sure this is used anymore.

    BOOL _shouldShowImportWarningOnSave;                          //!< Flag indicating the GeniusDocument was loaded from an older version.
    NSArray *_pairsDuringDrag;                                   //!< Temporary array of items being dragged and dropped.
    NSMutableSet *_customTypeStringCache;                        //!< Cache of all types used in deck.
}

- (NSMutableArray *) pairs;

- (NSSearchField *) searchField;    // in toolbar

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

@interface MyTableView : NSTableView {
    IBOutlet id documentController; //!< provides access to searchField of GeniusDocument
}
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
@end
