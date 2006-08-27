//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

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
