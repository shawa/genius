//
//  IconTextFieldCell.h
//  Genius
//
//  Created by John R Chang on Mon Jan 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IconTextFieldCell : NSTextFieldCell {
    NSImage * _image;
}

- (void)setImage:(NSImage *)image;
- (NSImage *)image;

@end
