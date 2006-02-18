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


@implementation GeniusWindowController (Toolbar)

- (void) setupToolbarWithLevelIndicator:(id)levelIndicator searchField:(id)searchField
{
    NSToolbar * toolbar = [[[NSToolbar alloc] initWithIdentifier:GeniusToolbarIdentifier] autorelease];
    [toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	
	_levelIndicator = [levelIndicator retain];	// XXX
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


// See file:///Developer/ADC%20Reference%20Library/documentation/Cocoa/Conceptual/Toolbars/Tasks/AddRemoveToolbarItems.html
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if (flag)
    {
        NSToolbarItem * toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        
        if ([itemIdentifier isEqual:GeniusToolbarAddItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Add", nil);
            [toolbarItem setLabel:label];
            [toolbarItem setPaletteLabel:label];

            NSImage * image = [NSImage imageNamed:@"Plus"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:[self document]];
            [toolbarItem setAction:@selector(newItem:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarQuizItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Quiz", nil);
            [toolbarItem setLabel:label];
            [toolbarItem setPaletteLabel:label];

            NSImage * image = [NSImage imageNamed:@"play"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:[self document]];
            [toolbarItem setAction:@selector(runQuiz:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarInfoItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Inspect", nil);
            [toolbarItem setLabel:label];
            [toolbarItem setPaletteLabel:label];

            NSImage * image = [NSImage imageNamed:@"Inspector"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:[self document]];
            [toolbarItem setAction:@selector(toggleInspector:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarColorsItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Colors", nil);
            [toolbarItem setLabel:label];
            [toolbarItem setPaletteLabel:label];

            NSImage * image = [NSImage imageNamed:@"colors"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(toggleColorPanel:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarFontsItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Fonts", nil);
            [toolbarItem setLabel:label];
            [toolbarItem setPaletteLabel:label];

            NSImage * image = [NSImage imageNamed:@"fonts"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(toggleFontPanel:)];
        }
		else if ([itemIdentifier isEqual:GeniusToolbarPreferencesItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Preferences", nil);
            [toolbarItem setLabel:label];
            [toolbarItem setPaletteLabel:label];

            NSImage * image = [NSImage imageNamed:@"preferences"];
            [toolbarItem setImage:image];
            
            [toolbarItem setTarget:[NSApp delegate]];
            [toolbarItem setAction:@selector(showPreferences:)];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarLevelIndicatorItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Progress", nil);
            [toolbarItem setLabel:label];
            [toolbarItem setPaletteLabel:label];
            
            [toolbarItem setView:_levelIndicator];
			[toolbarItem setMinSize:NSMakeSize(64.0,NSHeight([_levelIndicator frame]))];
			//[toolbarItem setMaxSize:NSMakeSize(64.0,NSHeight([_levelIndicator frame]))];
        }
        else if ([itemIdentifier isEqual:GeniusToolbarSearchItemIdentifier])
        {
            NSString * label = NSLocalizedString(@"Search", nil);
            [toolbarItem setLabel:label];
            [toolbarItem setPaletteLabel:label];
            
            [toolbarItem setMinSize:NSMakeSize(128.0, NSHeight([_searchField frame]))];
            [toolbarItem setView:_searchField]; //[_searchField superview]];
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
