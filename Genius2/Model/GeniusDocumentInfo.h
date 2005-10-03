//
//  GeniusDocumentInfo.h
//  Genius2
//
//  Created by John R Chang on 2005-10-03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GeniusDocumentInfo : NSManagedObject {
	
}

- (NSArray *) hiddenColumnIdentifiers;
- (void) setHiddenColumnIdentifiers:(NSArray *)array;

- (BOOL) isColumnARichText;
- (void) setIsColumnARichText:(BOOL)flag;

- (BOOL) isColumnBRichText;
- (void) setIsColumnBRichText:(BOOL)flag;

- (int) quizDirectionMode;
- (void) setQuizDirectionMode:(int)value;

@end
