/* GeniusAppDelegate */

#import <Cocoa/Cocoa.h>

@interface GeniusAppDelegate : NSObject
{
}

// Application menu
- (IBAction) showPreferences:(id)sender;
- (IBAction) openTipJarSite:(id)sender;
- (IBAction) openFileSharingSite:(id)sender;

// Help menu
- (IBAction) openSupportSite:(id)sender;

@end
