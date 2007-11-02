/*
	Genius
	Copyright (C) 2003-2006 John R Chang

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

#import "GeniusWelcomePanel.h"

static NSString * GeniusWelcomePanelDontShowKey = @"dontShowQuizWelcome";


//! Standard NSWindowController subclass for handling the PreQuiz nib.
/*!
    @todo Rename this clas to something without Panel in the name.
*/
@implementation GeniusWelcomePanel

//! Creates if needed the singleton GeniusWelcomePanel initializes it.
+ (GeniusWelcomePanel *) sharedWelcomePanel
{
    static GeniusWelcomePanel * sController = nil;
    if (sController == nil)
        sController = [[GeniusWelcomePanel alloc] initWithWindowNibName:@"PreQuiz"];
    return sController;
}

//! Presents PreQuiz window with helpful tips regarding memorization work.
/*!
    Presents user with opportunity to set a perference that disables this view in the future.
*/
- (BOOL) runModal
{
    static BOOL sHasSeenThisSession = NO;
    if (sHasSeenThisSession)
        return YES;
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    BOOL dontShowPref = [defaults boolForKey:GeniusWelcomePanelDontShowKey];
    if (dontShowPref)
        return YES;
        
    [[self window] center];
        
    int result = [NSApp runModalForWindow:[self window]];
    [self close];

    if (result == NSRunAbortedResponse)
        return NO;
    
    if ([dontRemindSwitch state] == NSOnState)
        [defaults setBool:YES forKey:GeniusWelcomePanelDontShowKey];
        
    sHasSeenThisSession = YES;
    return YES;
}

//! The user has elected not to continue with the quiz.
- (IBAction)goBack:(id)sender
{
    [NSApp abortModal];
}

//! The quiz should proceed.
- (IBAction)continue:(id)sender
{
    [NSApp stopModal];
}

//! The window has been closed.
- (BOOL)windowShouldClose:(id)sender
{
    [NSApp abortModal];
    return YES;
}

@end
