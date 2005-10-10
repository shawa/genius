#import "GeniusAppDelegate.h"

#import "GeniusValueTransformers.h"

#import "GeniusPreferencesController.h"
#import "GeniusHelpController.h"


@implementation GeniusAppDelegate

+ (void) initialize
{
//	NSUserDefaultsController * udc = [NSUserDefaultsController sharedUserDefaultsController];
	NSDictionary * defaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], @"useSoundEffects",
		[NSNumber numberWithFloat:50.0], @"QuizReviewLearnSliderValue", NULL];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

	GeniusFloatPercentTransformer * transformer = [[[GeniusFloatPercentTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GeniusFloatPercentTransformer"];
}


// Application menu

- (IBAction) showPreferences:(id)sender
{
	GeniusPreferencesController * pc = [GeniusPreferencesController sharedPreferencesController];
	[pc showWindow:sender];
}

- (IBAction) openTipJarSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://homepage.mac.com/jrc/Software/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction) openFileSharingSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://www.geniusfiles.info/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


// Help menu

- (IBAction) showHelpWindow:(id)sender
{
    [GeniusHelpController showWindow];
}

- (IBAction) openSupportSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://groups.yahoo.com/group/genius-talk/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
