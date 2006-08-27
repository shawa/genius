//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Foundation/Foundation.h>
#import "GeniusDocument.h"


@interface GeniusDocument (Private)

- (void) reloadInterfaceFromModel;

- (NSArray *) visibleColumnIdentifiers;

- (NSArrayController *) arrayController;

- (NSArray *) columnBindings;   // in display order

@end
