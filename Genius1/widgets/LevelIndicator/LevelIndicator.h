//
//  LevelIndicator.h
//
//  Created by John R Chang on Fri Oct 08 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

/*
	NOTE: Obsolete in Mac OS X 10.4 Tiger and later.  See AppKit/NSLevelIndicator.h
*/

#import <Cocoa/Cocoa.h>


@interface LevelIndicator : NSView
{
    NSImage * _leftImage;  //!< 3-d effect for left edge of view
    NSImage * _rightImage;  //!< 3-d effect for right edge of view
    NSImage * _bottomImage;  //!< 3-d effect for bottom edge of view
    NSImage * _backImage;  //!< 3-d effect for top edge of view with background color
    NSImage * _fillImage;  //!< 3-d effect for top edge of view with progress color
    double _minValue; //!< The minium expected value for _doubleValue.
    double _maxValue; //!< The maximum expected value for \a _doubleValue.
    double _doubleValue;  //!< The current value to display.
}

- (double)doubleValue;
- (void)setDoubleValue:(double)doubleValue;

- (double)minValue;
- (void)setMinValue:(double)newMinimum;

- (double)maxValue;
- (void)setMaxValue:(double)newMaximum;

@end
