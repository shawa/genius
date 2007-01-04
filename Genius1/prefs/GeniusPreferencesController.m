//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusPreferencesController.h"


@implementation GeniusPreferencesController

// file:///Developer/ADC%20Reference%20Library/documentation/Cocoa/Conceptual/Documents/Tasks/FAQ.html#//apple_ref/doc/uid/20000954-1081485
+ (id) sharedPreferencesController
{
	static GeniusPreferencesController * sController = nil;
	if (sController == nil)
		sController = [[GeniusPreferencesController alloc] initWithWindowNibName:@"Preferences"];
	return sController;
}

- (void) runModal
{
	[NSApp runModalForWindow:[self window]];
}

@end


@implementation GeniusPreferencesController (NSWindowDelegate)

- (void)windowWillClose:(NSNotification *)aNotification
{
	[NSApp stopModal];
}

@end
