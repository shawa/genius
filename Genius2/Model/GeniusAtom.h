//
//  GeniusAtom.h
//  Genius2
//
//  Created by John R Chang on 2005-09-24.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface GeniusAtom :  NSManagedObject  
{
}

- (void) setUsesRTFData:(BOOL)flag;	// converts string <-> rtfData

- (void) setString:(NSString *)string;	// also sets rtfData to nil
- (void) setRtfData:(NSData *)rtfData;	// also sets string to plain text form

@end
