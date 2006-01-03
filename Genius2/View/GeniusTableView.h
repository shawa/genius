/* GeniusTableView */

#import <Cocoa/Cocoa.h>


@interface GeniusTableView : NSTableView
{
	NSMutableArray * _allTableColumns;
	NSMenu * _toggleColumnsMenu;
}

- (NSMenu *) toggleColumnsMenu;

- (NSDictionary *)configurationDictionary;
- (void)setConfigurationFromDictionary:(NSDictionary *)configDict;

@end


@interface NSObject (GeniusTableViewDelegate)

- (NSArray *)tableViewDefaultTableColumnIdentifiers:(NSTableView *)aTableView;
- (void) tableView:(NSTableView *)aTableView didHideTableColumn:(NSTableColumn *)tableColumn;
- (void) tableView:(NSTableView *)aTableView didShowTableColumn:(NSTableColumn *)tableColumn;

- (BOOL) performKeyDown:(NSEvent *)theEvent;
- (BOOL) performKeyEquivalent:(NSEvent *)theEvent;

@end
