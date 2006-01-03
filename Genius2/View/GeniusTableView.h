/* GeniusTableView */

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
