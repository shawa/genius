//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "VisualStringDiff.h"


@interface NSString (VisualStringDiff)
- (BOOL) _isEqualToStringIgnoringPunctuationAndCase:(NSString *)string;
@end

@implementation NSString (VisualStringDiff)
- (BOOL) _isEqualToStringIgnoringPunctuationAndCase:(NSString *)string
{
	if ([self caseInsensitiveCompare:string] == NSOrderedSame)
		return YES;

	NSMutableString * string1 = [self mutableCopy];
	NSMutableString * string2 = [string mutableCopy];

	// Remove punctuation
	NSCharacterSet * punctuationCharacterSet = [NSCharacterSet punctuationCharacterSet];
	while (1)
	{
		NSRange range = [string1 rangeOfCharacterFromSet:punctuationCharacterSet];
		if (range.location == NSNotFound)
			break;
		[string1 deleteCharactersInRange:range];
	}
	while (1)
	{
		NSRange range = [string2 rangeOfCharacterFromSet:punctuationCharacterSet];
		if (range.location == NSNotFound)
			break;
		[string2 deleteCharactersInRange:range];
	}

	BOOL outResult = ([string1 caseInsensitiveCompare:string2] == NSOrderedSame);
	[string1 release];
	[string2 release];
	return outResult;
}
@end



//! Handles creation of an string that highlights the differences between two strings.
/*!
    Used in quiz interface to visualize the differences between what was typed and what
    was expected.
 */
@implementation VisualStringDiff

//! Helper method to determine the differences between two strings.
/*!
    The implementation chops @a string1 and @a string2 into words based on the space character, then writes
    the results out into two files which it then feeds to the UNIX diff program in order to calculate the
    differences between the two.  This method then returns the raw output of the UNIX diff command.  Have
    a look at the side-by-side output of diff for more details.  

    @todo Release @a diffTask even when running the command causes an exception.
    @todo Remove temp files even when running the command causes an exception. 
 */
+ (NSString *) _runDiffFromString:(NSString *)string1 toString:(NSString *)string2
{
	// Create temp files
	NSMutableString * text1 = [string1 mutableCopy];
	NSMutableString * text2 = [string2 mutableCopy];
	[text1 replaceOccurrencesOfString:@" " withString:@"\n" options:0L range:NSMakeRange(0, [text1 length])];
	[text2 replaceOccurrencesOfString:@" " withString:@"\n" options:0L range:NSMakeRange(0, [text2 length])];
	[text1 appendString:@"\n"];
	[text2 appendString:@"\n"];
	NSData * data1 = [text1 dataUsingEncoding:NSUTF8StringEncoding];
	NSData * data2 = [text2 dataUsingEncoding:NSUTF8StringEncoding];
	NSString * path1 = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Genius1.tmp"];
	NSString * path2 = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Genius2.tmp"];
	[data1 writeToFile:path1 atomically:NO];
	[data2 writeToFile:path2 atomically:NO];
	[text1 release];
	[text2 release];

	// Run diff
	NSTask *diffTask = [[NSTask alloc] init];
	NSPipe *newPipe = [NSPipe pipe];
	NSFileHandle *readHandle = [newPipe fileHandleForReading];

	[diffTask setStandardOutput:newPipe]; 
	[diffTask setLaunchPath:@"/usr/bin/diff"];
	[diffTask setArguments:[NSArray arrayWithObjects:@"-b", @"-i", @"--side-by-side", path1, path2, nil]];

	BOOL succeed = YES;
	NS_DURING
		[diffTask launch];
	NS_HANDLER
		succeed = NO;
	NS_ENDHANDLER
	if (succeed == NO)
		return nil;

	NSMutableData * diffData = [NSMutableData data];
	NSData *inData = nil;
	while ((inData = [readHandle availableData]) && [inData length])
		[diffData appendData:inData];
	NSString * diffOutput = [[NSString alloc] initWithData:diffData encoding:NSUTF8StringEncoding];

	[diffTask release];

	// Delete temp files
	NSFileManager * fm = [NSFileManager defaultManager];
	[fm removeFileAtPath:path1 handler:nil];
	[fm removeFileAtPath:path2 handler:nil];
	
	return [diffOutput autorelease];
}

//! creates a string that highlights the differences between @a origString and @a newString.
/*! 
    Relies on the output of the UNIX diff command.  

    @todo Rewrite this to make it legible.
    @see #_runDiffFromString:toString:
*/
+ (NSAttributedString *) attributedStringHighlightingDifferencesFromString:(NSString *)origString toString:(NSString *)newString
{
	if ([newString isEqualToString:@""])
		return [[[NSAttributedString alloc] initWithString:@""] autorelease];

	if ([newString isEqualToString:origString])
		return [[[NSAttributedString alloc] initWithString:origString] autorelease];

	// Run diff
	NSString * diffOutput = [self _runDiffFromString:origString toString:newString];
	if (diffOutput == nil)
		return [[[NSAttributedString alloc] initWithString:origString] autorelease];

	NSArray * diffLines = [diffOutput componentsSeparatedByString:@"\n"];
	//NSLog([diffLines description]);	// DEBUG

	// Parse results
	NSMutableArray * mergedWords = [NSMutableArray array];
	NSMutableIndexSet * highlightIndexSet = [NSMutableIndexSet indexSet];
	int i, count = [diffLines count];
	for (i=0; i<count; i++)
	{
		NSString * line = [diffLines objectAtIndex:i];
		NSArray * columns = [line componentsSeparatedByString:@"\t"];
		unsigned int columnCount = [columns count];
		if (columnCount < 2)
			continue;
		
		NSString * origWord = [columns objectAtIndex:0];
		NSString * newWord = [columns lastObject];

		// Modified
		NSString * marker = [columns objectAtIndex:columnCount-2];
		NSRange range = [marker rangeOfString:@"|"];
		if (range.location == NSNotFound)
			range = [marker rangeOfString:@"/"];
		if (range.location != NSNotFound)
		{
			if ([origWord _isEqualToStringIgnoringPunctuationAndCase:newWord] == NO)
				[highlightIndexSet addIndex:[mergedWords count]];
			/*else
				NSLog(@"%@ and %@ are the same", origWord, newWord);*/

			[mergedWords addObject:origWord];
			continue;
		}
		
		// Removed
		range = [marker rangeOfString:@">"];
		if (range.location != NSNotFound)
		{
			const unichar kMiddleDotUnichar = 0x00B7;
			NSString * sMiddleDotString = [NSString stringWithCharacters:&kMiddleDotUnichar length:1];
			NSString * threeDotsString = [NSString stringWithFormat:@"%@%@%@", sMiddleDotString, sMiddleDotString, sMiddleDotString];
			if ([[mergedWords lastObject] isEqual:threeDotsString] == NO)
			{
				[highlightIndexSet addIndex:[mergedWords count]];
				[mergedWords addObject:threeDotsString];
			}
			continue;
		}

		// Added
		if (range.location == NSNotFound)
			range = [newWord rangeOfString:@"<"];
		if (range.location != NSNotFound)
		{
			[highlightIndexSet addIndex:[mergedWords count]];

			[mergedWords addObject:origWord];			
			continue;
		}

		// Original
		[mergedWords addObject:origWord];
	}

	//NSLog(@"mergedWords=%@", [mergedWords description]);	// DEBUG
	//NSLog(@"highlightIndexSet=%@", [highlightIndexSet description]);	// DEBUG

	NSMutableAttributedString * outAttrString = [NSMutableAttributedString new];
	i = 0, count = [mergedWords count];
	while (i<count)
	{
		NSMutableString * chunk = [NSMutableString string];
		
		BOOL isHighlighted = [highlightIndexSet containsIndex:i];
		for (; i<count; i++)
		{
			BOOL shouldHighlight = [highlightIndexSet containsIndex:i];
			if (isHighlighted != shouldHighlight)
				break;

			NSString * word = [mergedWords objectAtIndex:i];
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
