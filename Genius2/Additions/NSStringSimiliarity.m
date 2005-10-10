//
//  NSStringSimiliarity.m
//  Genius
//
//  Created by John R Chang on Thu Dec 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSStringSimiliarity.h"
#import <CoreServices/CoreServices.h>


@implementation NSString (Similiarity)

- (float)isSimilarToString:(NSString *)aString
{
    // Non-fuzzy fast case
    if ([self caseInsensitiveCompare:aString] == NSOrderedSame)
        return 1.0;

    // Fuzzy match
    float outScore = 0.0;
    SKIndexRef index = NULL;
    SKSearchGroupRef group = NULL;
    SKDocumentRef document1 = NULL;
    SKDocumentRef document2 = NULL;
    SKSearchResultsRef searchResults = NULL;
    Boolean succeed;
    
    CFStringRef string1 = CFStringCreateCopy(NULL, (CFStringRef)self);
    if (string1 == NULL)
        return outScore;


    CFMutableDataRef indexData = (CFMutableDataRef)[NSMutableData data];
    index = SKIndexCreateWithMutableData(indexData, NULL, kSKIndexVector, NULL);
    if (index == NULL)
        goto exit_isSimilarToString;

    document1 = SKDocumentCreate(CFSTR("genius"), NULL, CFSTR("s1"));
    if (document1 == NULL)
        goto exit_isSimilarToString;
    succeed = SKIndexAddDocumentWithText(index, document1, string1, true);
    if (!succeed)
        goto exit_isSimilarToString;
    
    document2 = SKDocumentCreate(CFSTR("genius"), NULL, CFSTR("s2"));
    if (document2 == NULL)
        goto exit_isSimilarToString;
    succeed = SKIndexAddDocumentWithText(index, document2, (CFStringRef)aString, true);
    if (!succeed)
        goto exit_isSimilarToString;
    
    succeed = SKIndexFlush(index);
    if (!succeed)
        goto exit_isSimilarToString;
    
    
    CFArrayRef indices = (CFArrayRef)[NSArray arrayWithObject:(id)index];
    if (indices == NULL)
        goto exit_isSimilarToString;
    
    group = SKSearchGroupCreate(indices);
    if (group == NULL)
        goto exit_isSimilarToString;

    CFArrayRef exampleDocuments = (CFArrayRef)[NSArray arrayWithObject:(id)document1];
    searchResults = SKSearchResultsCreateWithDocuments(group, exampleDocuments, 2, NULL, NULL);
    if (searchResults == NULL)
        goto exit_isSimilarToString;
      
    SKDocumentRef foundDocuments[2];
    float foundScores[2] = {};

    CFIndex count = SKSearchResultsGetInfoInRange(searchResults, CFRangeMake(0,2), (SKDocumentRef *)&foundDocuments, NULL, (float *)&foundScores);
    if (count != 2)
    {
        outScore = 0.0;
        goto exit_isSimilarToString;
    }
        
    outScore = foundScores[1];

exit_isSimilarToString:    
    if (index)
        CFRelease(index);
    if (group)
        CFRelease(group);
    if (document1)
        CFRelease(document1);
    if (document2)
        CFRelease(document2);
    if (searchResults)
        CFRelease(searchResults);

    CFRelease(string1);
    return outScore;
}

@end
