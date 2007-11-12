//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

#import "GeniusDocument.h"
#import "GeniusAssociationEnumerator.h"


@interface QuizModel : NSObject {
	GeniusDocument * _document;        //!< The source of our associations.
	NSArray * _allActiveAssociations;  //!< Every association in the Document.

	unsigned int _requestedCount;      //!< The number of items for quizing.
	float _requestedReviewLearnFloat;  //!< Slider setting for review versus test.
	float _requestedMinScore;          //!< Cut off for items that I don't know.
}

- (id) initWithDocument:(GeniusDocument *)document;

- (BOOL) hasValidItems;	// preflight

- (void) setCount:(unsigned int)count;	// 0 means all
- (void) setReviewLearnFloat:(float)value;

- (GeniusAssociationEnumerator *) associationEnumerator;	// does the selection here

@end
