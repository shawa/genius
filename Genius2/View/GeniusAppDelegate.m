#import "GeniusAppDelegate.h"

#import "GeniusValueTransformers.h"


@implementation GeniusAppDelegate

+ (void) initialize
{
//	NSUserDefaultsController * udc = [NSUserDefaultsController sharedUserDefaultsController];
	NSDictionary * defaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], @"useSoundEffects", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

	GeniusFloatPercentTransformer * transformer = [[[GeniusFloatPercentTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GeniusFloatPercentTransformer"];
}


- (IBAction) openTipJarSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://homepage.mac.com/jrc/Software/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction) openSupportSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://groups.yahoo.com/group/genius-talk/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction) openFileSharingSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://www.geniusfiles.info/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
