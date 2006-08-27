//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusHelpWindowController.h"

@implementation GeniusHelpWindowController

- (void) awakeFromNib
{
	NSString * path = [[NSBundle mainBundle] pathForResource:@"Help" ofType:@"rtf"];
	[textView readRTFDFromFile:path];
}

+ (void) showWindow
{
	GeniusHelpWindowController * wc = [[GeniusHelpWindowController alloc] initWithWindowNibName:@"Help"];
    [[wc window] center];
    [wc showWindow:self];
}

@end
