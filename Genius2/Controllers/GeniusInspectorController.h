//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import <Cocoa/Cocoa.h>

@interface GeniusInspectorController : NSWindowController
{
	IBOutlet id documentController;
	IBOutlet id tabView;
/*	IBOutlet id atomATextView;
	IBOutlet id atomAController;
	IBOutlet id atomBTextView;
	IBOutlet id atomBController;*/
	IBOutlet id lastModifiedDateField;
	IBOutlet id lastTestedDateField;
}

+ (id) sharedInspectorController;

- (NSTabView *) tabView;	// used by -[GeniusDocument _tableViewDoubleAction:]

@end
