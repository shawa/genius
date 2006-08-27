//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>


@interface GeniusStringDiff : NSObject

+ (NSAttributedString *) attributedStringHighlightingDifferencesFromString:(NSString *)origString toString:(NSString *)newString;

@end
