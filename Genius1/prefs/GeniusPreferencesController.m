//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusPreferencesController.h"


NSString * GeniusPreferencesUseSoundEffectsKey = @"UseSoundEffects";

NSString * GeniusPreferencesListTextSizeModeKey = @"ListTextSizeMode";
NSString * GeniusPreferencesQuizUseFullScreenKey = @"UseFullScreen";
NSString * GeniusPreferencesQuizUseVisualErrorsKey = @"QuizUseVisualErrors";
NSString * GeniusPreferencesQuizMatchingModeKey = @"QuizMatchingMode";

NSString * GeniusPreferencesQuizChooseModeKey = @"QuizChooseMode";
NSString * GeniusPreferencesQuizNumItemsKey = @"QuizNumItems";
NSString * GeniusPreferencesQuizFixedTimeMinKey = @"QuizFixedTimeMin";
NSString * GeniusPreferencesQuizReviewLearnFloatKey = @"QuizReviewLearnFloat";

//! Standard NSWindowController subclass for handling interactionn with preferences window.
@implementation GeniusPreferencesController

//! Returns instance initialized with "Preferences" nib.
- (id) init {
    self = [super initWithWindowNibName: @"Preferences"];
    return self;
}

@end
