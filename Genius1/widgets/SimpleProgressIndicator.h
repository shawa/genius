//
//  SimpleProgressIndicator.h
//
//  Created by John R Chang on Fri Oct 08 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Cocoa/Cocoa.h>

@interface SimpleProgressIndicator : NSView
{
	double _doubleValue;
	double _minValue;
	double _maxValue;
}

- (double)doubleValue;
- (void)setDoubleValue:(double)doubleValue;

- (double)minValue;
- (void)setMinValue:(double)newMinimum;

- (double)maxValue;
- (void)setMaxValue:(double)newMaximum;

@end
