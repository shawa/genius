//
//  GeniusAtomView.h
//  test
//
//  Created by John R Chang on 2005-10-12.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * GeniusAtomViewUseRichTextAndGraphicsKey;


@interface GeniusAtomView : NSView {
	IBOutlet id textView;
	IBOutlet id toggleButton;
	NSObjectController * _objectController;
	NSString * _keyPath;
	BOOL _useRichTextAndGraphics;
}

- (void) bindAtomToController:(id)observableController withKeyPath:(NSString *)keyPath;

// KVO-compliant
- (BOOL) useRichTextAndGraphics;
- (void) setUseRichTextAndGraphics:(BOOL)flag;

// Warns user upon down-converting rich text to plain text
- (IBAction) performToggleRichText:(id)sender;

@end
