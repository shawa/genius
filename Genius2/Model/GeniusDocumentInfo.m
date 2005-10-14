//
//  GeniusDocumentInfo.m
//  Genius2
//
//  Created by John R Chang on 2005-10-03.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GeniusDocumentInfo.h"

#import "GeniusItem.h"

NSString * GeniusDocumentInfoIsColumnARichTextKey = @"isColumnARichText";
NSString * GeniusDocumentInfoIsColumnBRichTextKey = @"isColumnBRichText";


#import "GeniusDocument.h"
@interface GeniusDocument (Private)	// XXX
- (BOOL) convertAllAtomsToRichText:(BOOL)value forAtomKey:(NSString *)atomKey;
@end


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


- (NSDictionary *) _richTextColumnsDictionary	// never returns nil
{
	NSDictionary * richTextColumnsDictionary = nil;
	NSData * data = [self valueForKey:@"richTextColumnsDictData"];
	if (data)
		richTextColumnsDictionary = [NSUnarchiver unarchiveObjectWithData:data];
	if (richTextColumnsDictionary == nil)
		richTextColumnsDictionary = [NSDictionary dictionary];
	return richTextColumnsDictionary;
}

- (void) _setRichTextColumnsDictionary:(NSDictionary *)dictionary
{
	NSData * data = [NSArchiver archivedDataWithRootObject:dictionary];
	[self setValue:data forKey:@"richTextColumnsDictData"];
}

- (BOOL) isColumnARichText
{
	NSNumber * value = [[self _richTextColumnsDictionary] objectForKey:@"atomA"];
	if (value == nil)
		return NO;
	return [value boolValue];
}

- (void) setIsColumnARichText:(BOOL)flag
{
	[self willChangeValueForKey:GeniusDocumentInfoIsColumnARichTextKey];

	NSMutableDictionary * dictionary = [NSMutableDictionary dictionaryWithDictionary:[self _richTextColumnsDictionary]];
	[dictionary setObject:[NSNumber numberWithBool:flag] forKey:@"atomA"];
	[self _setRichTextColumnsDictionary:dictionary];

	[self didChangeValueForKey:GeniusDocumentInfoIsColumnARichTextKey];
}


- (BOOL) isColumnBRichText
{
	NSNumber * value = [[self _richTextColumnsDictionary] objectForKey:@"atomB"];
	if (value == nil)
		return NO;
	return [value boolValue];
}

- (void) setIsColumnBRichText:(BOOL)flag
{
	[self willChangeValueForKey:GeniusDocumentInfoIsColumnBRichTextKey];

	NSMutableDictionary * dictionary = [NSMutableDictionary dictionaryWithDictionary:[self _richTextColumnsDictionary]];
	[dictionary setObject:[NSNumber numberWithBool:flag] forKey:@"atomB"];
	[self _setRichTextColumnsDictionary:dictionary];

	[self didChangeValueForKey:GeniusDocumentInfoIsColumnBRichTextKey];
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
