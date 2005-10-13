//
//  NSStringSimiliarity.m
//
//  Created by John R Chang on Thu Dec 25 2003.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "NSStringSimiliarity.h"

#import <CoreServices/CoreServices.h>


@implementation NSString (Similiarity)

- (float)isSimilarToString:(NSString *)aString
{
    // Exact-match fast case
    if ([self caseInsensitiveCompare:aString] == NSOrderedSame)
        return 1.0;

    // Fuzzy match
    float outScore = 0.0;
    SKIndexRef skIndex = NULL;
    SKSearchGroupRef skGroup = NULL;
    SKDocumentRef skDocument1 = NULL;
    SKDocumentRef skDocument2 = NULL;
    SKSearchResultsRef skSearchResults = NULL;
    Boolean result;
    
    CFStringRef string1 = CFStringCreateCopy(NULL, (CFStringRef)self);
    if (string1 == NULL)
        return outScore;

	// Create in-memory Search Kit index
    CFMutableDataRef indexData = (CFMutableDataRef)[NSMutableData data];
    skIndex = SKIndexCreateWithMutableData(indexData, NULL, kSKIndexVector, NULL);
    if (skIndex == NULL)
        goto catch_error;

	// Create documents with content of given strings
    skDocument1 = SKDocumentCreate(CFSTR(""), NULL, CFSTR("s1"));
    if (skDocument1 == NULL)
        goto catch_error;
    result = SKIndexAddDocumentWithText(skIndex, skDocument1, string1, true);
    if (result == false)
        goto catch_error;
    
    skDocument2 = SKDocumentCreate(CFSTR(""), NULL, CFSTR("s2"));
    if (skDocument2 == NULL)
        goto catch_error;
    result = SKIndexAddDocumentWithText(skIndex, skDocument2, (CFStringRef)aString, true);
    if (result == false)
        goto catch_error;
    
    result = SKIndexFlush(skIndex);
    if (result == false)
        goto catch_error;
    
    // Create search group
    CFArrayRef indices = (CFArrayRef)[NSArray arrayWithObject:(id)skIndex];
    if (indices == NULL)
        goto catch_error;
    
    skGroup = SKSearchGroupCreate(indices);
    if (skGroup == NULL)
        goto catch_error;

	// Create search results
    CFArrayRef exampleDocuments = (CFArrayRef)[NSArray arrayWithObject:(id)skDocument1];
    skSearchResults = SKSearchResultsCreateWithDocuments(skGroup, exampleDocuments, 2, NULL, NULL);
    if (skSearchResults == NULL)
        goto catch_error;
      
	// Get relevance score
    SKDocumentRef foundDocuments[2];
    float foundScores[2] = {};
    CFIndex count = SKSearchResultsGetInfoInRange(skSearchResults, CFRangeMake(0,2), (SKDocumentRef *)&foundDocuments, NULL, (float *)&foundScores);
    if (count != 2)
    {
        outScore = 0.0;
        goto catch_error;
    }
        
    outScore = foundScores[1];

catch_error:    
    if (skIndex)
        CFRelease(skIndex);
    if (skGroup)
        CFRelease(skGroup);
    if (skDocument1)
        CFRelease(skDocument1);
    if (skDocument2)
        CFRelease(skDocument2);
    if (skSearchResults)
        CFRelease(skSearchResults);

    CFRelease(string1);
    return outScore;
}

@end
