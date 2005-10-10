//
//  NSStringSimiliarity.h
//  Genius
//
//  Created by John R Chang on Thu Dec 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Similiarity)

/*
    Returns 0.0 <= x <= 1.0.  0.0 == not equal (or error), 1.0 == equal.
    Uses SearchKit (AIAT) technology for word-based analysis.
    FIX: Doesn't set kSKLanguageTypes.
*/
- (float)isSimilarToString:(NSString *)aString;

@end
