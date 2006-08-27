//  Genius
//
//  This code is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.5 License.
//  http://creativecommons.org/licenses/by-nc-sa/2.5/

#import "GeniusAssociationEnumerator.h"

#import "GeniusAssociationDataPoint.h"


@implementation GeniusAssociationEnumerator

- (id) initWithAssociations:(NSArray *)associations
{
	self = [super init];
	_allAssociations = [associations retain];
	_remainingAssociations = [[NSMutableArray alloc] initWithArray:_allAssociations];
	_scheduledAssociations = [NSMutableArray new];
	_currentAssociation = nil;
	return self;
}

- (void) dealloc
{
	[_currentAssociation release];
	[_remainingAssociations release];
	[_scheduledAssociations release];
	[_allAssociations release];
	[super dealloc];
}

- (NSArray *)allObjects
{
	return _remainingAssociations;
}

- (id) nextObject
{
	[_currentAssociation release];

    if ([_scheduledAssociations count] > 0)
    {
        _currentAssociation = [_scheduledAssociations objectAtIndex:0];
        if ([[_currentAssociation valueForKey:GeniusAssociationDueDateKey] compare:[NSDate date]] == NSOrderedAscending)
        {
			[_currentAssociation retain];
            [_scheduledAssociations removeObjectAtIndex:0];
            return _currentAssociation;
        }
    }
    
    if ([_remainingAssociations count] > 0)
	{	
		// pop first object
		_currentAssociation = [_remainingAssociations objectAtIndex:0];		
		[_currentAssociation retain];
		[_remainingAssociations removeObjectAtIndex:0];
		return _currentAssociation;
	}
	
	return nil;
}


- (void) _rescheduleCurrentAssociation	// XXX: does this belong here or GeniusAssociation ?
{
    unsigned int deltaSec = [GeniusAssociationDataPoint timeIntervalForCount:1];
	if ([[_currentAssociation lastDataPoint] value] >= 0.5)
		deltaSec = [GeniusAssociationDataPoint timeIntervalForCount:[_currentAssociation resultCount]];
	
    NSDate * dueDate = [[NSDate date] addTimeInterval:deltaSec];
    [_currentAssociation setValue:dueDate forKey:GeniusAssociationDueDateKey];

	// Insert _currentAssociation into _scheduledAssociations, preserving order
	[_scheduledAssociations addObject:_currentAssociation];
	NSSortDescriptor * sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:GeniusAssociationDueDateKey ascending:YES] autorelease];
	NSArray * sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	[_scheduledAssociations sortUsingDescriptors:sortDescriptors];
}

- (void) neutral
{
    [self _rescheduleCurrentAssociation];
}

- (void) right
{
	[_currentAssociation addResult:YES];

    [self _rescheduleCurrentAssociation];
}

- (void) wrong
{
	[_currentAssociation addResult:NO];

    [self _rescheduleCurrentAssociation];
}

@end
