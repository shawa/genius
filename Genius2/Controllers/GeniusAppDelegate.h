/* GeniusAppDelegate */

#import <Cocoa/Cocoa.h>

@interface GeniusAppDelegate : NSObject
{
}

// Application menu
- (IBAction) showPreferences:(id)sender;
- (IBAction) openTipJarSite:(id)sender;
- (IBAction) openFileSharingSite:(id)sender;

// Study menu
- (IBAction) toggleSoundEffects:(id)sender;

// Help menu
- (IBAction) showHelpWindow:(id)sender;
- (IBAction) openSupportSite:(id)sender;

@end
