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

#import "GeniusAppDelegate.h"

#import "GeniusHelpWindowController.h"
#import "GeniusItem.h"
#import "GeniusDocument.h"
#import "GeniusDocumentFile.h"

#import "GeniusPreferencesController.h"

//! Standard Cocoa Application delegate.
@implementation GeniusAppDelegate

//! Initializes application with factory defaults.
+ (void) initialize
{
	// Register defaults
	NSDictionary * defaults = [NSDictionary dictionaryWithObjectsAndKeys:
        
		[NSNumber numberWithBool:YES], GeniusPreferencesUseSoundEffectsKey,
		[NSNumber numberWithBool:YES], GeniusPreferencesQuizUseFullScreenKey,
		[NSNumber numberWithBool:YES], GeniusPreferencesQuizUseVisualErrorsKey,
		[NSNumber numberWithInt:GeniusPreferencesQuizSimilarMatchingMode], GeniusPreferencesQuizMatchingModeKey,
        
		[NSNumber numberWithInt:10], GeniusPreferencesQuizNumItemsKey,
		[NSNumber numberWithInt:20], GeniusPreferencesQuizFixedTimeMinKey,
		[NSNumber numberWithFloat:50.0], GeniusPreferencesQuizReviewLearnFloatKey,
        
		NULL];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

//! Releases @a preferencesController and frees memory.
- (void) dealloc {
    [preferencesController release];
    [helpController release];
    [super dealloc];
}

//! Instanciates a GeniusPreferencesController if needed and displays it.
- (IBAction) showPreferences:(id)sender
{
    if (!preferencesController) {
        preferencesController = [[GeniusPreferencesController alloc] init];        
    }
    [preferencesController showWindow:self];
}


//! Opens Source Forge project website via finder.
- (IBAction) showWebSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://sourceforge.net/projects/genius"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

//! Opens the yahoo genius talk website via finder.
- (IBAction) showSupportSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://groups.yahoo.com/group/genius-talk"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

//! Empty method to ensure that our sound toggle menu stays active.
/*!
  The state of the toggle menu is bound directly(through a binding) to the use sound effects user preference.
  However without a target and action it wouldn't remain enabled.
*/
- (IBAction) toggleSoundEffects:(id)sender
{

}

//! Presents basic help window @see GeniusHelpWindowController#showWindow
- (IBAction) showHelpWindow:(id)sender
{
    if (!helpController) {
        helpController = [[GeniusHelpWindowController alloc] init];
    }
    
    [[helpController window] center];
    [helpController showWindow:self];
}

//! Wraps call to GeniusDocument(FileFormat)::importFile:
- (IBAction)importFile:(id)sender
{
    [GeniusDocument importFile:sender];
}

//! Checks current running version against previous.
/*
    The implementation of this method was complicated by a change in version strings.
    from date oriented to a simple ever climbing build number.  Consult tes cases for
    some examples.
 */
- (BOOL) isNewerVersion: (NSString*) currentVersion lastVersion:(NSString*)lastVersion
{
    if (!lastVersion && currentVersion)
        return YES;
    else if (!currentVersion && lastVersion)
        return NO;
    else if (!lastVersion && !currentVersion)
        return NO;

    if (([currentVersion length] == 8)  && ([lastVersion length] == 8))
        return ([currentVersion compare:lastVersion] > NSOrderedSame);
    
    else if (([currentVersion length] == 8)  && ([lastVersion length] != 8))
        return NO;

    else if (([currentVersion length] != 8)  && ([lastVersion length] == 8))
        return YES;

    else if (([currentVersion length] != 8)  && ([lastVersion length] != 8))
        return [currentVersion intValue] > [lastVersion intValue];
    

    return NO;
}

@end


@implementation GeniusAppDelegate(NSApplicationDelegate)

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    srandom(time(NULL));
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];

	// LastVersionRun
    NSBundle * mainBundle = [NSBundle mainBundle];
    NSString * currentVersion = [mainBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey];
    NSString * lastVersion = [userDefaults stringForKey:@"LastVersionRun"];
    
    if ([self isNewerVersion: currentVersion lastVersion: lastVersion])
    {
        [self performSelector:@selector(showHelpWindow:) withObject:self afterDelay:0.0];
        [userDefaults setObject:currentVersion forKey:@"LastVersionRun"];
    }

	// OpenFiles
    NSArray * openFiles = [userDefaults objectForKey:@"OpenFiles"];
	if (openFiles)
	{
		NSString * path;
		NSEnumerator * pathEnumerator = [openFiles objectEnumerator];
		while ((path = [pathEnumerator nextObject]))
			[self application:NSApp openFile:path];
	}
}

/*
    This is a hack to suppress new window creation in the case where an empty window already exists.
*/
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSDocumentController * dc = [NSDocumentController sharedDocumentController];
    GeniusDocument * doc = (GeniusDocument *)[dc currentDocument];

    NSArray * documents = [dc documents];
    if (doc && [documents count] == 1 && [[doc pairs] count] == 0 && [doc isDocumentEdited] == NO)
    {
        BOOL succeed = [doc readFromFile:filename ofType:@"Genius Document"];
        if (!succeed)
            return NO;

        [doc reloadInterfaceFromModel];
        return YES;
    }
    else
    {
        doc = [dc openDocumentWithContentsOfFile:filename display:YES];
        return (doc != nil);
    }
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

    [[NSUserDefaults standardUserDefaults] setObject:documentPaths forKey:@"OpenFiles"];
}

@end
