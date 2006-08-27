//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>


@class KFSplitView, GeniusTableView;

@interface GeniusWindowController : NSWindowController {
	NSSearchField * _searchField;
	KFSplitView * _splitView;
	GeniusTableView * _tableView;
	NSLevelIndicator * _levelIndicator;
	NSMenu * _defaultColumnsMenu;	// only used when window is inactive
}

- (void) setupTableView:(NSTableView *)tableView;
- (void) setupSplitView:(NSSplitView *)splitView;
- (void) setupAtomTextView:(NSTextView *)textView;
- (void) bindTextView:(NSTextView *)textView toController:(id)observableController withKeyPath:(NSString *)keyPath;

+ (float) listTextFontSizeForSizeMode:(int)mode;
+ (float) rowHeightForSizeMode:(int)mode;

@end


@interface NSObject (NSWindowControllerEventForwarding)
- (BOOL)performKeyDown:(NSEvent *)theEvent;
@end


@interface GeniusWindowController (Actions)

// Edit menu
- (IBAction) selectSearchField:(id)sender;

// View menu
- (IBAction) showRichTextEditor:(id)sender;

// Item menu
- (IBAction) toggleInspector:(id)sender;

// Toolbar
- (IBAction) toggleFontPanel:(id)sender;
- (IBAction) toggleColorPanel:(id)sender;

@end
