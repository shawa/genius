/*
	Genius
	Copyright (C) 2003-2006 John R Chang

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.	

	http://www.gnu.org/licenses/gpl.txt
*/

#import "GeniusAssociationEnumerator.h"
#include <math.h>   // pow
#import "NSArrayGeniusAdditions.h"


static unsigned long Factorial(int n)
{
    return (n<=1) ? 1 : n * Factorial(n-1);
}

//! Calculates the 
static float PoissonValue(int x, float m)
{
    return (pow(m,x) / Factorial(x)) * pow(M_E, -m);
}


//! Meant to be used like an NSEnumerator to iterate over a collection of GeniusAssociation items.
/*!
    Supports various selection and sorting options. 
 */
@implementation GeniusAssociationEnumerator

//! Default initializer.
/*!
    Provided @a asociations is copied and used as the basis for later filtering and sorting.
*/
- (id) initWithAssociations:(NSArray *)associations
{
    self = [super init];

    _inputAssociations = [associations mutableCopy];
    
    _count = [_inputAssociations count];
    _minimumScore = -1;
    _m_value = 1.0;
    
    _hasPerformedChooseAssociations = NO;
    //_selectedAssociationDicts = [NSMutableArray new];
    _scheduledAssociations = [NSMutableArray new];
    return self;
}

//! Releases #_inputAssociations and #_scheduledAssociations and frees up memory.
- (void) dealloc
{
    [_inputAssociations release];

    //[_selectedAssociationDicts release];
    [_scheduledAssociations release];

    [super dealloc];
}

//! _count setter.
/*!
    Parameter @a count is ignored if it is greater than the number of items in #_inputAssociations.
    @todo Don't assume GeniusAssociationEnumerator#_inputAssociations is set before count if that isn't enforced.
*/
- (void) setCount:(unsigned int)count
{
    _count = MIN([_inputAssociations count], count);
}

//! _minimumScore setter.
- (void) setMinimumScore:(int)score
{
    _minimumScore = score;
}

//! _m_value setter.
/*! @todo Change the name of this variable to something practical.  */
- (void) setProbabilityCenter:(float)value
{
    _m_value = value;
}

//! Loops over #_inputAssociations to find relevent items.
/*!
    Filters out disabled GeniusAssociation items and those with a score lower than
 the #_minimumScore.  As a side effect this method nullifies the GeniusAssociation#dueDate
 for items that are past due.
*/
- (NSArray *) _getActiveAssociations
{
    #if DEBUG
        NSLog(@"_minimumScore=%d, [_inputAssociations count]=%d", _minimumScore, [_inputAssociations count]);
    #endif
    int requestedMinimumScore = _minimumScore;

    _minimumScore = -2;
    _maximumScore = _minimumScore;
    
    
    NSMutableArray * outAssociations = [NSMutableArray array];
    NSEnumerator * associationEnumerator = [_inputAssociations objectEnumerator];
    GeniusAssociation * association;
    while ((association = [associationEnumerator nextObject]))
    {   
        // Filter out disabled pairs
        GeniusPair * pair = [association parentPair];
        if ([pair importance] == kGeniusPairDisabledImportance)
            continue;

        // Filter out minimum association scores
        if ([association score] < requestedMinimumScore)
            continue;

        // Filter out long-term items (HACK)
/*        NSDate * limitDate = [NSDate dateWithTimeIntervalSinceNow:7*60];
        if ([[association dueDate] compare:limitDate] == NSOrderedDescending)
            continue;*/

        [(NSMutableArray *)outAssociations addObject:association];
            
        // If the fire date has already expired, clear it
        if ([[association dueDate] compare:[NSDate date]] == NSOrderedAscending)
            [association setDueDate:nil];

        // Calculate minimum and maximum scores        
        if (_minimumScore < -1)
            _minimumScore = [association score];
        else
            _minimumScore = MIN(_minimumScore, [association score]);

        _maximumScore = MAX(_maximumScore, [association score]);
    }
    
    return outAssociations;
}

//! Function used in sorting array of GeniusAssociation instances by importance attribute.
static NSComparisonResult CompareAssociationByImportance(GeniusAssociation * assoc1, GeniusAssociation * assoc2, void *context)
{
    GeniusPair * pair1 = [assoc1 parentPair];
    GeniusPair * pair2 = [assoc2 parentPair];
    int importance1 = [pair1 importance];
    int importance2 = [pair2 importance];
    
    if (importance1 > importance2)
        return NSOrderedAscending;
    else if (importance1 < importance2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

//!  Selects items from @a associations based on GeniusAssociation#score and _m_value.
/*!
    Sorts the associations into buckets based on score.  Then calculates the Poisson value 
    for each bucket based on the established #_m_value.  Finally generates a series of
    random numbers to choose items from the buckets based on the probablility curve.
*/
- (NSArray *) _chooseCountAssociationsByScore:(NSArray *)associations
{
    #if DEBUG
        NSLog(@"_minimumScore=%d, _maximumScore=%d", _minimumScore, _maximumScore);
        NSLog(@"[associations count]=%d, _count=%d", [associations count], _count);
    #endif

    if ([associations count] <= _count)
        return associations;

    // Count the number of buckets necessary.
    NSMutableArray * buckets = [NSMutableArray array];
    int bucketCount = (_maximumScore - _minimumScore + 1);
    int b;
    for (b=0; b<bucketCount; b++)
        [buckets addObject:[NSMutableArray array]];

    // Sort the associations into buckets.
    NSEnumerator * associationEnumerator = [associations objectEnumerator];
    GeniusAssociation * association;
    while ((association = [associationEnumerator nextObject]))
    {
        b = [association score] - _minimumScore;
        NSMutableArray * bucket = [buckets objectAtIndex:b];
        [bucket addObject:association];
    }
    #if DEBUG
    for (b=0; b<bucketCount; b++)
        NSLog(@"bucket %d has %d associations", b, [[buckets objectAtIndex:b] count]);
    #endif

    // Calculate Poisson distribution curve using _m_value.
    float * p = calloc(sizeof(float), bucketCount);
    float max_p = 0.0;
    for (b=0; b<bucketCount; b++)
    {
        p[b] = PoissonValue(b, _m_value);
        max_p = MAX(max_p, p[b]);

        #if DEBUG
        NSLog(@"p[%d]=%f --> expect n=%.1f", b, p[b], _count * p[b]);
        #endif
    }

    // Perform weighted random selection of _count objects
    NSMutableArray * outAssociations = [NSMutableArray array];
    while ([outAssociations count] < _count)
    {
        float x = random() / (float)LONG_MAX;
        #if DEBUG
        float origValue = x;
        #endif

        // Here we translate the random point x to the index of the corresponding weighted bucket.
        // We assert that the sum of the probabilities (p[b] for all b) is 1.0.
        for (b=0; b<bucketCount; b++)
        {
            if (x < p[b])
            {
                NSMutableArray * bucket = [buckets objectAtIndex:b];
                if ([bucket count] > 0)
                {
                    [outAssociations addObject:[bucket objectAtIndex:0]];
                    [bucket removeObjectAtIndex:0];
                    
                    #if DEBUG
                    NSLog(@"%f\t--> pull from bucket %d, %d left", origValue, b, [bucket count]);
                    #endif
                    break;  // done with this association
                }
            }
            x -= p[b];
        }
    }

    free(p);
    
    return outAssociations;
}

//! Helper method to initialize the set of associations for enumeration.
/*!
    The process of choosing involves:
        @li Filtering out inactive associations
        @li Randomizing the remaining ones
        @li Sorting the results by importance
        @li Finally choosing at least #_count items based on #_minimumScore.
*/
- (void) performChooseAssociations
{
    // 1. First, filter out disabled pairs, minimum scores, and long-term dates.
    NSArray * activeAssociations = [self _getActiveAssociations];
    
    // 2. Randomize the remaining "active" associations
    NSArray * randomActiveAssociations = [activeAssociations sortedArrayUsingFunction:RandomSortFunction context:NULL];
    
    // 3. Weight the associations according to pair importance
    NSArray * orderedAssociations = [randomActiveAssociations sortedArrayUsingFunction:CompareAssociationByImportance context:NULL];
    
    // 4. Choose _count associations by score according to a probability curve
    NSArray * chosenAssociations = [self _chooseCountAssociationsByScore:orderedAssociations];

    // DEBUG
    #if DEBUG
    NSEnumerator * associationEnumerator = [chosenAssociations objectEnumerator];
    GeniusAssociation * association;
    while ((association = [associationEnumerator nextObject]))
    {
        GeniusPair * pair = [association parentPair];
        NSLog(@"%@, date=%@, score=%d, importance=%d", [[pair itemA] stringValue], [[association dueDate] description], [association score], [pair importance]);
    }
    #endif

    [_inputAssociations setArray:chosenAssociations];   // HACK

    _hasPerformedChooseAssociations = YES;
}

//! Convenience method for returning the number of items in _inputAssociations.
/*!
    @todo check if how this is used makes sense.  Seems like it should return the count of scheduled associations.
*/
- (int) remainingCount
{
    return [_inputAssociations count]; // + [_scheduledAssociations count];
}
//! Returns the next GeniusAssociation in the enumeration.
/*!
    Looks for an association from the _scheduledAssociations with a passed dueDate.  If none is found
    one of the _inputAssociations is returned.
*/
- (GeniusAssociation *) nextAssociation
{
    GeniusAssociation * association;
    
    // First time
    if (_hasPerformedChooseAssociations == NO)
        [self performChooseAssociations];

    // Try popping an association off the scheduled associations queue
    #if DEBUG
    //NSLog(@"_scheduledAssociations = %@", [_scheduledAssociations description]);
    #endif
    if ([_scheduledAssociations count])
    {
        association = [[_scheduledAssociations objectAtIndex:0] retain];
        if ([[association dueDate] compare:[NSDate date]] == NSOrderedAscending)
        {
            [_scheduledAssociations removeObjectAtIndex:0];
            return [association autorelease];
        }
    }
    
    // Otherwise try popping an unscheduled association
    #if DEBUG
    //NSLog(@"_inputAssociations = %@", [_inputAssociations description]);
    #endif
    if ([_inputAssociations count] == 0)
        return nil;
    association = [[_inputAssociations objectAtIndex:0] retain];
    [_inputAssociations removeObjectAtIndex:0];
    return [association autorelease];
}


//! Updates GeniusAssociation#dueDate based on current GeniusAssociation#score provided @a association and inserts in _scheduledAssociations.
- (void) _scheduleAssociation:(GeniusAssociation *)association
{
    unsigned int sec = pow(5, [association score]);
    NSDate * dueDate = [[NSDate date] addTimeInterval:sec];
    [association setDueDate:dueDate];

    int i, n = [_scheduledAssociations count];
    for (i=0; i<n; i++)
    {
        NSDate * dueDate = [association dueDate];
        GeniusAssociation * currentAssoc = [_scheduledAssociations objectAtIndex:i];
        NSDate * currentFireDate = [currentAssoc dueDate];
        if ([dueDate compare:currentFireDate] == NSOrderedAscending)
        {
            [_scheduledAssociations insertObject:association atIndex:i];
            return;
        }
    }
    [_scheduledAssociations addObject:association];
}


//! Bumps score of @a association up by one.
- (void) associationRight:(GeniusAssociation *)association
{
    // score++
    int score = [association score];
    [association setScore:score+1];

    [self _scheduleAssociation:association];
}

//! Sets score for the @a association back to zero.
/*!
    @todo This seems questionable.
 */
- (void) associationWrong:(GeniusAssociation *)association
{
    // score = 0
    [association setScore:0];

    [self _scheduleAssociation:association];
}

//! Sets score for the @a association
/*!
    @todo This seems unexpected.  Why would skipping something mean nullify the score and due date?
*/
- (void) associationSkip:(GeniusAssociation *)association
{
    // score = -1
    [association setScoreNumber:nil];
    
    [association setDueDate:nil];
}

@end
