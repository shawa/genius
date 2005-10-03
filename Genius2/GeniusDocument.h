/* GeniusDocument */

#import <Cocoa/Cocoa.h>

@class GeniusDocumentInfo;

@interface GeniusDocument : NSPersistentDocument
{
    IBOutlet id itemArrayController;
    IBOutlet id searchField;
    IBOutlet id tableView;
    IBOutlet id tableColumnMenu;

	NSDictionary * _tableColumnDictionary;
    NSWindowController * _inspectorController;
}

- (NSArrayController *) itemArrayController;
- (GeniusDocumentInfo *) documentInfo;	// used by GeniusDocument.nib

@end


@interface GeniusDocument (Actions)

// Edit menu
- (IBAction) selectSearchField:(id)sender;

// Item menu
- (IBAction) newItem:(id)sender;
- (IBAction) toggleInspector:(id)sender;
- (IBAction) setItemRating:(NSMenuItem *)sender;
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
