//
//  GeniusStringDiff.m
//  test
//
//  Created by John R Chang on 2004-12-01.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GeniusStringDiff.h"


@implementation GeniusStringDiff

+ (NSAttributedString *) attributedStringHighlightingDifferencesFromString:(NSString *)origString toString:(NSString *)newString
{
	if ([newString isEqualToString:origString])
		return [[[NSAttributedString alloc] initWithString:origString] autorelease];

	if ([newString isEqualToString:@""])
		return [[[NSAttributedString alloc] initWithString:@""] autorelease];

	// Create temp files
	NSMutableString * text1 = [origString mutableCopy];
	NSMutableString * text2 = [newString mutableCopy];
	
	[text1 replaceOccurrencesOfString:@" " withString:@"\n" options:NULL range:NSMakeRange(0, [text1 length])];
	[text2 replaceOccurrencesOfString:@" " withString:@"\n" options:NULL range:NSMakeRange(0, [text2 length])];
	NSData * data1 = [text1 dataUsingEncoding:NSUTF8StringEncoding];
	NSData * data2 = [text2 dataUsingEncoding:NSUTF8StringEncoding];
	NSString * path1 = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Genius1.tmp"];
	NSString * path2 = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Genius2.tmp"];
	[data1 writeToFile:path1 atomically:NO];
	[data2 writeToFile:path2 atomically:NO];
	[text1 release];
	[text2 release];

	// Launch diff
	NSTask *diffTask = [[NSTask alloc] init];
	NSPipe *newPipe = [NSPipe pipe];
	NSFileHandle *readHandle = [newPipe fileHandleForReading];

	[diffTask setStandardOutput:newPipe]; 
	[diffTask setLaunchPath:@"/usr/bin/diff"];
	[diffTask setArguments:[NSArray arrayWithObjects:@"-b", @"-i", @"--side-by-side", path1, path2, nil]];
	[diffTask launch];

	NSMutableData * diffData = [NSMutableData data];
	NSData *inData = nil;
	while ((inData = [readHandle availableData]) && [inData length])
		[diffData appendData:inData];
	NSString * diffString = [[NSString alloc] initWithData:diffData encoding:NSUTF8StringEncoding];

	[diffTask release];

	NSFileManager * fm = [NSFileManager defaultManager];
	[fm removeFileAtPath:path1 handler:nil];
	[fm removeFileAtPath:path2 handler:nil];
	
	//NSLog(diffString);
	
	// Parse results
	NSMutableIndexSet * diffIndexSet = [NSMutableIndexSet indexSet];
	NSMutableArray * outWords = [NSMutableArray array];
	
	NSArray * diffLines = [diffString componentsSeparatedByString:@"\n"];
	int i, count = [diffLines count];
	for (i=0; i<count; i++)
	{
		NSString * line = [diffLines objectAtIndex:i];
		NSArray * columns = [line componentsSeparatedByString:@"\t"];
		unsigned int columnCount = [columns count];
		if (columnCount < 2)
			continue;
		NSString * marker = [columns objectAtIndex:columnCount-2];
		NSString * origWord = [columns objectAtIndex:0];

		NSRange range = [marker rangeOfString:@"|"];
		if (range.location == NSNotFound)
			range = [marker rangeOfString:@"/"];
		if (range.location == NSNotFound)
			range = [[columns lastObject] rangeOfString:@"<"];

		if (range.location != NSNotFound)
		{
			[diffIndexSet addIndex:i];
			[outWords addObject:origWord];
			continue;
		}

		range = [marker rangeOfString:@">"];
		if (range.location != NSNotFound)
		{
			[diffIndexSet addIndex:i];
			[outWords addObject:@"_"];
			continue;
		}

		[outWords addObject:origWord];
	}

	NSMutableAttributedString * outAttrString = [NSMutableAttributedString new];
	i = 0, count = [outWords count];
	while (i<count)
	{
		NSMutableString * chunk = [NSMutableString string];
		
		BOOL isHighlighted = [diffIndexSet containsIndex:i];
		for (; i<count; i++)
		{
			BOOL shouldHighlight = [diffIndexSet containsIndex:i];
			if (isHighlighted != shouldHighlight)
				break;

			NSString * word = [outWords objectAtIndex:i];
			[chunk appendFormat:@"%@ ", word];
		}
		[chunk deleteCharactersInRange:NSMakeRange([chunk length]-1, 1)];

		//NSLog(@"%d/%d %d \"%@\"", i, count, isHighlighted, chunk);
		
		NSDictionary * attrs = nil;
		if (isHighlighted)
		{
			NSColor * highlightColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5625 alpha:1.0];
			attrs = [NSDictionary dictionaryWithObject:highlightColor forKey:NSBackgroundColorAttributeName];
		}
		
		NSAttributedString * attrChunk = [[NSAttributedString alloc] initWithString:chunk attributes:attrs];
		[outAttrString appendAttributedString:attrChunk];
		[attrChunk release];

		if (i<count)
			[outAttrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease]];
	}

	return [outAttrString autorelease];
}

@end
