//
//  TableViewResponder.h
//  Genius
//
//  Created by Chris Miner on 19.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TableViewResponder: NSResponder
{
    NSObject *_target;                        //!< destination of our key down actions
}

- (id) initWithTarget:(NSObject*) target;

@end

