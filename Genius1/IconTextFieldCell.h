//
//  IconTextFieldCell.h
//
//  Created by John R Chang on Mon Jan 12 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Cocoa/Cocoa.h>


@interface IconTextFieldCell : NSTextFieldCell {
    NSImage * _image; //!< The image to display at left in cell.
}

- (void)setImage:(NSImage *)image;
- (NSImage *)image;

@end
