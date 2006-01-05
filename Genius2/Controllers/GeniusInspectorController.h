/* GeniusInspectorController */

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
