//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

#import "CustomizableTableView.h"


@interface GeniusTableView : CustomizableTableView
{
}

@end


@interface NSObject (GeniusTableViewDelegate)

- (BOOL) performKeyDown:(NSEvent *)theEvent;
- (BOOL) performKeyEquivalent:(NSEvent *)theEvent;

@end
