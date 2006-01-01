//
//  CollapsableSplitView.m
//
//  Created by John R Chang on 2005-10-13.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "CollapsableSplitView.h"


@implementation CollapsableSplitView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_collapsedSubviewsDict = [NSMutableDictionary new];
    }
    return self;
}

- (void) awakeFromNib
{
	_collapsedSubviewsDict = [NSMutableDictionary new];
}

- (void) dealloc
{
	[_collapsedSubviewsDict release];
	[super dealloc];
}


- (void)drawDividerInRect:(NSRect)aRect	// XXX: doesn't really belong here
{
	if ([_collapsedSubviewsDict count] > 0)
	{
		BOOL isVertical = [self isVertical];

		NSEnumerator * keyEnumerator = [_collapsedSubviewsDict keyEnumerator];
		id key;
		while ((key = [keyEnumerator nextObject]))
		{
			NSView * tempView = [key pointerValue];
			
			// If the collapsed placeholder view has now been resized by the user
			// to the extent that it should be uncollapsed (i.e. expanded) ...
			NSSize size = [tempView frame].size;
			if ((isVertical && size.width > 0.0) || (isVertical == NO && size.height > 0.0))
			{
				// Swap in subview
				NSView * origSubview = [_collapsedSubviewsDict objectForKey:key];
				[origSubview setFrameSize:size];
				[self replaceSubview:tempView with:origSubview];
				[_collapsedSubviewsDict removeObjectForKey:key];
			}
		}
	}
	
	[super drawDividerInRect:aRect];
}

- (void) collapseSubviewAt:(int)offset
{
	NSView * subview = [[self subviews] objectAtIndex:offset];
	NSView * tempView = [[NSView alloc] initWithFrame:NSZeroRect];

	// Swap out subview
	id key = [NSValue valueWithPointer:tempView];
	[_collapsedSubviewsDict setObject:subview forKey:key];
	[self replaceSubview:subview with:tempView];
	[self adjustSubviews];
	
	[tempView release];
}

- (void) uncollapseSubviewAt:(int)offset
{
	NSView * tempView = [[self subviews] objectAtIndex:offset];

	id key = [NSValue valueWithPointer:tempView];
	NSView * origSubview = [_collapsedSubviewsDict objectForKey:key];
	if (origSubview == nil)
		return;
		
	// Swap in subview
	[self replaceSubview:tempView with:origSubview];
	[_collapsedSubviewsDict removeObjectForKey:key];
}


/*- (BOOL)isSubviewCollapsed:(NSView *)subview
{
	// The subview might have been collapsed by us or privately by Cocoa
	
	BOOL isVertical = [self isVertical];
	NSSize size = [subview frame].size;
	if ((isVertical && size.width == 0.0) || (isVertical == NO && size.height == 0.0))
		return YES;
	
	return [super isSubviewCollapsed:subview];
}*/

@end
