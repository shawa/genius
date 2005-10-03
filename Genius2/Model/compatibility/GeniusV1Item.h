//
//  GeniusV1Item.h
//  Genius
//
//  Created by John R Chang on Mon Oct 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


// An item models one or more representations of a memorizable atom of information
@interface GeniusV1Item : NSObject <NSCoding, NSCopying> {
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
