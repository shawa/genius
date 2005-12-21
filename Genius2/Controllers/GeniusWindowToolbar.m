//
//  GeniusWindowToolbar.m
//  Genius
//
//  Created by John R Chang on 2005-10-14.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusWindowToolbar.h"

#import "GeniusDocument.h"


NSString * GeniusToolbarIdentifier = @"GeniusToolbar";

NSString * GeniusToolbarAddItemIdentifier = @"Add";
NSString * GeniusToolbarFontsItemIdentifier = @"Fonts";
NSString * GeniusToolbarColorsItemIdentifier = @"Colors";
NSString * GeniusToolbarInfoItemIdentifier = @"Info";
NSString * GeniusToolbarLevelIndicatorItemIdentifier = @"LevelIndicator";
NSString * GeniusToolbarQuizItemIdentifier = @"Quiz";
NSString * GeniusToolbarSearchItemIdentifier = @"Search";
NSString * GeniusToolbarPreferencesItemIdentifier = @"Preferences";

//NSString * GeniusToolbarLearnReviewSliderItemIdentifier = @"LearnReviewSlider";
//NSString * GeniusToolbarNotesItemIdentifier = @"Notes";


// not the prettiest
static id sLevelIndicator = nil;

@implementation GeniusWindowController (Toolbar)

- (void) setupToolbarWithLevelIndicator:(id)levelIndicator searchField:(id)searchField
{
    NSToolbar * toolbar = [[[NSToolbar alloc] initWithIdentifier:GeniusToolbarIdentifier] autorelease];
    [toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	
	sLevelIndicator = levelIndicator;
	_searchField = searchField;
	
    [[self window] setToolbar:toolbar];
}

@end


@implementation GeniusWindowController (NSToolbarDelegate)

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
		GeniusToolbarAddItemIdentifier,
	NSToolbarFlexibleSpaceItemIdentifier,
		GeniusToolbarFontsItemIdentifier,
		GeniusToolbarColorsItemIdentifier,
		GeniusToolbarInfoItemIdentifier,
	NSToolbarFlexibleSpaceItemIdentifier,
		GeniusToolbarLevelIndicatorItemIdentifier,
		GeniusToolbarQuizItemIdentifier, 
	NSToolbarFlexibleSpaceItemIdentifier,
		GeniusToolbarSearchItemIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
		GeniusToolbarAddItemIdentifier,
		GeniusToolbarFontsItemIdentifier,
		GeniusToolbarColorsItemIdentifier,
		GeniusToolbarInfoItemIdentifier,
		GeniusToolbarLevelIndicatorItemIdentifier,
		GeniusToolbarQuizItemIdentifier, 
		GeniusToolbarSearchItemIdentifier,
	NSToolbarFlexibleSpaceItemIdentifier,
		GeniusToolbarPreferencesItemIdentifier,
		nil];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if (flag)
    {
        NSToolbarItem * toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        
        if ([itemIdentifier isEqual:GeniusToolbarAddItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Add", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"Plus"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:[self document]];
            [toolbarItem setAction:@selector(newItem:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarQuizItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Quiz", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"play"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:[self document]];
            [toolbarItem setAction:@selector(runQuiz:)];
        }
/*        else if ([itemIdentifier isEqual:GeniusToolbarLearnReviewSliderItemIdentifier])
        {
            //NSString * label = NSLocalizedString(@"Auto-Pick", nil);
            //[toolbarItem setLabel:label];

			NSView * itemView = [learnReviewSlider superview];
            [toolbarItem setView:itemView];
            [toolbarItem setMinSize:NSMakeSize([itemView frame].size.width, 32.0)];
        }*/
        else if ([itemIdentifier isEqual:GeniusToolbarInfoItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Inspect", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"Inspector"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:[self document]];
            [toolbarItem setAction:@selector(toggleInspector:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarColorsItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Colors", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"colors"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(toggleColorPanel:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarFontsItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Fonts", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"fonts"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(toggleFontPanel:)];
        }
		else if ([itemIdentifier isEqual:GeniusToolbarPreferencesItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Preferences", nil);
            [toolbarItem setLabel:label];

            NSImage * image = [NSImage imageNamed:@"preferences"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:[NSApp delegate]];
            [toolbarItem setAction:@selector(showPreferences:)];
        }
/*        else if ([itemIdentifier isEqual:GeniusToolbarNotesItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Notes", nil);
            [toolbarItem setLabel:label];
            
            NSImage * image = [NSImage imageNamed:@"Information"];
//            NSImage * image = [NSImage imageNamed:@"notes"];
            [toolbarItem setImage:image];
    
            [toolbarItem setTarget:[self document]];
            [toolbarItem setAction:@selector(showNotes:)];
        }*/
        else if ([itemIdentifier isEqual:GeniusToolbarLevelIndicatorItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Progress", nil);
            [toolbarItem setLabel:label];
            
            [toolbarItem setMinSize:NSMakeSize(64.0, 16.0)];
            [toolbarItem setView:[sLevelIndicator superview]];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarSearchItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Search", nil);
            [toolbarItem setLabel:label];
            
/*            _searchField = [NSSearchField new];
            [_searchField setTarget:[self document]];
            [_searchField setAction:@selector(search:)];*/
            [toolbarItem setMinSize:NSMakeSize(128.0, 22.0)];
            [toolbarItem setView:[_searchField superview]];
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
