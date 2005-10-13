//
//  NSStringSimiliarity.h
//
//  Created by John R Chang on Thu Dec 25 2003.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Foundation/Foundation.h>


@interface NSString (Similiarity)

/*
    Returns 0.0 <= x <= 1.0.  0.0 == not equal (or error), 1.0 == equal.
    Uses Search Kit (a.k.a. AIAT, V-Twin) technology.
*/
- (float) isSimilarToString:(NSString *)aString;

@end
