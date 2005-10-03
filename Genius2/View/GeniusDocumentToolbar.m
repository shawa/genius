//
//  GeniusDocumentToolbar.m
//  Genius
//
//  Created by John R Chang on Fri Dec 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "GeniusDocumentToolbar.h"


NSString * GeniusToolbarIdentifier = @"GeniusToolbar";

NSString * GeniusToolbarStudyItemIdentifier = @"Test";
NSString * GeniusToolbarLearnReviewSliderItemIdentifier = @"LearnReviewSlider";
//NSString * GeniusToolbarNotesItemIdentifier = @"Notes";
NSString * GeniusToolbarInfoItemIdentifier = @"Info";
NSString * GeniusToolbarSearchItemIdentifier = @"Search";


@implementation GeniusDocument (Toolbar)

- (void) setupToolbarForWindow:(NSWindow *)window
{
    NSToolbar * toolbar = [[[NSToolbar alloc] initWithIdentifier:GeniusToolbarIdentifier] autorelease];
//	[toolbar setShowsBaselineSeparator:NO];
    [toolbar setDelegate:self];
	
    [window setToolbar:toolbar];
}

@end


@implementation GeniusDocument (NSToolbarDelegate)

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:GeniusToolbarStudyItemIdentifier, GeniusToolbarLearnReviewSliderItemIdentifier, NSToolbarSeparatorItemIdentifier,
    GeniusToolbarInfoItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, GeniusToolbarSearchItemIdentifier, nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [self toolbarAllowedItemIdentifiers:toolbar];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if (flag)
    {
        NSToolbarItem * toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        
        if ([itemIdentifier isEqual:GeniusToolbarStudyItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Quiz", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"launch-32"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(runQuiz:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarLearnReviewSliderItemIdentifier])
        {
            //NSString * label = NSLocalizedString(@"Auto-Pick", nil);
            //[toolbarItem setLabel:label];

/*			NSView * itemView = [learnReviewSlider superview];
            [toolbarItem setView:itemView];
            [toolbarItem setMinSize:NSMakeSize([itemView frame].size.width, 32.0)];*/
        }
        else if ([itemIdentifier isEqual:GeniusToolbarInfoItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Info", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"get-info-32"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(toggleInspector:)];
        }
/*        else if ([itemIdentifier isEqual:GeniusToolbarNotesItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Notes", nil);
            [toolbarItem setLabel:label];
            
            NSImage * image = [NSImage imageNamed:@"Information"];
//            NSImage * image = [NSImage imageNamed:@"notes"];
            [toolbarItem setImage:image];
    
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(showNotes:)];
        }*/
        else if ([itemIdentifier isEqual:GeniusToolbarSearchItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Search", nil);
            [toolbarItem setLabel:label];
            
/*            _searchField = [NSSearchField new];
            [_searchField setTarget:self];
            [_searchField setAction:@selector(search:)];*/
            [toolbarItem setMinSize:NSMakeSize(128.0, 22.0)];
            [toolbarItem setView:[searchField superview]];
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
