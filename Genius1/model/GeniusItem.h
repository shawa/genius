/*
	Genius
	Copyright (C) 2003-2006 John R Chang

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

#import <Foundation/Foundation.h>


//! A GeniusItem models one or more representations of a memorizable atom of information.
/*! Example atoms of information include strings, images, web links, or sounds. A GeniusItem represents one of these atomic types of information. */
//! @todo Delete dead code. 
@interface GeniusItem : NSObject <NSCoding, NSCopying> {
    //! string atom
    NSString * _stringValue;
    //! image atom @todo not used
    NSURL * _imageURL;
    //! link atom @todo not used
    NSURL * _webResourceURL;
    //! synthesized speech atom @todo not used
    NSString * _speakableStringValue;
    //! record audio atom @todo not used
    NSURL * _soundURL;
}

- (void) addObserver: (id) observer;
- (void) removeObserver: (id) observer;

// Visual
- (NSString *) stringValue;

- (NSURL *) imageURL;

- (NSURL *) webResourceURL;

// Audio
- (NSString *) speakableStringValue;

- (NSURL *) soundURL;

@end
