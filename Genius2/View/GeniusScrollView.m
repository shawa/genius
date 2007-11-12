//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusScrollView.h"

//! A view with missing side boarders in which our table view is displayed.
@implementation GeniusScrollView

//! XXX: hack to draw only the top and bottom borders
- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[super drawRect:rect];
	
	[[NSColor colorWithCalibratedWhite:0.65 alpha:1.0] set];
	rect = NSInsetRect([self bounds], -1.0, 0.0);	
	NSFrameRect(rect);
}

@end
