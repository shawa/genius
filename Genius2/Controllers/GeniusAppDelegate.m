//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusAppDelegate.h"

#import "GeniusValueTransformers.h"

#import "GeniusPreferencesController.h"
#import "GeniusHelpController.h"

#import "GeniusPreferences.h"

#import "GeniusDocument.h"


@implementation GeniusAppDelegate

+ (void) initialize
{
	// Register value transformers
	NSValueTransformer * transformer = [[[GeniusFloatPercentTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GeniusFloatPercentTransformer"];
	
	transformer = [[[GeniusEnabledBooleanToTextColorTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GeniusEnabledBooleanToTextColorTransformer"];

	transformer = [[[GeniusBooleanToStringTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GeniusBooleanToStringTransformer"];

	transformer = [[[GeniusFloatValueTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"GeniusFloatValueTransformer"];


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
    NSURL * url = [NSURL URLWithString:@"http://web.mac.com/jrc/Genius/#tipjar"];
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

- (IBAction) openGeniusWebSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://web.mac.com/jrc/Genius/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
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

	_isNewVersion = NO;

	// LastVersionRun
    NSBundle * mainBundle = [NSBundle mainBundle];
    NSString * currentVersion = [mainBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey];
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    NSString * lastVersion = [ud stringForKey:@"LastVersionRun"];
    if ((lastVersion == nil) || ([currentVersion isEqual:lastVersion] == NO))
	{
		_isNewVersion = YES;

        [ud setObject:currentVersion forKey:@"LastVersionRun"];
        [ud setObject:nil forKey:@"OpenFiles"];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if (_isNewVersion)
	{
        [self performSelector:@selector(showHelpWindow:) withObject:self afterDelay:0.0];
    }
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	// OpenFiles
	NSDocumentController * dc = [NSDocumentController sharedDocumentController];
    NSArray * openFiles = [ud objectForKey:@"OpenFiles"];
	if (openFiles && [openFiles count] > 0 && _isNewVersion == NO)
	{
		NSString * path;
		NSEnumerator * pathEnumerator = [openFiles objectEnumerator];
		while ((path = [pathEnumerator nextObject]))
		{
			NSURL * url = [NSURL fileURLWithPath:path];
			[dc openDocumentWithContentsOfURL:url display:YES error:NULL];
		}
		return NO;
	}

	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Get all document paths
	NSMutableArray * documentPaths = [NSMutableArray array];
	NSArray * documents = [NSApp orderedDocuments];
	NSEnumerator * documentEnumerator = [documents reverseObjectEnumerator];
	NSDocument * document;
	while ((document = [documentEnumerator nextObject]))
	{
		NSString * path = [document fileName];
		if (path)
			[documentPaths addObject:path];
	}

    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:documentPaths forKey:@"OpenFiles"];
}

@end
