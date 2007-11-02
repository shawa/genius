//
//  NSStringSimiliarity.m
//
//  Created by John R Chang on Thu Dec 25 2003.
//  Modified by John R Chang on Sun Aug 27 2006.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "NSString+Similiarity.h"

#import <CoreServices/CoreServices.h>

//! Simple category for support of loosely matching strings based on SearchKit
/*!
    @category NSString(Similiarity)
    @todo Perhaps a simple searchkit wrapper would be a better idea?
 */
@implementation NSString(Similiarity)
//! Returns search kit score for @a inQuery.
/*!
    Only returns score for last match if there is more than one match.
    @todo Perhaps convert this helper function to a category method?
*/
float ScoreForSearchAsync(SKIndexRef inIndex, CFStringRef inQuery)
{
    // Create search
	SKSearchRef search = SKSearchCreate(inIndex, inQuery, kSKSearchOptionFindSimilar);
    if (search == NULL)
		return 0.0;	// XXX

	SKDocumentID documentIDs[1] = {};
    float foundScores[1] = {0.0};
	CFIndex foundCount = 0;
    //! @todo Perhaps do while with comparison on search result?
	while (1)
	{
		Boolean result = SKSearchFindMatches(search, 1, documentIDs, foundScores, 0.5, &foundCount);
		if (result == false)
			break;
        // @todo Perhaps delete this delay
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	}
	
	CFRelease(search);
	
	return foundScores[0];
}
  
//! Returns a value between 0 and 1 depending on the quality of match
/*!
    Returns 0.0 <= x <= 1.0.  0.0 == not equal (or error), 1.0 == equal.
    Uses Search Kit.
 */
- (float)isSimilarToString:(NSString *)aString
{
    // Exact-match fast case
    if ([self caseInsensitiveCompare:aString] == NSOrderedSame)
        return 1.0;

    // Fuzzy match
    float outScore = 0.0;
    SKIndexRef index = NULL;
    SKDocumentRef document = NULL;
	SKSearchRef search = NULL;
    Boolean result;
    
	// Create in-memory Search Kit index
    index = SKIndexCreateWithMutableData((CFMutableDataRef)[NSMutableData data], NULL, kSKIndexVector, NULL);
    if (index == NULL)
        goto catch_error;

	// Create documents with content of given strings
    document = SKDocumentCreate(CFSTR(""), NULL, CFSTR("s1"));
    if (document == NULL)
        goto catch_error;
	
    result = SKIndexAddDocumentWithText(index, document, (CFStringRef)self, true);
    if (result == false)
        goto catch_error;
    
    // Flush index
    result = SKIndexFlush(index);
    if (result == false)
        goto catch_error;
    
	float selfScore = ScoreForSearchAsync(index, (CFStringRef)self);
	float paramScore = ScoreForSearchAsync(index, (CFStringRef)aString);
	
	outScore = paramScore / selfScore;

catch_error:    
    if (index)
        CFRelease(index);
    if (document)
        CFRelease(document);
    if (search)
        CFRelease(search);

    return outScore;
}

@end
