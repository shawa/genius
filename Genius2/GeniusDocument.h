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
    IBOutlet id splitView;
	
    IBOutlet id atomATextView;
    IBOutlet id atomBTextView;
	
	NSArray * _itemsDuringDrag;
}

- (NSWindow *) mainWindow;

- (NSArrayController *) itemArrayController;

- (GeniusDocumentInfo *) documentInfo;	// used by GeniusDocument.nib and QuizModel

@end


@interface GeniusDocument (Actions)

// File menu
- (IBAction) exportFile:(id)sender;

// Edit menu
- (IBAction) delete:(id)sender;
- (IBAction) duplicate:(id)sender;

// View menu
- (IBAction) showRichTextEditor:(id)sender;

// Item menu
- (IBAction) newItem:(id)sender;

- (IBAction) setItemRating:(NSMenuItem *)sender;

- (IBAction) swapColumns:(id)sender;

- (IBAction) makePlainText:(NSMenuItem *)sender;
- (IBAction) resetItemScore:(id)sender;

// Study menu
- (IBAction) setQuizDirectionModeAction:(NSMenuItem *)sender;
- (IBAction) runQuiz:(id)sender;

@end
