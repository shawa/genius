#import "GeniusWelcomePanel.h"

static NSString * GeniusWelcomePanelDontShowKey = @"dontShowQuizWelcome";


@implementation GeniusWelcomePanel

+ (GeniusWelcomePanel *) sharedWelcomePanel
{
    static GeniusWelcomePanel * sController = nil;
    if (sController == nil)
        sController = [[GeniusWelcomePanel alloc] initWithWindowNibName:@"WelcomePanel"];
    return sController;
}

- (BOOL) runModal
{
    static BOOL sHasSeenThisSession = NO;
    if (sHasSeenThisSession)
        return YES;
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    BOOL dontShowPref = [defaults boolForKey:GeniusWelcomePanelDontShowKey];
    if (dontShowPref)
        return YES;
        
    [[self window] center];
        
    int result = [NSApp runModalForWindow:[self window]];
    [self close];

    if (result == NSRunAbortedResponse)
        return NO;
    
    if ([dontRemindSwitch state] == NSOnState)
        [defaults setBool:YES forKey:GeniusWelcomePanelDontShowKey];
        
    sHasSeenThisSession = YES;
    return YES;
}

- (IBAction)goBack:(id)sender
{
    [NSApp abortModal];
}

- (IBAction)continue:(id)sender
{
    [NSApp stopModal];
}


- (BOOL)windowShouldClose:(id)sender
{
    [NSApp abortModal];
    return YES;
}

@end
