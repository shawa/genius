//
//  SimpleProgressIndicator.m
//
//  Created by John R Chang on Fri Oct 08 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "SimpleProgressIndicator.h"

//! An NSView which displays \a _doubleValue as a colored bar against a white background.
@implementation SimpleProgressIndicator

//! Initializes and returns a newly allocated SimpleProgressIndicator object with a specified frame rectangle.
- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	_doubleValue = 0.0;
	_minValue = 0.0;
	_maxValue = 100.0;
	return self;
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

//! _minValue setter.
- (void)setMaxValue:(double)newMaximum
{
	_maxValue = newMaximum;
	[self setNeedsDisplay:YES];
}

/// Renders the SimpleProgressIndicator view as a partially filled white box.
/*!
 * The users selected text background color is used to fill in the white box.  The percentage
 * filled is calculated as <tt>(_doubleValue - _minValue) / (_maxValue - _minValue)</tt>.
 */
- (void)drawRect:(NSRect)aRect
{
    /// @todo Check bounds on theses values
    float percent = (_doubleValue - _minValue) / (_maxValue - _minValue);
	float w = percent * aRect.size.width;

	[[NSColor selectedTextBackgroundColor] set];
	//[[NSColor alternateSelectedControlColor] set];
	NSRect foregroundRect = aRect;
	foregroundRect.size.width = w;
	NSRectFill(foregroundRect);

	[[NSColor whiteColor] set];
	NSRect backgroundRect = aRect;
	backgroundRect.size.width = (1.0 - percent) * aRect.size.width;
	backgroundRect.origin.x =+ w;
	NSRectFill(backgroundRect);
}

@end
