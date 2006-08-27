//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Foundation/Foundation.h>
#import "GeniusDocument.h"


@interface GeniusDocument (GeniusV1FileImporter)

- (BOOL) importGeniusV1_5FileAtURL:(NSURL *)aURL;

@end
