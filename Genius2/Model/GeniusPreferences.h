//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Foundation/Foundation.h>


// Study menu
extern NSString * GeniusPreferencesUseSoundEffectsKey;				// bool

// Preferences panel
extern NSString * GeniusPreferencesListTextSizeModeKey;				// integer (0-2)
extern NSString * GeniusPreferencesQuizUseFullScreenKey;			// bool
extern NSString * GeniusPreferencesQuizUseVisualErrorsKey;			// bool
extern NSString * GeniusPreferencesQuizMatchingModeKey;				// integer (0-2)
enum {
	GeniusPreferencesQuizExactMatchingMode = 0,
	GeniusPreferencesQuizCaseInsensitiveMatchingMode,
	GeniusPreferencesQuizSimilarMatchingMode
};

extern NSString * GeniusPreferencesQuizChooseModeKey;				// integer (0-1)
enum {
	GeniusPreferencesQuizNumItemsChooseMode = 0,
	GeniusPreferencesQuizFixedTimeChooseMode,
};
extern NSString * GeniusPreferencesQuizNumItemsKey;					// integer (1-)
extern NSString * GeniusPreferencesQuizFixedTimeMinKey;				// integer (1-)
extern NSString * GeniusPreferencesQuizReviewLearnFloatKey;			// float (0.0-100.0)


@interface GeniusPreferences : NSObject
+ (void) registerDefaults;
@end
