#import "RelevanceIndicator.h"


@implementation RelevanceIndicator

- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]) != nil) {

        //OSStatus status = CreateRelevanceBarControl(NULL, &controlRect, 50, 0, 100, &_controlRef);
        
        _minValue = 0.0;
        _maxValue = 100.0;
        _doubleValue = 50.0;
        
        NSSize imageSize = { 2.0, 10.0 };
        _patternImage = [[NSImage alloc] initWithSize:imageSize];
        [_patternImage lockFocus];

        [[NSColor colorWithCalibratedWhite:0.5333 alpha:1.0] set];    // dark
        NSRect lineRect1 = NSMakeRect(0.0, 0.0, 1.0, imageSize.height);
        NSFrameRect(lineRect1);

        [[NSColor colorWithCalibratedWhite:0.7176 alpha:1.0] set];    // light
        NSRect lineRect2 = NSMakeRect(1.0, 0.0, 1.0, imageSize.height);
        NSFrameRect(lineRect2);

        [_patternImage unlockFocus];
        
        _doubleValue = 50.0;
    }
    return self;
}

- (void) dealloc
{
    [_patternImage release];

    [super dealloc];
}


- (void)drawRect:(NSRect)rect
{
    NSRect boundsRect = [self bounds];
    double span = _maxValue - _minValue;
    double percent = (_doubleValue - _minValue) / span;
    float width = boundsRect.size.width * percent;

    NSRect fillRect = boundsRect;
    fillRect.size.width = width;
    [[NSColor colorWithPatternImage:_patternImage] set];
    NSRectFill(fillRect);

    NSRect clearRect = boundsRect;
    clearRect.origin.x += width + 1.0;
    NSDrawWindowBackground(clearRect);
}


- (double)minValue
{
    return _minValue;
}

- (void)setMinValue:(double)newMinimum
{
    if (newMinimum > _maxValue)
        return;
        
    _minValue = newMinimum;

    [self setNeedsDisplay:YES];
}


- (double)maxValue
{
    return _maxValue;
}

- (void)setMaxValue:(double)newMaximum
{
    if (newMaximum < _minValue)
        return;

    _maxValue = newMaximum;

    [self setNeedsDisplay:YES];
}


- (double)doubleValue
{
//    SInt16 value = GetControlValue(_controlRef);
    return _doubleValue;
}

- (void)setDoubleValue:(double)doubleValue
{
//    SetControlValue(_controlRef, value);
    _doubleValue = doubleValue;

    [self setNeedsDisplay:YES];
}

@end
