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
	double _doubleValue; //!< The current value to display.
	double _minValue; //!< The minium expected value for _doubleValue.
	double _maxValue; //!< The maximum expected value for \a _doubleValue.
}

- (double)doubleValue; 
- (void)setDoubleValue:(double)doubleValue;

- (double)minValue;
- (void)setMinValue:(double)newMinimum;

- (double)maxValue;
- (void)setMaxValue:(double)newMaximum;

@end
