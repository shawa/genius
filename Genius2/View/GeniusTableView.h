/* GeniusTableView */

#import <Cocoa/Cocoa.h>


@interface GeniusTableView : NSTableView
{
	NSMutableArray * _allTableColumns;
}

@end


@interface NSObject (GeniusTableViewDelegate)

- (NSArray *) tableViewHiddenTableColumnIdentifiers:(NSTableView *)tableView;
- (void) tableView:(NSTableView *)tableView setHiddenTableColumnIdentifiers:(NSArray *)hiddenIdentifiers;

- (void) tableView:(NSTableView *)tableView didShowTableColumn:(NSTableColumn *)tableColumn;


- (void) delete:(id)sender;

@end
