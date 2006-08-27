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
    NSImage * _leftImage, * _rightImage, * _bottomImage;
    NSImage * _backImage, * _fillImage;
    double _minValue, _maxValue;
    double _doubleValue;
}

- (double)doubleValue;
- (void)setDoubleValue:(double)doubleValue;

- (double)minValue;
- (void)setMinValue:(double)newMinimum;

- (double)maxValue;
- (void)setMaxValue:(double)newMaximum;

@end
