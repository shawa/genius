//
//  IconTextFieldCell.m
//  Genius
//
//  Created by John R Chang on Mon Jan 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "IconTextFieldCell.h"


@implementation IconTextFieldCell

- (id) init
{
    self = [super init];
    _image = nil;
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    IconTextFieldCell * newCell = [[IconTextFieldCell alloc] init];
    newCell->_image = [_image retain];
    return newCell;
}

- (void) dealloc
{
    [_image release];
    [super dealloc];
}

- (void)setImage:(NSImage *)image
{
    [_image release];
    _image = [image retain];
}

- (NSImage *)image
{
    return _image;
}


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

- (NSRect)imageRectForBounds:(NSRect)theRect
{
    // Superclass returns a centered image position
    // We need to left align it, i.e. NSImageLeft
    NSRect imageRect = [super imageRectForBounds:theRect]; 
    NSRect titleRect = [super titleRectForBounds:theRect];
    imageRect.origin.x = titleRect.origin.x + 2.0;
        
    return imageRect;
}


// Without the following, the editor is placed over our icon
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSRect textFrame = [self titleRectForBounds:aRect];
    [super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength
{
    NSRect textFrame = [self titleRectForBounds:aRect];
    [super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

@end
