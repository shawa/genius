//
//  GeniusDocumentPrivate.h
//  Genius
//
//  Created by John R Chang on Tue Dec 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeniusDocument.h"


@interface GeniusDocument (Private)

- (void) reloadInterfaceFromModel;

- (NSArray *) visibleColumnIdentifiers;

- (NSArrayController *) arrayController;

- (NSArray *) columnBindings;   // in display order

@end
