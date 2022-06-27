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


- (void)sleep_getSleepSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    BOOL includeUserEntered = [RCTAppleHealthKit boolFromOptions:input key:@"includeUserEntered" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    // day predicate
    NSPredicate *dayPredicate = [RCTAppleHealthKit predicateForSamplesBetweenDates:startDate endDate:endDate];
    
    // not include manual data
    NSPredicate *manualDataPredicate = [NSPredicate predicateWithFormat:@"metadata.%K != YES", HKMetadataKeyWasUserEntered];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate, manualDataPredicate]];
    
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    [self fetchSleepCategorySamplesForPredicate:predicate
                                          limit:limit
                             includeUserEntered:includeUserEntered
                                      ascending:ascending
                                watchOnly:watchOnly
                                     completion:^(NSArray *results, NSError *error) {
                                         if(results){
                                             callback(@[[NSNull null], results]);
                                             return;
                                         } else {
                                             callback(@[RCTJSErrorFromNSError(error)]);
                                             return;
                                         }
                                     }];
    
}


@end
