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

#import <Foundation/Foundation.h>

@class GeniusPreferencesController;
@class GeniusHelpWindowController;

@interface GeniusAppDelegate : NSObject {
    GeniusPreferencesController *preferencesController;  //!< Standard NSWindowController subclass for preferences window.
    GeniusHelpWindowController *helpController;              //!< Standard NSWindowController subclass for help window.
}

- (IBAction) showPreferences:(id)sender;
- (IBAction) showWebSite:(id)sender;
- (IBAction) showSupportSite:(id)sender;
- (IBAction) toggleSoundEffects:(id)sender;
- (IBAction) showHelpWindow:(id)sender;
- (IBAction) importFile:(id)sender;

- (BOOL) isNewerVersion: (NSString*) currentVersion lastVersion:(NSString*)lastVersion;

@end
