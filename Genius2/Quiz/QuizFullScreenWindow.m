//
//  QuizFullScreenWindow.m
//  Genius2
//
//  Created by John R Chang on 2005-10-11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QuizFullScreenWindow.h"


@implementation QuizFullScreenWindow

- (id)init
{
	NSRect screenRect = [[NSScreen mainScreen] frame];
	self = [super initWithContentRect:screenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];	[self setLevel:(NSModalPanelWindowLevel-1)];
	[self setBackgroundColor:[NSColor blackColor]];
	[self setAlphaValue:0.5];
	[self setOpaque:NO];
	[self setHasShadow:NO];
	[self setIgnoresMouseEvents:YES];
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(_handleAppWillResignActive:) name:NSApplicationWillResignActiveNotification object:nil];
	[nc addObserver:self selector:@selector(_handleAppWillBecomeActive:) name:NSApplicationWillBecomeActiveNotification object:nil];
	
	return self;
}

- (void) dealloc
{
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	
	[super dealloc];
}


- (void) _handleAppWillResignActive:(NSNotification *)notification
{
	[self orderOut:nil];
}

- (void) _handleAppWillBecomeActive:(NSNotification *)notification
{
	[self orderFront:nil];
}

@end
