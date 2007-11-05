/* RelevanceIndicator */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface RelevanceIndicator : NSView
{
    NSImage * _patternImage; //!< Fill pattern for bar.
    double _minValue,        //!< Minium value represented by the view.
    double _maxValue;        //!< Maximum value represented by the view.
    double _doubleValue;     //!< Current value to be represented by the view.
}

- (double)minValue;
- (void)setMinValue:(double)newMinimum;

- (double)maxValue;
- (void)setMaxValue:(double)newMaximum;

- (double)doubleValue;
- (void)setDoubleValue:(double)doubleValue;

@end
