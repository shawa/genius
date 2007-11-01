//
//  SimpleProgressIndicator.h
//
//  Created by John R Chang on Fri Oct 08 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Cocoa/Cocoa.h>
/// An NSView which displays \a _doubleValue as a colored bar against a white background.
@interface SimpleProgressIndicator : NSView
{
	double _doubleValue; //!< The current value to display.
	double _minValue; //!< The minium expected value for _doubleValue.
	double _maxValue; //!< The maximum expected value for \a _doubleValue.
}

//! _doubleValue getter.
- (double)doubleValue; 
//! _doubleValue setter.
- (void)setDoubleValue:(double)doubleValue;

//! _minValue getter.
- (double)minValue;
//! _minValue setter.
- (void)setMinValue:(double)newMinimum;

//! _maxValue getter.
- (double)maxValue;
//! _minValue setter.
- (void)setMaxValue:(double)newMaximum;

@end
