/* GeniusHelpWindowController */

#import <Cocoa/Cocoa.h>

@interface GeniusHelpController : NSWindowController
{
    IBOutlet id webView;
}

- (id) initWithResourceName:(NSString *)resourceName title:(NSString *)title;

@end
