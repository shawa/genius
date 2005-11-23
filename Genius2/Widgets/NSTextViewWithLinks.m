//  NSTextViewWithLinks.m
//  TextLinks

//  Copyright (c) 2003 Apple Computer, Inc. All rights reserved.
//	See legal notice at end of file.

//	This application demonstrates how to programmatically create links in text,
//	and optionally handle clicks in those links. See README.rtf for more information.

// http://developer.apple.com/samplecode/Sample_Code/Cocoa/TextLinks.htm


#import "NSTextViewWithLinks.h"


//	Informal protocol for extending NSTextView's delegate
@interface NSObject (NSTextViewWithLinks_Delegate)
- (NSCursor *) cursorForLink: (NSObject *) linkObject
    atIndex: (unsigned) charIndex
    ofTextView: (NSTextView *) aTextView;
@end



@implementation NSTextViewWithLinks

#pragma mark PUBLIC CLASS METHODS -- NSObject OVERRIDES

//	Make all NSTextView instances into instances of this class, even if we didn't create them.
//	(We could instead selectively make some instances in nib files belong to this class,
//	 but then it's hard to enter the initial text using Interface Builder.)
+ (void) load
{
    [self poseAsClass: [self superclass]];
}


#pragma mark PRIVATE INSTANCE METHODS

- (NSCursor *) cursorForLink: (NSObject *) linkObject
    atIndex: (unsigned) charIndex
{
    NSCursor 	*result = nil;

    //	If the delegate implements the method, consult it.
    if ([[self delegate] respondsToSelector: @selector(cursorForLink:atIndex:ofTextView:)])
        result = [[self delegate] cursorForLink: linkObject  atIndex: charIndex  ofTextView: self];

    //	If the delegate didn't implement it, or it did but returned nil, substitute a guess.
    if (result == nil)
        result = [NSCursor pointingHandCursor];
    return result;
}


#pragma mark PUBLIC INSTANCE METHODS -- NSView OVERRIDES

- (void) resetCursorRects
{
    NSAttributedString	*attrString;
    NSPoint				containerOrigin;
    NSRect				visRect;
    NSRange				visibleGlyphRange, visibleCharRange, attrsRange;

    //	Get the attributed text inside us
    attrString = [self textStorage];

    //	Figure what part of us is visible (we're typically inside a scrollview)
    containerOrigin = [self textContainerOrigin];
    visRect = NSOffsetRect ([self visibleRect], -containerOrigin.x, -containerOrigin.y);

    //	Figure the range of characters which is visible
    visibleGlyphRange = [[self layoutManager] glyphRangeForBoundingRect:visRect inTextContainer:[self textContainer]];
    visibleCharRange = [[self layoutManager] characterRangeForGlyphRange:visibleGlyphRange actualGlyphRange:NULL];

    //	Prime for the loop
    attrsRange = NSMakeRange (visibleCharRange.location, 0);

    //	Loop until we reach the end of the visible range of characters
    while (NSMaxRange(attrsRange) < NSMaxRange(visibleCharRange)) // find all visible URLs and set up cursor rects
    {
        NSString *linkObject;

        //	Find the next link inside the range
        linkObject = [attrString attribute: NSLinkAttributeName 
            atIndex: NSMaxRange(attrsRange)
            effectiveRange: &attrsRange];

        if (linkObject != nil)
        {
            NSCursor		*cursor;
            NSRectArray		rects;
            unsigned int	rectCount, rectIndex;
            NSRect			oneRect;

            //	Figure what cursor to show over this link.
            cursor = [self cursorForLink: linkObject  atIndex: attrsRange.location];

            //	Find the rectangles where this range falls. (We could use -boundingRectForGlyphRange:...,
            //	but that gives a single rectangle, which might be overly large when a link runs
            //	through more than one line.)
            rects = [[self layoutManager] rectArrayForCharacterRange: attrsRange
                withinSelectedCharacterRange: NSMakeRange (NSNotFound, 0)
                inTextContainer: [self textContainer]
                rectCount: &rectCount];

            //	For each rectangle, find its visible portion and ask for the cursor to appear
            //	when they're over that rectangle.
            for (rectIndex = 0; rectIndex < rectCount; rectIndex++)
            {
                oneRect = NSIntersectionRect (rects[rectIndex], [self visibleRect]);
                [self addCursorRect: oneRect  cursor: cursor];
            }
       }
    }
}

@end

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
