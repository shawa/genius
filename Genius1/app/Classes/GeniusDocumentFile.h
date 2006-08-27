//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Foundation/Foundation.h>
#import "GeniusDocument.h"


@interface GeniusDocument (FileFormat)

- (NSData *)dataRepresentationOfType:(NSString *)aType;
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType;

- (IBAction)exportFile:(id)sender;
+ (IBAction)importFile:(id)sender;

@end
