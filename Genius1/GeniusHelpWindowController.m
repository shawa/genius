/*
	Genius
	Copyright (C) 2003-2006 John R Chang
	Copyright (C) 2007-2008 Chris Miner

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.	

	http://www.gnu.org/licenses/gpl.txt
*/

#import "GeniusHelpWindowController.h"

//! Implements basic help window that displays simple rft help document.
@implementation GeniusHelpWindowController

//! Standard NSWindowController override.  Returns "Help".
- (NSString *)windowNibName
{
    return @"Help";
}

//! Initializes textView using contents of Help.rtf found in main bundle.
- (void) awakeFromNib
{
	NSString * path = [[NSBundle mainBundle] pathForResource:@"Help" ofType:@"rtf"];
	[textView readRTFDFromFile:path];
}

@end
