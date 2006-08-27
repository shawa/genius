//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

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


@implementation GeniusHelpController (WebPolicyDelegate)

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
	if ([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] == WebNavigationTypeOther)
		[listener use];
	else
	{
		[listener ignore];

		NSURL * url = [actionInformation objectForKey:WebActionOriginalURLKey];
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
}

@end

