//
//  RCTAppleHealthKit+Methods_Activity.m
//  RCTAppleHealthKit
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.

#import "RCTAppleHealthKit+Methods_Activity.h"
#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"

@implementation RCTAppleHealthKit (Methods_Activity)

- (void)activity_getActiveEnergyBurned:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKQuantityType *activeEnergyType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit kilocalorieUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeUserEntered = [RCTAppleHealthKit boolFromOptions:input key:@"includeUserEntered" withDefault:false];

    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeUserEntered == false) {
        NSPredicate *includeUserEntered = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeUserEntered]];
    }

    if (watchOnly) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[watchPredicate]];
    }
    

    [self fetchCumulativeSumStatisticsCollection:activeEnergyType
                                            unit:unit
                                          period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *results, NSError *error) {
                                          if(results){
                                              callback(@[[NSNull null], results]);
                                              return;
                                          } else {
                                              NSLog(@"error getting active energy burned samples: %@", error);
                                              callback(@[RCTMakeError(@"error getting active energy burned samples:", error, nil)]);
                                              return;
                                          }
                                      }];
}

- (void)activity_getBasalEnergyBurned:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKQuantityType *basalEnergyType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit kilocalorieUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeUserEntered = [RCTAppleHealthKit boolFromOptions:input key:@"includeUserEntered" withDefault:false];

    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeUserEntered == false) {
        NSPredicate *includeUserEntered = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeUserEntered]];
    }

    if (watchOnly) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[watchPredicate]];
    }

    [self fetchCumulativeSumStatisticsCollection:basalEnergyType
                                            unit:unit
                                          period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *results, NSError *error) {
                                          if(results){
                                              callback(@[[NSNull null], results]);
                                              return;
                                          } else {
                                              NSLog(@"error getting basal energy burned samples: %@", error);
                                              callback(@[RCTMakeError(@"error getting basal energy burned samples:", error, nil)]);
                                              return;
                                          }
                                      }];
}


- (void)activity_getAppleExerciseTime:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback API_AVAILABLE(ios(9.3))
{
    HKQuantityType *exerciseType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleExerciseTime];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit secondUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeUserEntered = [RCTAppleHealthKit boolFromOptions:input key:@"includeUserEntered" withDefault:false];

    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeUserEntered == false) {
        NSPredicate *includeUserEntered = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeUserEntered]];
    }

    if (watchOnly) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[watchPredicate]];
    }

    [self fetchCumulativeSumStatisticsCollection:exerciseType
                                            unit:unit
                                          period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *results, NSError *error) {
                                          if(results){
                                              callback(@[[NSNull null], results]);
                                              return;
                                          } else {
                                              NSLog(@"error getting exercise time: %@", error);
                                              callback(@[RCTMakeError(@"error getting exercise time:", error, nil)]);
                                              return;
                                          }
                                      }];
}

- (void)activity_getAppleStandTime:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback API_AVAILABLE(ios(13.0))
{
    HKQuantityType *exerciseType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleStandTime];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit secondUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeUserEntered = [RCTAppleHealthKit boolFromOptions:input key:@"includeUserEntered" withDefault:false];

    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeUserEntered == false) {
        NSPredicate *includeUserEntered = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeUserEntered]];
    }

    if (watchOnly) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[watchPredicate]];
    }


    [self fetchCumulativeSumStatisticsCollection:exerciseType
                                            unit:unit
                                          period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *results, NSError *error) {
                                          if(results){
                                              callback(@[[NSNull null], results]);
                                              return;
                                          } else {
                                              NSLog(@"error getting stand time: %@", error);
                                              callback(@[RCTMakeError(@"error getting stand time:", error, nil)]);
                                              return;
                                          }
                                      }];
}

@end
