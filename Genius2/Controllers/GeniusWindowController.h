//
//  GeniusWindowController.h
//  Genius2
//
//  Created by John R Chang on 2005-10-14.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GeniusWindowController : NSWindowController {
	NSSearchField * _searchField;
}

- (void) setupTableView:(NSTableView *)tableView withHeaderViewMenu:(NSMenu *)headerViewMenu;
- (void) setupSplitView:(NSSplitView *)splitView;

+ (float) listTextFontSizeForSizeMode:(int)mode;


// Edit menu
- (IBAction) selectSearchField:(id)sender;

// Item menu
- (IBAction) toggleInspector:(id)sender;

@end
