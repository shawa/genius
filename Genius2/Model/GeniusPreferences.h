//
//  GeniusPreferences.h
//  Genius2
//
//  Created by John R Chang on 2005-10-11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


// Study menu
extern NSString * GeniusPreferencesUseSoundEffectsKey;				// bool

// Preferences panel
extern NSString * GeniusPreferencesListTextSizeModeKey;				// integer (0-2)
extern NSString * GeniusPreferencesQuizUseFullScreenKey;			// bool
extern NSString * GeniusPreferencesQuizUseVisualErrorsKey;			// bool
extern NSString * GeniusPreferencesQuizMatchingModeKey;				// integer (0-2)

extern NSString * GeniusPreferencesQuizNumItemsKey;					// integer (1-)
extern NSString * GeniusPreferencesQuizFixedTimeMinKey;				// integer (1-)
extern NSString * GeniusPreferencesQuizReviewLearnFloatKey;			// float (0.0-100.0)

enum {
	GeniusPreferencesQuizExactMatchingMode = 0,
	GeniusPreferencesQuizCaseInsensitiveMatchingMode,
	GeniusPreferencesQuizSimilarMatchingMode
};


@interface GeniusPreferences : NSObject
+ (void) registerDefaults;
@end
