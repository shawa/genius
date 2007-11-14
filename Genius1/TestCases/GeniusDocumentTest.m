//
//  GeniusDocumentTest.m
//  Genius
//
//  Created by Chris Miner on 13.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GeniusDocument.h"
#import "GeniusPair.h"

#import <SenTestingKit/SenTestingKit.h>


@interface GeniusDocumentTest : SenTestCase {
    
}

@end

//! test cases for the GeniusDocument
@implementation GeniusDocumentTest

//! test that adding an item works.
- (void) testAddingItem
{    
    NSError *error;
    NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
    
    id document = [documentController openUntitledDocumentAndDisplay:YES error:&error];
    STAssertNotNil(document, nil);

    [document add:nil];
    STAssertEquals([[document pairs] count], 1U, @"Number count of pairs %d != 1", [[document pairs] count]);
}

@end
