//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

@interface GeniusWelcomePanel : NSWindowController
{
    IBOutlet id dontRemindSwitch;
}

+ (GeniusWelcomePanel *) sharedWelcomePanel;

- (BOOL) runModal;

- (IBAction)goBack:(id)sender;
- (IBAction)continue:(id)sender;
@end
