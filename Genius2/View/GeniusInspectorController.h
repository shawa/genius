/* GeniusInspectorController */

#import <Cocoa/Cocoa.h>

@interface GeniusInspectorController : NSWindowController
{
	IBOutlet id atomATextView;
	IBOutlet id atomAController;
	IBOutlet id atomBTextView;
	IBOutlet id atomBController;
}

+ (id) sharedInspectorController;

- (NSArrayController *) arrayController;				// used by GeniusInspector.nib

@end
