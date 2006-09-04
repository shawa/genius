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


// An item models one or more representations of a memorizable atom of information
@interface GeniusItem : NSObject <NSCoding, NSCopying> {
    NSString * _stringValue;
    NSURL * _imageURL;
    NSURL * _webResourceURL;
    NSString * _speakableStringValue;
    NSURL * _soundURL;
    
    BOOL _dirty;    // used by key-value observing
}

// Visual
- (NSString *) stringValue;                     // returns @"" if not set
//- (void) setStringValue:(NSString *)string;

- (NSURL *) imageURL;
//- (void) setImageURL:(NSURL *)imageURL;

- (NSURL *) webResourceURL;
//- (void) setWebResourceURL:(NSURL *)webResourceURL;

// Audio
- (NSString *) speakableStringValue;    // returns -stringValue if not set
    //- (void) setSpeakableStringValue:(NSString *)speakableString;

- (NSURL *) soundURL;
//- (void) setSoundURL:(NSURL *)soundURL;

@end
