//
//  GeniusWindowToolbar.h
//  Genius
//
//  Created by John R Chang on 2005-10-14.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GeniusWindowController.h"


@interface GeniusWindowController (Toolbar)

- (void) setupToolbarWithLevelIndicator:(id)levelIndicator searchField:(id)searchField;

@end
