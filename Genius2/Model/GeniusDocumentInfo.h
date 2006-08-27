//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>


enum
{
	GeniusQuizUnidirectionalMode = 1,
	GeniusQuizBidirectionalMode,
};


@interface GeniusDocumentInfo : NSManagedObject

- (NSDictionary *) tableViewConfigurationDictionary;
- (void) setTableViewConfigurationDictionary:(NSDictionary *)configDict;

- (int) quizDirectionMode;
- (void) setQuizDirectionMode:(int)value;

@end
