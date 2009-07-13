/*
	Genius
	Copyright (C) 2003-2006 John R Chang
	Copyright (C) 2007-2008 Chris Miner

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.	

	http://www.gnu.org/licenses/gpl.txt
*/

#import "GeniusToolbar.h"


NSString * GeniusToolbarIdentifier = @"GeniusToolbar";

NSString * GeniusToolbarStudyItemIdentifier = @"Study";
NSString * GeniusToolbarLearnReviewSliderItemIdentifier = @"LearnReviewSlider";
NSString * GeniusToolbarNotesItemIdentifier = @"Notes";
NSString * GeniusToolbarInfoItemIdentifier = @"Info";
NSString * GeniusToolbarSearchItemIdentifier = @"Search";

/*!
    @category GeniusDocument(Toolbar)
    @abstract Support for setting up the toolbar.
*/
@implementation GeniusDocument(Toolbar)

//! Intstanciates the toobar and attaches it to the GeniusDocument window.
- (void) setupToolbarForWindow:(NSWindow *)window
{
    NSToolbar * toolbar = [[[NSToolbar alloc] initWithIdentifier:GeniusToolbarIdentifier] autorelease];
    [toolbar setDelegate:self];
    
    [window setToolbar:toolbar];
}

@end

//! Standard support for configuring a tool bar.
@implementation GeniusDocument(NSToolbarDelegate)

//! Configures the allowed item identifiers for our toolbar.
- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:GeniusToolbarStudyItemIdentifier, GeniusToolbarLearnReviewSliderItemIdentifier, NSToolbarSeparatorItemIdentifier,
    GeniusToolbarInfoItemIdentifier, GeniusToolbarNotesItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, GeniusToolbarSearchItemIdentifier, nil];
}

//! Configures the default item identifiers for our toolbar.
- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [self toolbarAllowedItemIdentifiers:toolbar];
}

//! Creates a new toolbar item; returns a toolbar item of the identified kind for our toolbar.
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if (flag)
    {
        NSToolbarItem * toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        
        if ([itemIdentifier isEqual:GeniusToolbarStudyItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Study", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"play"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(quizAutoPick:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarLearnReviewSliderItemIdentifier])
        {
            //NSString * label = NSLocalizedString(@"Auto-Pick", nil);
            //[toolbarItem setLabel:label];

			NSView * itemView = [learnReviewSlider superview];
            [toolbarItem setView:itemView];
            [toolbarItem setMinSize:NSMakeSize([itemView frame].size.width, [itemView frame].size.height)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarInfoItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Info", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"Inspector"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:infoDrawer];
            [toolbarItem setAction:@selector(toggle:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarNotesItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Notes", nil);
            [toolbarItem setLabel:label];
            
            NSImage * image = [NSImage imageNamed:@"Information"];
            [toolbarItem setImage:image];
    
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(showNotes:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarSearchItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Search", nil);
            [toolbarItem setLabel:label];
            
            _searchField = [[NSSearchField alloc] init];
            [_searchField setTarget:self];
            [_searchField setAction:@selector(search:)];
            [toolbarItem setMinSize:NSMakeSize(128.0, 22.0)];
            [toolbarItem setView:_searchField];
        }
        else
        {
            return nil;
        }
            
        return toolbarItem;
    }
    else
    {
        NSEnumerator * itemEnumerator = [[toolbar items] objectEnumerator];
        NSToolbarItem * item;
        while ((item = [itemEnumerator nextObject]))
            if ([[item itemIdentifier] isEqualToString:itemIdentifier])
                return item;
        return nil;
    }
}

@end
