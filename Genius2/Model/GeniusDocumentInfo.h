//
//  GeniusDocumentInfo.h
//  Genius2
//
//  Created by John R Chang on 2005-10-03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * GeniusDocumentInfoIsColumnARichTextKey;
extern NSString * GeniusDocumentInfoIsColumnBRichTextKey;

enum
{
	GeniusQuizUnidirectionalMode = 1,
	GeniusQuizBidirectionalMode,
};


@interface GeniusDocumentInfo : NSManagedObject

- (NSDictionary *) tableViewConfigurationDictionary;
- (void) setTableViewConfigurationDictionary:(NSDictionary *)configDict;

- (BOOL) isColumnARichText;
- (void) setIsColumnARichText:(BOOL)flag;

- (BOOL) isColumnBRichText;
- (void) setIsColumnBRichText:(BOOL)flag;

- (int) quizDirectionMode;
- (void) setQuizDirectionMode:(int)value;

@end
