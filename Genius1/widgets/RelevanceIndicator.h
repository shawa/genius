/* RelevanceIndicator */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface RelevanceIndicator : NSView
{
    NSImage * _patternImage;
    double _minValue, _maxValue;
    double _doubleValue;
}

- (double)minValue;
- (void)setMinValue:(double)newMinimum;

- (double)maxValue;
- (void)setMaxValue:(double)newMaximum;

- (double)doubleValue;
- (void)setDoubleValue:(double)doubleValue;

@end
