//
//  QuizModel.m
//  Genius2
//
//  Created by John R Chang on 2005-10-09.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QuizModel.h"

#import "GeniusAssociation.h"
#import "GeniusItem.h"	// myRating

#import "GeniusPreferences.h"
#import "GeniusDocumentInfo.h"	// -quizDirectionMode
#import "QuizArrayAdditions.h"

#define DEBUG 0


@implementation QuizModel

- (id) initWithDocument:(GeniusDocument *)document
{
	self = [super init];
	_document = [document retain];
	_associations = nil;
	
	_requestedCount = 13;
	_requestedMinScore = -1.0;

	return self;
}

- (void) dealloc
{
	[_document release];
	[_associations release];
	[super dealloc];
}


- (void) setCount:(unsigned int)count
{
	_requestedCount = count;
}

- (void) setMinimumScore:(float)score
{
	_requestedMinScore = score;
}

- (float) _probabilityCenter
{
	// 0% should be minimum=0 (review only)
	// 50% should be m=1.0
	// 100% should be m=0.0 (learn only)

	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    float reviewLearnValue = [ud floatForKey:GeniusPreferencesQuizReviewLearnSliderFloatKey];

	if (reviewLearnValue == 0.0)
		_requestedMinScore = 0.0;
	
    return ((100.0 - reviewLearnValue) / 100.0) * 2.0;
}


- (NSArray *) _activeAssociations
{
	NSMutableArray * fragments = [NSMutableArray arrayWithObject:@"(parentItem.isEnabled == YES)"]; // AND (parentItem.atomA.string != NIL) AND (parentItem.atomB.string != NIL)"];

	int quizDirectionMode = [[_document documentInfo] quizDirectionMode];
	if (quizDirectionMode == GeniusQuizUnidirectionalMode)
		[fragments addObject:@"(sourceAtomKey == \"atomA\" AND targetAtomKey == \"atomB\")"];
	else
		[fragments addObject:@"((sourceAtomKey == \"atomA\" AND targetAtomKey == \"atomB\") OR (sourceAtomKey == \"atomB\" AND targetAtomKey == \"atomA\"))"];

	if (_requestedMinScore != 1.0)
		[fragments addObject:[NSString stringWithFormat:@"(predictedScore >= %f)", _requestedMinScore]];
	
	NSMutableString * query = [NSMutableString string];
	int i, count = [fragments count];
	for (i=0; i<count; i++)
	{
		NSString * fragment = [fragments objectAtIndex:i];
		[query appendString:fragment];
		if (i<count-1)
			[query appendString:@" AND "];
	}

	// Fetch all relevant associations
	NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"GeniusAssociation" inManagedObjectContext:[_document managedObjectContext]];
	[request setEntity:entity];

	NSPredicate * predicate = [NSPredicate predicateWithFormat:query];
	[request setPredicate:predicate];
	
	NSError * error = nil;
	NSArray * associations = [[_document managedObjectContext] executeFetchRequest:request error:&error];
	if (associations == nil)
		NSLog(@"%@", [error description]);
	return associations;
}


static NSComparisonResult CompareAssociationByRating(GeniusAssociation * assoc1, GeniusAssociation * assoc2, void *context)
{
    GeniusItem * item1 = [assoc1 valueForKey:@"parentItem"];
    GeniusItem * item2 = [assoc2 valueForKey:@"parentItem"];
    int rating1 = [[item1 valueForKey:@"myRating"] intValue];
    int rating2 = [[item2 valueForKey:@"myRating"] intValue];
    
    if (rating1 > rating2)
        return NSOrderedAscending;
    else if (rating1 < rating2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}


static unsigned long Factorial(int n)
{
    return (n<=1) ? 1 : n * Factorial(n-1);
}

static float PoissonValue(int x, float m)
{
    return (pow(m,x) / Factorial(x)) * pow(M_E, -m);
}

- (NSArray *) _chooseAssociationsByWeightedCurve:(NSArray *)associations
{
    #if DEBUG
		// Calculate minimum and maximum scores        
		float minScore = [[associations valueForKeyPath:@"@min.predictedScore"] floatValue];
		float maxScore = [[associations valueForKeyPath:@"@max.predictedScore"] floatValue];		
        NSLog(@"minScore=%f, maxScore=%f", minScore, maxScore);
	NSLog(@"[associations count]=%d, _requestedCount=%d", [associations count], _requestedCount);
    #endif

    if ([associations count] <= _requestedCount)
        return associations;

    // Count the number of buckets necessary.
    NSMutableArray * buckets = [NSMutableArray array];
    int bucketCount = 11; // ((maxScore - minScore) * 10.0) + 1;
    int b;
    for (b=0; b<bucketCount; b++)
        [buckets addObject:[NSMutableArray array]];

    // Sort the associations into buckets.
    NSEnumerator * associationEnumerator = [associations objectEnumerator];
    GeniusAssociation * association;
    while ((association = [associationEnumerator nextObject]))
    {
		float predictedScore = [[association valueForKey:GeniusAssociationPredictedScoreKey] floatValue];
        b = predictedScore * 10.0;
		if (predictedScore == -1.0)
			b = 0;
		
        NSMutableArray * bucket = [buckets objectAtIndex:b];
        [bucket addObject:association];
    }
    #if DEBUG
    for (b=0; b<bucketCount; b++)
        NSLog(@"bucket[%d] has count %d", b, [[buckets objectAtIndex:b] count]);
    #endif

    // Calculate Poisson distribution curve using _m_value.
	float _m_value = [self _probabilityCenter];
    #if DEBUG
	NSLog(@"_m_value = %f", _m_value);
    #endif

    float * p = calloc(sizeof(float), bucketCount);
    float max_p = 0.0;
    for (b=0; b<bucketCount; b++)
    {
        p[b] = PoissonValue(b, _m_value);
        max_p = MAX(max_p, p[b]);

        #if DEBUG
        NSLog(@"p[%d]=%f --> expect count %.1f", b, p[b], _requestedCount * p[b]);
        #endif
    }

    // Perform weighted random selection of _requestedCount objects
    NSMutableArray * outAssociations = [NSMutableArray array];
    while ([outAssociations count] < _requestedCount)
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
                    NSLog(@"random %f --> pull from bucket %d; %d left", origValue, b, [bucket count]);
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

- (NSArray *) associations
{
	if (_associations == nil)
	{
		// 1. First, filter out disabled pairs, minimum scores, and long-term dates.
		NSArray * activeAssociations = [self _activeAssociations];
		
		// 2. Shuffle the remaining "active" associations
		NSArray * shuffledAssociations = [activeAssociations _arrayByRandomizing];

		// 3. Weight the associations according to user rating
		NSArray * orderedAssociations = [shuffledAssociations sortedArrayUsingFunction:CompareAssociationByRating context:NULL];

		// 4. Choose n associations by score according to a probability curve
		NSArray * chosenAssociations = [self _chooseAssociationsByWeightedCurve:orderedAssociations];

		_associations = [chosenAssociations retain];
	}
	return _associations;
}

- (GeniusAssociationEnumerator *) associationEnumerator
{
	NSArray * associations = [self associations];
	return [[[GeniusAssociationEnumerator alloc] initWithAssociations:associations] autorelease];
}


- (void) foo
{
        // If the fire date has already expired, clear it

}

@end
