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
#import "GeniusDocumentPrivate.h"   // reloadInterfaceFromModel
#import "GeniusDocumentFile.h"
#include <unistd.h> // getpid


@implementation GeniusAppDelegate

- (IBAction) showTipJar:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://web.mac.com/jrc/Genius/#tipjar"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction) showWebSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://web.mac.com/jrc/Genius/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction) showSupportSite:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://groups.yahoo.com/group/genius-talk/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction) toggleSoundEffects:(id)sender
{
	// just to keep the menu item enabled
}

- (IBAction) showHelpWindow:(id)sender
{
    [GeniusHelpWindowController showWindow];
}


- (IBAction)importFile:(id)sender
{
    [GeniusDocument importFile:sender];
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

	// -registerDefaults: doesn't work here for some reason
/*	NSDictionary * registrationDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:NSOnState], @"useSoundEffects", nil];
	[ud registerDefaults:registrationDict];*/
	[ud setBool:YES forKey:@"useSoundEffects"];
	
	// LastVersionRun
    NSBundle * mainBundle = [NSBundle mainBundle];
    NSString * currentVersion = [mainBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey];
    NSString * lastVersion = [ud stringForKey:@"LastVersionRun"];
    if (!lastVersion || [currentVersion compare:lastVersion] > NSOrderedSame)
    {
        [self performSelector:@selector(showHelpWindow:) withObject:self afterDelay:0.0];
        [ud setObject:currentVersion forKey:@"LastVersionRun"];
    }

	// OpenFiles
    NSArray * openFiles = [ud objectForKey:@"OpenFiles"];
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

    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:documentPaths forKey:@"OpenFiles"];
}

@end
