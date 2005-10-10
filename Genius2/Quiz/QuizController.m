//
//  QuizController.m
//  Genius2
//
//  Created by John R Chang on 2005-10-10.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QuizController.h"


@implementation QuizController

- (id) initWithAssociationEnumerator:(GeniusAssociationEnumerator *)associationEnumerator
{
	self = [super init];
	
	_associationEnumerator = [associationEnumerator retain];
	_windowController = [[NSWindowController alloc] initWithWindowNibName:@"GeniusQuiz"];

    _newSound = [[NSSound soundNamed:@"Blow"] retain];
    _rightSound = [[NSSound soundNamed:@"Hero"] retain];
    _wrongSound = [[NSSound soundNamed:@"Basso"] retain];

	return self;
}

- (void) dealloc
{
	[_windowController release];
	[_associationEnumerator release];
	
    [_newSound release];
    [_rightSound release];
    [_wrongSound release];

	[super dealloc];
}


- (void) runQuiz
{
	// TO DO
	NSLog(@"runQuiz");
	NSLog(@"%d", [[_associationEnumerator allObjects] count]);
}

@end
