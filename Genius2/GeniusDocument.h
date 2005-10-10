/* GeniusDocument */

#import <Cocoa/Cocoa.h>

@class GeniusDocumentInfo;

@interface GeniusDocument : NSPersistentDocument
{
    IBOutlet id itemArrayController;
    IBOutlet id documentInfoController;
    IBOutlet id levelIndicator;
    IBOutlet id searchField;
    IBOutlet id tableView;
    IBOutlet id tableColumnMenu;

	NSDictionary * _tableColumnDictionary;
}

- (NSArrayController *) itemArrayController;
- (GeniusDocumentInfo *) documentInfo;	// used by GeniusDocument.nib and QuizModel

@end


@interface GeniusDocument (Actions)

// File menu
- (IBAction) exportFile:(id)sender;

// Edit menu
- (IBAction) selectSearchField:(id)sender;

// Item menu
- (IBAction) newItem:(id)sender;
- (IBAction) toggleInspector:(id)sender;
- (IBAction) setItemRating:(NSMenuItem *)sender;
- (IBAction) swapColumns:(id)sender;
- (IBAction) resetItemScore:(id)sender;

// Format menu
- (IBAction) toggleColumnRichText:(NSMenuItem *)sender;

// Study menu
- (IBAction) setQuizDirectionModeAction:(NSMenuItem *)sender;
- (IBAction) runQuiz:(id)sender;
- (IBAction) toggleSoundEffects:(id)sender;

// table view pop-up menu
- (IBAction) toggleTableColumnShown:(NSMenuItem *)sender;

@end
