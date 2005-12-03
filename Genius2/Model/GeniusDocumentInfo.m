//
//  GeniusDocumentInfo.m
//  Genius2
//
//  Created by John R Chang on 2005-10-03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusDocumentInfo.h"

#import "GeniusItem.h"


@implementation GeniusDocumentInfo

- (NSDictionary *) tableViewConfigurationDictionary
{
	NSData * data = [self valueForKey:@"tableViewConfigurationDictionaryData"];
	if (data == nil)
		return nil;
	return [NSUnarchiver unarchiveObjectWithData:data];
}

- (void) setTableViewConfigurationDictionary:(NSDictionary *)configDict
{
	NSData * data = [NSArchiver archivedDataWithRootObject:configDict];
	[self setValue:data forKey:@"tableViewConfigurationDictionaryData"];
}


- (int) quizDirectionMode
{
    [self willAccessValueForKey:@"quizDirectionMode"];
	return [[self primitiveValueForKey:@"quizDirectionMode"] intValue];
    [self didAccessValueForKey:@"quizDirectionMode"];
}

- (void) setQuizDirectionMode:(int)value
{
    [self willChangeValueForKey:@"quizDirectionMode"];
	[self setPrimitiveValue:[NSNumber numberWithInt:value] forKey:@"quizDirectionMode"];
    [self didChangeValueForKey:@"quizDirectionMode"];
}

@end
