//
//  VisualStringDiff.h
//  test
//
//  Created by John R Chang on 2004-12-01.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VisualStringDiff : NSObject

+ (NSAttributedString *) attributedStringHighlightingDifferencesFromString:(NSString *)origString toString:(NSString *)newString;

@end
