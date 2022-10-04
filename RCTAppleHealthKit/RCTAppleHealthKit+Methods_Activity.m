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

- (void)activity_getActiveEnergyBurned:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    HKQuantityType *activeEnergyType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit kilocalorieUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60 * 60 * 24];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
//    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];

    if(startDate == nil){
        reject(@"Invalid Argument", @"startDate is required in options", nil);

        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeManuallyAdded == false) {
        NSPredicate *includeManuallyAdded = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeManuallyAdded]];
    }

//    if (ignoredDevices != nil) {
//        NSPredicate *ignoredDevicesPredicate = [RCTAppleHealthKit predicateToIgnoreDevices:ignoredDevices];
//        if(ignoredDevicesPredicate != nil) {
//            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ignoredDevicesPredicate]];
//        }
//    }

    if (watchOnly) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
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
                                              resolve(results);

                                              return;
                                          } else {
                                              NSLog(@"error getting active energy burned samples: %@", error);
                                              reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting active energy burned samples: %@", error.localizedDescription], error);
                                              return;
                                          }
                                      }];
}

- (void)activity_getBasalEnergyBurned:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    HKQuantityType *basalEnergyType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit kilocalorieUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60 * 60 * 24];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
//    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];

    if(startDate == nil){
        reject(@"Invalid Argument", @"startDate is required in options", nil);
//        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeManuallyAdded == false) {
        NSPredicate *includeManuallyAdded = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeManuallyAdded]];
    }

//    if (ignoredDevices != nil) {
//        NSPredicate *ignoredDevicesPredicate = [RCTAppleHealthKit predicateToIgnoreDevices:ignoredDevices];
//        if(ignoredDevicesPredicate != nil) {
//            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ignoredDevicesPredicate]];
//        }
//    }

    if (watchOnly) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
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
                                              resolve(results);
                                              return;
                                          } else {
                                              NSLog(@"error getting basal energy burned samples: %@", error);
                                              reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting basal energy burned samples: %@", error.localizedDescription], error);
                                              return;
                                          }
                                      }];
}

- (void)activity_getAppleExerciseTime:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject API_AVAILABLE(ios(9.3))
{
    HKQuantityType *exerciseType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierAppleExerciseTime];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit minuteUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60 * 60 * 24];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
//    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];

    if(startDate == nil){
        reject(@"Invalid Argument", @"startDate is required in options", nil);
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeManuallyAdded == false) {
        NSPredicate *includeManuallyAdded = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeManuallyAdded]];
    }
    
//    if (ignoredDevices != nil) {
//        NSPredicate *ignoredDevicesPredicate = [RCTAppleHealthKit predicateToIgnoreDevices:ignoredDevices];
//        if(ignoredDevicesPredicate != nil) {
//            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ignoredDevicesPredicate]];
//        }
//    }

    if (watchOnly) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
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
                                              resolve(results);
//                                              callback(@[[NSNull null], results]);
                                              return;
                                          } else {
                                              NSLog(@"error getting exercise time: %@", error);
//                                              callback(@[RCTMakeError(@"error getting exercise time:", error, nil)]);
                                              reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting exercise time samples: %@", error.localizedDescription], error);
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
//    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];

    if(startDate == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeManuallyAdded == false) {
        NSPredicate *includeManuallyAdded = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeManuallyAdded]];
    }

//    if (watchOnly) {
//        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
//        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[watchPredicate]];
//    }


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


- (void)activity_getCaloriesBurned:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit kilocalorieUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];

    if(startDate == nil){
        reject(@"Invalid Argument", @"startDate is required in options", nil);
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ AND %K <= %@",
                                            HKPredicateKeyPathEndDate, startDate,
                                            HKPredicateKeyPathStartDate, endDate];

    if (includeManuallyAdded == false) {
        NSPredicate *includeManuallyAdded = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeManuallyAdded]];
    }
    
    if (ignoredDevices != nil) {
        NSPredicate *ignoredDevicesPredicate = [RCTAppleHealthKit predicateToIgnoreDevices:ignoredDevices];
        if(ignoredDevicesPredicate != nil) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ignoredDevicesPredicate]];
        }
    }

    if (watchOnly) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
    }
    
    [self fetchCalories:unit
                      period:period
                   predicate:predicate
                   startDate:startDate
                     endDate:endDate
                       limit:limit
                   ascending:ascending
                  completion:^(NSArray *results, NSError *error) {
                      if(results){
                          resolve(results);
                          return;
                      } else {
                          NSLog(@"error getting stand time: %@", error);
                          reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting calories: %@", error.localizedDescription], error);
                          return;
                      }
                  }];
}


@end
