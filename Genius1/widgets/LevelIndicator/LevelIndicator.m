//
//  LevelIndicator.m
//
//  Created by John R Chang on Fri Oct 08 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

/*
	NOTE: Obsolete in Mac OS X 10.4 Tiger and later.  See AppKit/NSLevelIndicator.h
*/


#import "LevelIndicator.h"

//! An NSView which displays \a _doubleValue as a colored bar against a white background.
/*! 
    Similar to the SimpleProgressView but using images instead of drawing.
    @todo Replace LevelInticator with NSLevelIndicator.
*/
@implementation LevelIndicator

//! Initializes and returns a newly allocated LevelInicator object with a specified frame rectangle.
- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    _leftImage = [[NSImage imageNamed:@"progress_left"] retain];
    _rightImage = [[NSImage imageNamed:@"progress_right"] retain];
    _bottomImage = [[NSImage imageNamed:@"progress_bottom"] retain];
    _backImage = [[NSImage imageNamed:@"progress_back"] retain];
    _fillImage = [[NSImage imageNamed:@"progress_fillgreen"] retain];

    _minValue = 0.0;
    _maxValue = 100.0;
    _doubleValue = 50.0;
    
    return self;
}

//! Deallocates the memory occupied by the receiver.
- (void) dealloc
{
    [_leftImage release];
    [_rightImage release];
    [_bottomImage release];
    [_backImage release];
    [_fillImage release];

    [super dealloc];
}

//! _doubleValue getter.
- (double)doubleValue
{
    return _doubleValue;
}

//! _doubleValue setter.
- (void)setDoubleValue:(double)doubleValue
{
    _doubleValue = doubleValue;
    
    [self setNeedsDisplay:YES];
}

//! _minValue getter.
- (double)minValue
{
    return _minValue;
}

//! _minValue setter.
- (void)setMinValue:(double)newMinimum
{
    _minValue = newMinimum;

    [self setNeedsDisplay:YES];
}

//! _maxValue getter.
- (double)maxValue
{
    return _maxValue;
}

//! _maxValue setter.
- (void)setMaxValue:(double)newMaximum
{
    _maxValue = newMaximum;

    [self setNeedsDisplay:YES];
}

//! helper method for drawing the back and fill rectangles.
- (void)drawBarInside:(NSRect)aRect
{
    float percent = (_doubleValue - _minValue) / (_maxValue - _minValue);
    NSRect srcRect = {};
    
    // _fillImage
    srcRect.size = [_fillImage size];
    NSRect fillRect = aRect;
    fillRect.size.width *= percent;
    [_fillImage drawInRect:fillRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];
    
    // _backImage
    srcRect.size = [_backImage size];
    NSRect backRect = aRect;
    backRect.origin.x += fillRect.size.width;
    backRect.size.width = (aRect.size.width - fillRect.size.width);
    [_backImage drawInRect:backRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];
}

//! Renders the edge images and then uses #_doubleValue to calculate a percentag fill.
- (void)drawRect:(NSRect)aRect
{    
    NSRect bounds = [self bounds];
    NSRect srcRect = {};
    NSPoint origin;

    // _leftImage
    srcRect.size = [_leftImage size];
    origin = NSZeroPoint;
    [_leftImage drawAtPoint:origin fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];
    
    // _rightImage
    srcRect.size = [_rightImage size];
    origin.x = bounds.size.width - srcRect.size.width;
    [_rightImage drawAtPoint:origin fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];

    // _bottomImage
    srcRect.size = [_bottomImage size];
    NSRect bottomRect = bounds;
    bottomRect.origin.x = [_leftImage size].width;
    bottomRect.size.width -= (bottomRect.origin.x * 2);
    bottomRect.size.height = srcRect.size.height;
    [_bottomImage drawInRect:bottomRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];

    // -drawBarInside:
    NSRect insideRect = NSInsetRect(bottomRect, -2.0, 0.0);
    insideRect.size.height = bounds.size.height - bottomRect.size.height;
    insideRect.origin.y = bottomRect.size.height;

    [self drawBarInside:insideRect];
}

@end
