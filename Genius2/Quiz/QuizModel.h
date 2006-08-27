//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

#import "GeniusDocument.h"
#import "GeniusAssociationEnumerator.h"


@interface QuizModel : NSObject {
	GeniusDocument * _document;
	NSArray * _allActiveAssociations;

	unsigned int _requestedCount;
	float _requestedReviewLearnFloat;
	float _requestedMinScore;
}

- (id) initWithDocument:(GeniusDocument *)document;

- (BOOL) hasValidItems;	// preflight

- (void) setCount:(unsigned int)count;	// 0 means all
- (void) setReviewLearnFloat:(float)value;

- (GeniusAssociationEnumerator *) associationEnumerator;	// does the selection here

@end
