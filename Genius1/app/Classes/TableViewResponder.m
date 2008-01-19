//
//  TableViewResponder.m
//  Genius
//
//  Created by Chris Miner on 19.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TableViewResponder.h"

//! Simple first responder element for handling key events in table view.
@implementation TableViewResponder

//! Initializes instance with the given target.
- (id) initWithTarget:(NSObject*) target
{
    self = [super init];
    if (self != nil)
    {
        _target = target;
    }
    return self;
}

//! Handle delete key.
- (void)deleteBackward:(id)sender
{
    if ([_target respondsToSelector:@selector(delete:)])
    {
        [_target performSelector:@selector(delete:) withObject:self];
    }
}

//! Handle tab key.
- (void)insertTab:(id)sender
{
    if ([_target respondsToSelector:@selector(selectSearchField:)])
    {
        [_target performSelector:@selector(selectSearchField:) withObject:self];
    }
}

//! Standard 1st responder implementation.
- (void) keyDown: (NSEvent *) event
{
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

@end
