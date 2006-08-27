//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

@interface GeniusHelpController : NSWindowController
{
    IBOutlet id webView;
}

- (id) initWithResourceName:(NSString *)resourceName title:(NSString *)title;

@end
