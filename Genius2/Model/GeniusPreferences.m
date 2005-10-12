//
//  GeniusPreferences.m
//  Genius2
//
//  Created by John R Chang on 2005-10-11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusPreferences.h"


NSString * GeniusPreferencesUseSoundEffectsKey = @"useSoundEffects";
NSString * GeniusPreferencesUseFullScreenKey = @"useFullScreen";

NSString * GeniusPreferencesListTextSizeModeKey = @"ListTextSizeMode";
NSString * GeniusPreferencesQuizUseVisualErrorsKey = @"QuizUseVisualErrors";
NSString * GeniusPreferencesQuizReviewLearnSliderFloatKey = @"QuizReviewLearnSliderValue";
NSString * GeniusPreferencesQuizMatchingModeKey = @"QuizMatchingMode";


@implementation GeniusPreferences

+ (void) registerDefaults
{
	// Register defaults
	NSDictionary * defaults = [NSDictionary dictionaryWithObjectsAndKeys:

		[NSNumber numberWithBool:YES], GeniusPreferencesUseSoundEffectsKey,
		[NSNumber numberWithBool:YES], GeniusPreferencesUseFullScreenKey,

		[NSNumber numberWithBool:YES], GeniusPreferencesQuizUseVisualErrorsKey,
		[NSNumber numberWithFloat:50.0], GeniusPreferencesQuizReviewLearnSliderFloatKey,
		[NSNumber numberWithInt:GeniusPreferencesQuizSimilarMatchingMode], GeniusPreferencesQuizMatchingModeKey,

		NULL];

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

@end
