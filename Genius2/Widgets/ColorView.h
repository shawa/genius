//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>


@interface ColorView : NSView {
	NSColor * _backgroundColor;
	NSColor * _frameColor;
}

- (void) setBackgroundColor:(NSColor *)color;
- (void) setFrameColor:(NSColor *)color;

@end
