/* GeniusWelcomePanel */

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
