/* QuizOptionsController */

#import <Cocoa/Cocoa.h>

@interface QuizOptionsController : NSWindowController
{
    IBOutlet id fixedTimeTextField;
    IBOutlet id numItemsTextField;
    IBOutlet id quizModeRadioMatrix;
    IBOutlet id learnMoreTextView;
    IBOutlet id reviewLearnSlider;
}

- (id) init;
- (int) runModal;

- (IBAction)cancel:(id)sender;
- (IBAction)quiz:(id)sender;

@end
