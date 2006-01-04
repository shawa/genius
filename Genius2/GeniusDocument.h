/* GeniusDocument */

#import <Cocoa/Cocoa.h>

@class GeniusDocumentInfo;

@interface GeniusDocument : NSPersistentDocument
{
    IBOutlet id itemArrayController;

    IBOutlet id levelIndicator;
    IBOutlet id searchField;
    IBOutlet id tableView;
    IBOutlet id splitView;
	
    IBOutlet id atomATextView;
    IBOutlet id atomBTextView;
	
	GeniusDocumentInfo * _documentInfo;
	
	NSArray * _itemsDuringDrag;
}

- (NSWindow *) window;

- (NSArrayController *) itemArrayController;

- (GeniusDocumentInfo *) documentInfo;	// used by GeniusDocument.nib and QuizModel

- (float) overallPercent;	// 0-100.0

@end


@interface GeniusDocument (Actions)

// File menu
- (IBAction) exportFile:(id)sender;

// Edit menu
- (IBAction) delete:(id)sender;
- (IBAction) duplicate:(id)sender;

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
