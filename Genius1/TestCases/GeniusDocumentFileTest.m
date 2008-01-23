//
//  GeniusDocumentFileTest.m
//  Genius
//
//  Created by Chris Miner on 13.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GeniusDocument.h"
#import "GeniusDocumentPrivate.h"
#import "GeniusPair.h"

#import <SenTestingKit/SenTestingKit.h>


@interface GeniusDocumentFileTest : SenTestCase
{

}

@end

//! test cases for the GeniusDocument
@implementation GeniusDocumentFileTest

//! test creating a document works.
- (void) testOpenNewDocument
{    
    NSError *error;
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    GeniusDocument *document  = [documentController openUntitledDocumentAndDisplay:YES error:&error];
    STAssertNotNil(document, nil);
}

//! loads up preconfigured doc and checks that all is in order.
- (void) testDataRepresentation
{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"TestFile1" ofType:@"genius"]];
    
    NSError *error;
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    GeniusDocument *document  = (GeniusDocument*)[documentController openUntitledDocumentAndDisplay:YES error:&error];

    [document loadDataRepresentation:data ofType:@"Genius Documnent"];
    STAssertNil([document valueForKeyPath:@"_cumulativeStudyTime"], nil);
    STAssertEqualObjects([document valueForKeyPath:@"probabilityCenter"], [NSNumber numberWithFloat:50.0F], nil);
    
    NSDictionary * headers = [document valueForKey:@"columnHeadersDict"];
    STAssertEquals([headers count], 2U, nil);
    
    NSArray *pairs = [document pairs];
    STAssertEquals([pairs count], 1U, nil);
    
    GeniusPair *pair = [pairs objectAtIndex:0];
    STAssertEqualObjects([pair valueForKeyPath:@"itemA.stringValue"], @"Test Question", nil);
    STAssertEqualObjects([pair valueForKeyPath:@"itemB.stringValue"], @"Test Answer", nil);
    STAssertEqualObjects([pair valueForKeyPath:@"customGroupString"], @"Test Group", nil);
    STAssertEqualObjects([pair valueForKeyPath:@"customTypeString"], @"Test Type", nil);
    STAssertEqualObjects([pair valueForKeyPath:@"notesString"], @"Test Notes", nil);
}

//! Loads up preconfigure test file and saves, compares output file and input file.
-(void) testLoadAndSave
{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"TestFile1" ofType:@"genius"]];
    
    NSError *error;
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    GeniusDocument *document  = (GeniusDocument*)[documentController openUntitledDocumentAndDisplay:YES error:&error];
    
    [document loadDataRepresentation:data ofType:@"Genius Documnent"];
    
    NSData *newData = [document dataRepresentationOfType:@"Genius Document"];
    
    STAssertTrue([newData isEqualToData:data], nil);
}

@end
