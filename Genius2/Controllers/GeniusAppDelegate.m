#import "GeniusAppDelegate.h"

#import "GeniusValueTransformers.h"

#import "GeniusPreferencesController.h"
#import "GeniusHelpController.h"

#import "GeniusPreferences.h"


@implementation GeniusAppDelegate

+ (void) initialize
{
	// Register value transformers
	NSValueTransformer * transformer = [[[GeniusFloatPercentTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GeniusFloatPercentTransformer"];
	
	transformer = [[[GeniusEnabledBooleanToTextColorTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GeniusEnabledBooleanToTextColorTransformer"];


	[GeniusPreferences registerDefaults];
}


// Application menu

- (IBAction) showPreferences:(id)sender
{
	GeniusPreferencesController * pc = [GeniusPreferencesController sharedPreferencesController];
	[pc runModal];
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


// Study menu

- (IBAction) toggleSoundEffects:(id)sender
{
	// do nothing - NSUserDefaultsController handles this in the nib
	// This is defined for automatic menu item enabling
}


// Help menu

- (IBAction) showHelpWindow:(id)sender
{
	static GeniusHelpController * sHelpController = nil;
	if (sHelpController == nil)
	{
		NSString * title = NSLocalizedString(@"Genius Help", nil);
		sHelpController = [[GeniusHelpController alloc] initWithResourceName:@"Help" title:title];
	}

    [sHelpController showWindow:sender];
}

- (IBAction) openSupportSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://groups.yahoo.com/group/genius-talk/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end


@implementation GeniusAppDelegate (NSApplicationDelegate)

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    srandom(time(NULL) * getpid());
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	// LastVersionRun
    NSBundle * mainBundle = [NSBundle mainBundle];
    NSString * currentVersion = [mainBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey];
    NSString * lastVersion = [ud stringForKey:@"LastVersionRun"];
    if (!lastVersion || [currentVersion compare:lastVersion] > NSOrderedSame)
    {
        [self performSelector:@selector(showHelpWindow:) withObject:self afterDelay:0.0];
        [ud setObject:currentVersion forKey:@"LastVersionRun"];
    }
}

@end
