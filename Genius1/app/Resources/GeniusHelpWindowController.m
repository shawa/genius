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
