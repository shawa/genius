//
//  LevelIndicator.h
//
//  Created by John R Chang on Fri Oct 08 2004.
//  This code is distributed under Creative Commons Attribution 2.0.
//  http://creativecommons.org/licenses/by/2.0/
//

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
