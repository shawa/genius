/* GeniusTableView */

#import <Cocoa/Cocoa.h>


@interface GeniusTableView : NSTableView
{
	NSMutableArray * _allTableColumns;
	NSMenu * _columnsMenu;
}

- (NSMenu *) dynamicColumnsMenu;

- (NSDictionary *)configurationDictionary;
- (void)setConfigurationFromDictionary:(NSDictionary *)configDict;

@end


@interface NSObject (GeniusTableViewDelegate)

- (NSArray *)tableViewDefaultHiddenTableColumnIdentifiers:(NSTableView *)aTableView;
- (void) tableView:(NSTableView *)aTableView didHideTableColumn:(NSTableColumn *)tableColumn;
- (void) tableView:(NSTableView *)aTableView didShowTableColumn:(NSTableColumn *)tableColumn;

- (BOOL) performKeyDown:(NSEvent *)theEvent;
- (BOOL) performKeyEquivalent:(NSEvent *)theEvent;

@end
