//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Foundation/Foundation.h>


@interface GeniusV1Item : NSObject <NSCoding, NSCopying> {
    NSString * _stringValue;                    //!< string atom
    NSURL * _imageURL;                          //!< image atom @todo not used
    NSURL * _webResourceURL;                    //!< link atom @todo not used
    NSString * _speakableStringValue;           //!< synthesized speech atom @todo not used
    NSURL * _soundURL;                          //!< record audio atom @todo not used
    
    /*! @todo Replace dummy property with implementation of setValue:forUndefinedKey: */
    BOOL _dirty;    //!< dummy property to ensure key value compliance for the key dirty
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
