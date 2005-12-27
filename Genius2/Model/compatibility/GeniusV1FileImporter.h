//
//  GeniusV1FileImporter.h
//  Genius
//
//  Created by John R Chang on Fri Nov 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeniusDocument.h"


@interface GeniusDocument (GeniusV1FileImporter)

- (BOOL) importGeniusV1_5FileAtURL:(NSURL *)aURL;

@end
