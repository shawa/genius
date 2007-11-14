//
//  GeniusPairTest.m
//  Genius
//
//  Created by Chris Miner on 13.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>
#import "GeniusPair.h"

@interface GeniusPairTest : SenTestCase {
    GeniusPair *geniusPair;
}

@end

//! A collection of GeniusPair tests.
@implementation GeniusPairTest

- (void) setUp
{
    geniusPair = [[GeniusPair alloc] init];
}

- (void) tearDown
{
    [geniusPair release];
}

//! Test that a new GeniusPair already has associated objects.
- (void) testAllocation
{
    STAssertNotNil([geniusPair itemA], nil);
    STAssertNotNil([geniusPair itemB], nil);
    STAssertNotNil([geniusPair associationAB], nil);
    STAssertNotNil([geniusPair associationBA], nil);
    STAssertFalse([[geniusPair valueForKey:@"dirty"] boolValue], nil);
}

//! Test that changes to score number are registered
- (void) testObserveScoreNumber
{
    STAssertFalse([[geniusPair valueForKey:@"dirty"] boolValue], nil);
    [[geniusPair associationAB] setValue:[NSNumber numberWithInt:1U] forKey:@"scoreNumber"];
    STAssertTrue([[geniusPair valueForKey:@"dirty"] boolValue], nil);
}

//! Test that changes to due date are registered
- (void) testObserveDueDate
{
    STAssertFalse([[geniusPair valueForKey:@"dirty"] boolValue], nil);
    [[geniusPair associationAB] setValue:[NSNumber numberWithInt:1U] forKey:@"dueDate"];
    STAssertTrue([[geniusPair valueForKey:@"dirty"] boolValue], nil);
}

//! Test that changes to string value are registered
- (void) testObserveStringValue
{
    STAssertFalse([[geniusPair valueForKey:@"dirty"] boolValue], nil);
    [[geniusPair itemA] setValue:@"a value" forKey:@"stringValue"];
    STAssertTrue([[geniusPair valueForKey:@"dirty"] boolValue], nil);
}

//! Test that encoding fails without a keyed archiver.
- (void) testEncodingFailure
{    
    STAssertThrowsSpecificNamed([NSArchiver archivedDataWithRootObject:geniusPair], NSException, NSInternalInconsistencyException, nil);
}

//! Test that encoding and decoding archives group, notes, type, and importance.
- (void) testEncoding
{   
    [geniusPair setCustomGroupString:@"my group"];
    [geniusPair setCustomTypeString:@"my type"];
    [geniusPair setNotesString:@"my notes"];
    [geniusPair setImportance:42];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:geniusPair];
    GeniusPair *newPair = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    STAssertEqualObjects([geniusPair customGroupString], @"my group", nil);    
    STAssertEqualObjects([geniusPair customTypeString], @"my type", nil);    
    STAssertEqualObjects([geniusPair notesString], @"my notes", nil);    
    STAssertEquals([geniusPair importance], 42, nil);    
}

@end
