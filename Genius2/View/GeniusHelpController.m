#import "GeniusHelpController.h"

@implementation GeniusHelpController

- (void) awakeFromNib
{
	NSString * path = [[NSBundle mainBundle] pathForResource:@"Help" ofType:@"rtf"];
	[textView readRTFDFromFile:path];
}

+ (void) showWindow
{
	NSString * title = NSLocalizedString(@"Genius Help", nil);
	GeniusHelpController * wc = [[GeniusHelpController alloc] initWithWindowNibName:@"Documentation"];
	[[wc window] setTitle:title];
    [[wc window] center];
    [wc showWindow:self];
}

@end
