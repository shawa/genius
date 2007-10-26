//
//  GeniusAppDelegateTest.m
//  Genius
//
//  Created by Chris Miner on 26.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GeniusAppDelegateTest.h"
#import "GeniusAppDelegate.h"


@implementation GeniusAppDelegateTest

- (void) setUp
{
    appDelegate = [[GeniusAppDelegate alloc] init];
}

- (void) tearDown
{
    [appDelegate release];
}

- (void) testOldStyleYear
{
    STAssertTrue([appDelegate isNewerVersion:@"20060615" lastVersion:@"20050615"], @"Year failure.");
    STAssertFalse([appDelegate isNewerVersion:@"20060615" lastVersion:@"20070615"], @"Year failure.");
    STAssertFalse([appDelegate isNewerVersion:@"20060615" lastVersion:@"20060615"], @"Year failure.");
}

- (void) testOldStyleMonth
{
    STAssertTrue([appDelegate isNewerVersion:@"20060715" lastVersion:@"20060615"], @"Month failure.");
    STAssertFalse([appDelegate isNewerVersion:@"20060615" lastVersion:@"20060715"], @"Month failure.");
    STAssertFalse([appDelegate isNewerVersion:@"20060615" lastVersion:@"20060615"], @"Month failure.");
}

- (void) testOldStyleDay
{
    STAssertTrue([appDelegate isNewerVersion:@"20060616" lastVersion:@"20050615"], @"Day failure.");
    STAssertFalse([appDelegate isNewerVersion:@"20060615" lastVersion:@"20070616"], @"Day failure.");
    STAssertFalse([appDelegate isNewerVersion:@"20060615" lastVersion:@"20060615"], @"Day failure.");
}


- (void) testNil
{
    STAssertTrue([appDelegate isNewerVersion:@"1806" lastVersion:nil], @"Nil failure.");
    STAssertTrue([appDelegate isNewerVersion:@"20060815" lastVersion:nil], @"Nil failure.");

    STAssertFalse([appDelegate isNewerVersion:nil lastVersion:@"1806"], @"Nil failure.");
    STAssertFalse([appDelegate isNewerVersion:nil lastVersion:@"20060815"], @"Nil failure.");

    STAssertFalse([appDelegate isNewerVersion:nil lastVersion:nil], @"Nil failure.");
}

- (void) testNewStyle
{
    STAssertTrue([appDelegate isNewerVersion:@"1806" lastVersion:@"1805"], @"New Style failure.");
    STAssertTrue([appDelegate isNewerVersion:@"11" lastVersion:@"1"], @"New Style failure.");
    STAssertTrue([appDelegate isNewerVersion:@"11" lastVersion:@"01"], @"New Style failure.");
    STAssertTrue([appDelegate isNewerVersion:@"2" lastVersion:@"1"], @"New Style failure.");
    STAssertTrue([appDelegate isNewerVersion:@"20" lastVersion:@"1"], @"New Style failure.");
    
    STAssertFalse([appDelegate isNewerVersion:@"1806" lastVersion:@"1806"], @"New Style failure.");
    STAssertFalse([appDelegate isNewerVersion:@"1806" lastVersion:@"1807"], @"New Style failure.");
    STAssertFalse([appDelegate isNewerVersion:@"01" lastVersion:@"11"], @"New Style failure.");
    STAssertFalse([appDelegate isNewerVersion:@"001" lastVersion:@"11"], @"New Style failure.");
    STAssertFalse([appDelegate isNewerVersion:@"1" lastVersion:@"2"], @"New Style failure.");
    STAssertFalse([appDelegate isNewerVersion:@"01" lastVersion:@"001"], @"New Style failure.");
    STAssertFalse([appDelegate isNewerVersion:@"0001" lastVersion:@"001"], @"New Style failure.");
}

- (void) testMixed
{
    STAssertTrue([appDelegate isNewerVersion:@"1806" lastVersion:@"20060815"], @"Date style is considered newer.");
    STAssertTrue([appDelegate isNewerVersion:@"2" lastVersion:@"20060815"], @"Date style is considered newer.");
}

@end
