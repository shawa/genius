//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

@interface GeniusAppDelegate : NSObject
{
	BOOL _isNewVersion;
}

// Application menu
- (IBAction) showPreferences:(id)sender;
- (IBAction) openTipJarSite:(id)sender;
- (IBAction) openFileSharingSite:(id)sender;

// Study menu
- (IBAction) toggleSoundEffects:(id)sender;

// Help menu
- (IBAction) showHelpWindow:(id)sender;
- (IBAction) openGeniusWebSite:(id)sender;
- (IBAction) openSupportSite:(id)sender;

@end
