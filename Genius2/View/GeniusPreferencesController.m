//
//  GeniusPreferencesController.m
//  Genius2
//
//  Created by John R Chang on 2005-10-04.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusPreferencesController.h"


@implementation GeniusPreferencesController

// file:///Developer/ADC%20Reference%20Library/documentation/Cocoa/Conceptual/Documents/Tasks/FAQ.html#//apple_ref/doc/uid/20000954-1081485
+ (id) sharedPreferencesController
{
	static GeniusPreferencesController * sController = nil;
	if (sController == nil)
		sController = [[GeniusPreferencesController alloc] initWithWindowNibName:@"GeniusPreferences"];
	return sController;
}

@end
