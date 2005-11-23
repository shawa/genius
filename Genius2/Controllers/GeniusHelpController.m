#import "GeniusHelpController.h"

#import <WebKit/WebKit.h>


@implementation GeniusHelpController

- (id) initWithResourceName:(NSString *)resourceName title:(NSString *)title
{
	self = [super initWithWindowNibName:@"Help"];

	[self window]; // load window
	
	NSString * path = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"html"];
	NSString * string = [NSString stringWithContentsOfFile:path];
	[[webView mainFrame] loadHTMLString:string baseURL:nil];

	[[self window] setTitle:title];
    [[self window] center];
	
	return self;
}

@end
