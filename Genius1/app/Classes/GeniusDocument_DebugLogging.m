//
//  GeniusDocument_DebugLogging.m
//  Genius
//
//  Created by Chris Miner on 09.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GeniusDocument_DebugLogging.h"
#import <JRSwizzle/JRSwizzle.h>

//! Simple swizzle based logging code.
@implementation GeniusDocument(DebugLogging)

//! replaces some methods with logging versions.
+ (void) installLogging
{
    NSError *error = nil;
    
    // insertObject:inPairsAtIndex:
    [GeniusDocument jr_swizzleMethod:@selector(insertObject:inPairsAtIndex:) withMethod:@selector(insertObject:inPairsAtIndex:) error:&error];
    NSAssert1(error == nil, @"Swizzle Unexpectedly Failed %@", error);
    
    // removeObjectFromPairsAtIndex:
    [GeniusDocument jr_swizzleMethod:@selector(removeObjectFromPairsAtIndex:) withMethod:@selector(log_removeObjectFromPairsAtIndex:) error:&error];
    NSAssert1(error == nil, @"Swizzle Unexpectedly Failed %@", error);
    
    // setPairs:
    [GeniusDocument jr_swizzleMethod:@selector(setPairs:) withMethod:@selector(log_setPairs:) error:&error];
    NSAssert1(error == nil, @"Swizzle Unexpectedly Failed %@", error);
    
    // observeValueForKeyPath:ofObject:change:context:
    [GeniusDocument jr_swizzleMethod:@selector(observeValueForKeyPath:ofObject:change:context:) withMethod:@selector(log_observeValueForKeyPath:ofObject:change:context:) error:&error];
    NSAssert1(error == nil, @"Swizzle Unexpectedly Failed %@", error);
    
    // updateChangeCount:
    [GeniusDocument jr_swizzleMethod:@selector(updateChangeCount:) withMethod:@selector(log_updateChangeCount:) error:&error];
    NSAssert1(error == nil, @"Swizzle Unexpectedly Failed %@", error);
    
    //activeUndoTarget
    [GeniusDocument jr_swizzleMethod:@selector(activeUndoTarget) withMethod:@selector(log_activeUndoTarget) error:&error];
    NSAssert1(error == nil, @"Swizzle Unexpectedly Failed %@", error);
    
    //beginQuiz:
    [GeniusDocument jr_swizzleMethod:@selector(beginQuiz:) withMethod:@selector(check_beginQuiz:) error:&error];
    NSAssert1(error == nil, @"Swizzle Unexpectedly Failed %@", error);    
}

//! logs referenced call to referenced method executes it
- (void)log_updateChangeCount:(NSDocumentChangeType)change
{
    NSString *changeString = nil;
    
    switch(change)
    {
        case NSChangeDone:
            changeString = @"NSChangeDone";
            break;
        case NSChangeUndone:
            changeString = @"NSChangeUndone";
            break;
        case NSChangeCleared:
            changeString = @"NSChangeCleared";
            break;
        case NSChangeReadOtherContents:
            changeString = @"NSChangeReadOtherContents";
            break;
        case NSChangeAutosaved:
            changeString = @"NSChangeAutosaved";
            break;
    }
    
    NSLog(@"_cmd: %s change: %@", _cmd, changeString);
    [self log_updateChangeCount:change];    
}


//! logs referenced call to referenced method executes it
- (void)log_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id newValue = [change valueForKey:NSKeyValueChangeNewKey];
    Class class = [object class];
    NSLog(@"Changed %@ instance %@ to %@", class, keyPath, newValue);

    [self log_observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

//! logs referenced call to referenced method executes it
- (void) log_insertObject:(GeniusPair*) pair inPairsAtIndex:(int)index
{
    NSLog(@"_cmd: %s", _cmd);
    [self log_insertObject:pair inPairsAtIndex:index];
}

//! logs referenced call to referenced method executes it
- (void) log_removeObjectFromPairsAtIndex:(int) index
{
    NSLog(@"_cmd: %s", _cmd);
    [self log_removeObjectFromPairsAtIndex:index];    
}

//! logs referenced call to referenced method executes it
- (void) log_setPairs: (NSMutableArray*) values
{
    NSLog(@"_cmd: %s", _cmd);
    return [self log_setPairs:values];
}

//! logs referenced call to referenced method executes it
- (id) log_activeUndoTarget
{
    id result = [self log_activeUndoTarget];
    NSLog(@"_cmd: %s returning: %@", _cmd, result);
    return result;
}

//! checks that all undo actions for the quiz were removed from stack.
- (void) check_beginQuiz:(id) enumerator
{
    int initial = [[self valueForKeyPath:@"undoManager.undoStack.count"] intValue];
    
    [self check_beginQuiz:enumerator];

    int final = [[self valueForKeyPath:@"undoManager.undoStack.count"] intValue];

    NSAssert2(final == initial, @"Undo stack count should be %d but is %d.", initial, final);    
}

@end