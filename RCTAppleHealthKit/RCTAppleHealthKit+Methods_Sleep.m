//
//  RCTAppleHealthKit+Methods_Sleep.m
//  RCTAppleHealthKit
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit+Methods_Sleep.h"
#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"

@implementation RCTAppleHealthKit (Methods_Sleep)


- (void)sleep_getSleepSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    if(startDate == nil){
        reject(@"Invalid Argument", @"startDate is required in options", nil);
        return;
    }
    
    // day predicate
    NSPredicate *predicate = [RCTAppleHealthKit predicateForSamplesBetweenDates:startDate endDate:endDate];
    
    // not include manual data
    if (includeManuallyAdded == false) {
        NSPredicate *manualDataPredicate = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[manualDataPredicate]];
    }

    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    [self fetchSleepCategorySamplesForPredicate:predicate
                                          limit:limit
                                      ascending:ascending
                                watchOnly:watchOnly
                                     completion:^(NSArray *results, NSError *error) {
                                         if(results){
                                             resolve(results);
                                             return;
                                         } else {
                                             reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting active energy burned samples: %@", error.localizedDescription], error);
                                             return;
                                         }
                                     }];
    
}


@end
