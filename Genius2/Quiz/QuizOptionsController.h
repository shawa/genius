/* QuizOptionsController */

#import <Cocoa/Cocoa.h>

@interface QuizOptionsController : NSWindowController
{
    IBOutlet id quizModeRadioMatrix;
    IBOutlet id fixedTimeTextField;
    IBOutlet id numItemsTextField;
	IBOutlet id numItemsStepper;
    IBOutlet id reviewLearnSlider;

    IBOutlet id learnMoreTextView;
}

- (id) init;
- (int) runModal;


- (NSMatrix *) quizModeRadioMatrix;
- (NSTextField *) fixedTimeTextField;
- (NSTextField *) numItemsTextField;
- (NSSlider *) reviewLearnSlider;

@end
