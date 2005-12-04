/* QuizOptionsController */

#import <Cocoa/Cocoa.h>

@interface QuizOptionsController : NSWindowController
{
    IBOutlet id quizModeRadioMatrix;
    IBOutlet id numItemsTextField;
	IBOutlet id numItemsStepper;
    IBOutlet id fixedTimeTextField;
    IBOutlet id reviewLearnSlider;

    IBOutlet id learnMoreTextView;
}

- (id) init;
- (int) runModal;

@end
