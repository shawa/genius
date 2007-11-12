//
//  NSStringSimiliarity.h
//
//  Created by John R Chang on Thu Dec 25 2003.
//  Modified by John R Chang on Sun Aug 27 2006.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Foundation/Foundation.h>


@interface NSString (Similiarity)

- (float) isSimilarToString:(NSString *)aString;

@end
