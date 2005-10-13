//
//  ColorView.h
//  Genius2
//
//  Created by John R Chang on 2005-10-12.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ColorView : NSView {
	NSColor * _backgroundColor;
	NSColor * _frameColor;
}

- (void) setBackgroundColor:(NSColor *)color;
- (void) setFrameColor:(NSColor *)color;

@end
