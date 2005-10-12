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
extern NSString * GeniusPreferencesUseFullScreenKey;				// bool

// Preferences panel
extern NSString * GeniusPreferencesListTextSizeModeKey;				// integer (0-1)
extern NSString * GeniusPreferencesQuizUseVisualErrorsKey;			// bool
extern NSString * GeniusPreferencesQuizReviewLearnSliderFloatKey;	// float (0.0-100.0)
extern NSString * GeniusPreferencesQuizMatchingModeKey;				// integer (0-2)


enum {
	GeniusPreferencesQuizExactMatchingMode = 0,
	GeniusPreferencesQuizCaseInsensitiveMatchingMode,
	GeniusPreferencesQuizSimilarMatchingMode
};


@interface GeniusPreferences : NSObject
+ (void) registerDefaults;
@end
