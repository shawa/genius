#import "GeniusTableView.h"

@implementation GeniusTableView

// Handle delete:
- (void)keyDown:(NSEvent *)theEvent
{	
    if ([theEvent keyCode] == 51)       // Delete
    {
        id delegate = [self delegate];
        if (delegate && [delegate respondsToSelector:@selector(delete:)])
        {
            [delegate performSelector:@selector(delete:) withObject:self];
            return;
        }
    }
}

@end
