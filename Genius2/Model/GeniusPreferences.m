//
//  GeniusPreferences.m
//  Genius2
//
//  Created by John R Chang on 2005-10-11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusPreferences.h"


NSString * GeniusPreferencesUseSoundEffectsKey = @"UseSoundEffects";

NSString * GeniusPreferencesListTextSizeModeKey = @"ListTextSizeMode";
NSString * GeniusPreferencesQuizUseFullScreenKey = @"UseFullScreen";
NSString * GeniusPreferencesQuizUseVisualErrorsKey = @"QuizUseVisualErrors";
NSString * GeniusPreferencesQuizMatchingModeKey = @"QuizMatchingMode";

NSString * GeniusPreferencesQuizChooseModeKey = @"QuizChooseMode";
NSString * GeniusPreferencesQuizNumItemsKey = @"QuizNumItems";
NSString * GeniusPreferencesQuizFixedTimeMinKey = @"QuizFixedTimeMin";
NSString * GeniusPreferencesQuizReviewLearnFloatKey = @"QuizReviewLearnFloat";


@implementation GeniusPreferences

+ (void) registerDefaults
{
	// Register defaults
	NSDictionary * defaults = [NSDictionary dictionaryWithObjectsAndKeys:

		[NSNumber numberWithBool:YES], GeniusPreferencesUseSoundEffectsKey,
		[NSNumber numberWithBool:YES], GeniusPreferencesQuizUseFullScreenKey,
		[NSNumber numberWithBool:YES], GeniusPreferencesQuizUseVisualErrorsKey,
		[NSNumber numberWithInt:GeniusPreferencesQuizSimilarMatchingMode], GeniusPreferencesQuizMatchingModeKey,

		[NSNumber numberWithInt:10], GeniusPreferencesQuizNumItemsKey,
		[NSNumber numberWithInt:20], GeniusPreferencesQuizFixedTimeMinKey,
		[NSNumber numberWithFloat:50.0], GeniusPreferencesQuizReviewLearnFloatKey,

		NULL];

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

@end
