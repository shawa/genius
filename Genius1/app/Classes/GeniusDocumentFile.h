//
//  GeniusDocumentFile.h
//  Genius
//
//  Created by John R Chang on Fri Nov 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeniusDocument.h"


@interface GeniusDocument (FileFormat)

- (NSData *)dataRepresentationOfType:(NSString *)aType;
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType;

- (IBAction)exportFile:(id)sender;
+ (IBAction)importFile:(id)sender;

@end
