//
//  GSTableView.h
//  Genius
//
//  Created by Chris Miner on 20.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GSTableView : NSTableView
{
    NSMutableDictionary *tableColumnCache;                 //!< Cache of all table columns for hiding and displaying them.
}

- (void) setVisibleColumns:(NSArray*) identifiers;
- (void) toggleColumnWithIdentifier:(NSString *)identifier;
- (NSArray *) visibleColumnIdentifiers;

@end
