//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <CoreData/CoreData.h>


extern NSString * GeniusAtomStringKey;
extern NSString * GeniusAtomRTFDDataKey;

extern NSString * GeniusAtomStringRTDDataKey;	// for GeniusWindowController


/*
	An atom models one or more representations of a memorizable unit of information
*/
@interface GeniusAtom :  NSManagedObject <NSCopying>
{
	id _delegate;
}

+ (NSDictionary *) defaultTextAttributes;
- (BOOL) usesDefaultTextAttributes;		// used by GeniusDocument.nib
- (void) clearTextAttributes;

- (void) setStringRTFDData:(NSData *)rtfdData;
- (NSData *) stringRTFDData;	// falls back to string

- (void) setDelegate:(id)delegate;

@end


@interface NSObject (GeniusAtomDelegate)
- (void) atomHasChanged:(GeniusAtom *)atom;
@end
