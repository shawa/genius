//
//  GeniusDocument.h
//  Vocab-O-Matic
//
//  Created by John R Chang on Sat Oct 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface GeniusDocument : NSDocument
{
    IBOutlet id tableView;
    IBOutlet id arrayController;
    IBOutlet id statusField;
    IBOutlet id levelField;
    IBOutlet id levelIndicator;
    IBOutlet id infoDrawer;
    IBOutlet id notesDrawer;
    IBOutlet id initialWatermarkView;
    
    IBOutlet id learnReviewSlider;  // in toolbar
    NSSearchField * _searchField;   // in toolbar
    NSMutableDictionary * _tableColumns;
    
    // Data model
    NSMutableArray * _visibleColumnIdentifiersBeforeNibLoaded;    // only used during load
    float _learnVsReviewWeightBeforeNibLoaded;
    NSMutableDictionary * _columnHeadersDict;
    NSMutableArray * _pairs;
    NSDate * _cumulativeStudyTime;

    BOOL _shouldShowImportWarningOnSave;
    NSArray * _pairsDuringDrag;
    NSMutableSet * _customTypeStringCache;
}

- (NSMutableArray *) pairs;

- (NSSearchField *) searchField;    // in toolbar

@end

@interface GeniusDocument (IBActions)

// View menu
- (IBAction)toggleGroupColumn:(id)sender;
- (IBAction)toggleTypeColumn:(id)sender;
- (IBAction)toggleABScoreColumn:(id)sender;
- (IBAction)toggleBAScoreColumn:(id)sender;
- (IBAction)showInfo:(id)sender;

- (IBAction)add:(id)sender;
- (IBAction)duplicate:(id)sender;
//- (IBAction)swapItems:(id)sender;
- (IBAction)resetScore:(id)sender;
- (IBAction)setItemImportance:(id)sender;

- (IBAction)search:(id)sender;

- (IBAction)quizAutoPick:(id)sender;
- (IBAction)quizReview:(id)sender;
- (IBAction)quizSelection:(id)sender;

@end


@interface GeniusArrayController : NSArrayController {
    IBOutlet id geniusDocument;
    NSString * _filterString;
}

- (NSString *) filterString;
- (void) setFilterString:(NSString *)string;

- (NSArray *)arrangeObjects:(NSArray *)objects;
@end


@interface MyTableView : NSTableView {
    IBOutlet id documentController; // to get to the searchField
}
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
@end

@interface NSObject (MyTableViewDelegate)
- (BOOL) _tableView:(NSTableView *)aTableView shouldChangeHeaderTitleOfTableColumn:(NSTableColumn *)aTableColumn;
- (void) _tableView:(NSTableView *)aTableView didChangeHeaderTitleOfTableColumn:(NSTableColumn *)aTableColumn;
@end
