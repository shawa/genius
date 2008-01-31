//
//  ParagraphStyleFormatter.h
//
//  Created by John R Chang on Thu Feb 05 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Foundation/Foundation.h>


@interface ParagraphStyleFormatter : NSFormatter {
    NSMutableParagraphStyle * _paragraphStyle;  //!< Used in formating our string.
}

- (void)setLineBreakMode:(NSLineBreakMode)mode;

@end
