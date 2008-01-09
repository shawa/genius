/*******************************************************************************
	JRSwizzle.h
		Copyright (c) 2007 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://opensource.org/licenses/mit-license.php>

	***************************************************************************/

#import <Foundation/Foundation.h>
//! See http://rentzsch.com
@interface NSObject (JRSwizzle)
//! http://rentzsch.com
+ (BOOL)jr_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_;
//! http://rentzsch.com
+ (BOOL)jr_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError**)error_;
@end
