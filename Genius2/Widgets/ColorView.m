//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "ColorView.h"


@implementation ColorView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_backgroundColor = [[NSColor windowBackgroundColor] retain];
		_frameColor = [[NSColor grayColor] retain];
    }
    return self;
}

- (void) dealloc
{
	[_backgroundColor release];
	[_frameColor release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[_backgroundColor set];
	NSRectFill(rect);
	
	rect = NSInsetRect([self bounds], -1.0, 0.0);	// XXX: hack to draw only the top and bottom borders
	[_frameColor set];
	NSFrameRect(rect);
}


- (void) setBackgroundColor:(NSColor *)color
{
	[_backgroundColor release];
	_backgroundColor = [color copy];
}

- (void) setFrameColor:(NSColor *)color
{
	[_frameColor release];
	_frameColor = [color copy];
}

@end
