//
//  CollapsableSplitView.h
//
//  Created by John R Chang on 2005-10-13.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

/*
	This is a subclass of NSSplitView that adds a method to programmatically collapse a subview.

	Normally, a subview is effectively programmatically collapsable by setting it to zero height/width,
	but if it has autoresizable content, the normal Cocoa behavior screws up the frame at size zero.
*/

#import <Cocoa/Cocoa.h>


@interface CollapsableSplitView : NSSplitView {
	NSMutableDictionary * _collapsedSubviewsDict;
}

- (void) collapseSubviewAt:(int)offset;	// To uncollapse, set the subview's size.

/*	
	Note: Cocoa uses its own method of collapsing subviews, so if you enable it
	(by implementing the NSSplitView delegate method -splitView:canCollapseSubview: )
	you will not be able to programmatically uncollapse in those cases.
*/

@end
