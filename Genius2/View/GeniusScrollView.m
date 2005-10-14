//
//  GeniusScrollView.m
//  Genius2
//
//  Created by John R Chang on 2005-10-14.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusScrollView.h"


@implementation GeniusScrollView

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[super drawRect:rect];
	
	[[NSColor colorWithCalibratedWhite:0.65 alpha:1.0] set];
	rect = NSInsetRect([self bounds], -1.0, 0.0);	// XXX: hack to draw only the top and bottom borders
	NSFrameRect(rect);
}

@end
