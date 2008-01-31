//
//  IconTextFieldCell.m
//
//  Created by John R Chang on Mon Jan 12 2004.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "IconTextFieldCell.h"


//! An NSTextFieldCell with left justified image.
/*!
    Used in the table view to display score for a given item.
*/
@implementation IconTextFieldCell

//! Initializes IconTextFieldCell with no image.
- (id) init
{
    self = [super init];
    _image = nil;
    return self;
}

//! Creates copy which shares the original image.
- (id)copyWithZone:(NSZone *)zone
{
    IconTextFieldCell * newCell = [[IconTextFieldCell alloc] init];
    newCell->_image = [_image retain];
    return newCell;
}

//! Releases _image and frees up memory.
- (void) dealloc
{
    [_image release];
    [super dealloc];
}

//! _image setter.
- (void)setImage:(NSImage *)image
{
    [_image release];
    _image = [image retain];
}

//! _image getter.
- (NSImage *)image
{
    return _image;
}


//! Draws icon if any and then next to it the field text.
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (_image)
    {
        NSRect imageFrame = [self imageRectForBounds:cellFrame];
        //[[NSColor blueColor] set]; NSFrameRect(imageFrame);	// DEBUG
        
        NSPoint point = imageFrame.origin;
        if ([controlView isFlipped])
            point.y += imageFrame.size.height;
        [_image compositeToPoint:point operation:NSCompositeSourceOver];        
    }

    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [super drawInteriorWithFrame:titleRect inView:controlView];
}


//! Calculates position of title origin based on image width.
- (NSRect)titleRectForBounds:(NSRect)theRect
{
    NSRect titleRect = [super titleRectForBounds:theRect];
    
    if (_image)
    {
        NSRect imageRect = [self imageRectForBounds:theRect]; 

        const float kHorizontalMarginBetweenIconAndText = 3.0;
        float offsetForImageRectX = imageRect.size.width + kHorizontalMarginBetweenIconAndText;
        titleRect.origin.x += offsetForImageRectX;
        titleRect.size.width -= offsetForImageRectX;
    }

    return titleRect;
}

//! Calculates position of image origin relative to title origin.
- (NSRect)imageRectForBounds:(NSRect)theRect
{
    // Superclass returns a centered image position
    // We need to left align it, i.e. NSImageLeft
    NSRect imageRect = [super imageRectForBounds:theRect]; 
    NSRect titleRect = [super titleRectForBounds:theRect];
    imageRect.origin.x = titleRect.origin.x + 2.0;
        
    return imageRect;
}


//!  Shorten up the editor rectangle to accomodate our icon
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSRect textFrame = [self titleRectForBounds:aRect];
    [super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
}

//! Shorten up the editor to reflect our icon.
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength
{
    NSRect textFrame = [self titleRectForBounds:aRect];
    [super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

@end
