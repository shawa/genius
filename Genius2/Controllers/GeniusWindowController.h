//
//  GeniusWindowController.h
//  Genius2
//
//  Created by John R Chang on 2005-10-14.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class CollapsableSplitView, GeniusTableView;

@interface GeniusWindowController : NSWindowController {
	NSSearchField * _searchField;
	CollapsableSplitView * _splitView;
	GeniusTableView * _tableView;
	NSMenu * _defaultColumnsMenu;
}

- (void) setupTableView:(NSTableView *)tableView;
- (void) setupSplitView:(NSSplitView *)splitView;
- (void) setupAtomTextView:(NSTextView *)textView;
- (void) bindTextView:(NSTextView *)textView toController:(id)observableController withKeyPath:(NSString *)keyPath;

+ (float) listTextFontSizeForSizeMode:(int)mode;
+ (float) rowHeightForSizeMode:(int)mode;

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
