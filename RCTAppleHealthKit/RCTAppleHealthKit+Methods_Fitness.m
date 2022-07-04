//
//  RCTAppleHealthKit+Methods_Fitness.m
//  RCTAppleHealthKit
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit+Methods_Fitness.h"
#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"

#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>

@implementation RCTAppleHealthKit (Methods_Fitness)

- (void)fitness_getStepCountOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];

    
    if(date == nil) {
        callback(@[RCTMakeError(@"could not parse date from options.date", nil, nil)]);
        return;
    }

    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKUnit *stepsUnit = [HKUnit countUnit];

    NSPredicate *dayPredicate = [RCTAppleHealthKit predicateForSamplesOnDay:date];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate]];
    
    [self fetchSumOfSamplesOnDayForType:stepCountType
                                    unit:stepsUnit
                                    day:date
                              predicate:predicate
                             completion:^(double value, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!value && value != 0) {
            callback(@[RCTJSErrorFromNSError(error)]);
            return;
        }

         NSDictionary *response = @{
                 @"value" : @(value),
                 @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                 @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
         };

        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit countUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    NSString *type = [RCTAppleHealthKit stringFromOptions:input key:@"type" withDefault:@"Walking"];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:[NSDate date]];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];

    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];

    HKSampleType *samplesType = [RCTAppleHealthKit quantityTypeFromName:type];

    void (^completion)(NSArray *results, NSError *error);

    completion = ^(NSArray *results, NSError *error) {
        if (results){
            callback(@[[NSNull null], results]);

            return;
        } else {
            NSLog(@"error getting samples: %@", error);
            callback(@[RCTMakeError(@"error getting samples:", error, nil)]);

            return;
        }
    };


    if ([type isEqual:@"Running"] || [type isEqual:@"Cycling"]) {
        unit = [HKUnit mileUnit];
    }

    [self fetchSamplesOfType:samplesType
                        unit:unit
                   predicate:predicate
                   ascending:ascending
                       limit:limit
                  completion:completion];
}


- (void)fitness_getDailyStepSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit countUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL includeWatch = [RCTAppleHealthKit boolFromOptions:input key:@"includeWatch" withDefault:false];
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
        if (ignoredDevicesPredicate != nil) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ignoredDevicesPredicate]];
        }
    }
    
    if (includeWatch) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateIncludeWatch];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
    }

    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];

    [self fetchCumulativeSumStatisticsCollection:stepCountType
                                            unit:unit
                                            period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *arr, NSError *err){
        if (err != nil) {
            reject(@"Error Callback", [NSString stringWithFormat:@"error getting walkingRunning distance: %@", err.localizedDescription], err);
//            callback(@[RCTJSErrorFromNSError(err)]);
            return;
        } else {
            resolve(arr);
        }
//        callback(@[[NSNull null], arr]);
    }];
}


- (void)fitness_saveSteps:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    double value = [RCTAppleHealthKit doubleFromOptions:input key:@"value" withDefault:(double)0];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];

    if(startDate == nil || endDate == nil){
        callback(@[RCTMakeError(@"startDate and endDate are required in options", nil, nil)]);
        return;
    }

    HKUnit *unit = [HKUnit countUnit];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:value];
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:type quantity:quantity startDate:startDate endDate:endDate];

    [self.healthStore saveObject:sample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            callback(@[RCTJSErrorFromNSError(error)]);
            return;
        }
        callback(@[[NSNull null], @(value)]);
    }];
}


- (void)fitness_initializeStepEventObserver:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKSampleType *sampleType =
    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];

    HKObserverQuery *query =
    [[HKObserverQuery alloc]
     initWithSampleType:sampleType
     predicate:nil
     updateHandler:^(HKObserverQuery *query,
                     HKObserverQueryCompletionHandler completionHandler,
                     NSError *error) {

         if (error) {
             callback(@[RCTJSErrorFromNSError(error)]);
             return;
         }

          [self sendEventWithName:@"change:steps" body:@{@"name": @"change:steps"}];

         // If you have subscribed for background updates you must call the completion handler here.
         // completionHandler();

     }];

    [self.healthStore executeQuery:query];
}


- (void)fitness_getDistanceWalkingRunningOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];

    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];

    if(date == nil){
        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    
    NSPredicate *dayPredicate = [RCTAppleHealthKit predicateForSamplesOnDay:date];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate]];
    
//    if (includeManuallyAdded == false) {
//        NSPredicate *includeManuallyAdded = [RCTAppleHealthKit predicateNotUserEntered];
//        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[includeManuallyAdded]];
//    }
//
//    if (watchOnly) {
//        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateWatchOnly];
//        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[watchPredicate]];
//    }

    [self fetchSumOfSamplesOnDayForType:quantityType unit:unit day:date predicate:predicate completion:^(double distance, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!distance && distance != 0) {
            callback(@[RCTJSErrorFromNSError(error)]);
            return;
        }

        NSDictionary *response = @{
                @"value" : @(distance),
                @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
        };


        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getDailyDistanceWalkingRunningSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];

    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL includeWatch = [RCTAppleHealthKit boolFromOptions:input key:@"includeWatch" withDefault:false];
    
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

    if (includeWatch) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateIncludeWatch];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
    }

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];

    [self fetchCumulativeSumStatisticsCollection:quantityType
                                            unit:unit
                                            period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *results, NSError *err){
                                          if (err != nil) {
                                              NSLog(@"error with fetchCumulativeSumStatisticsCollection: %@", err);
                                              reject(@"Error Callback", [NSString stringWithFormat:@"error getting walkingRunning distance: %@", err.localizedDescription], err);
                                              return;
                                          }
                                          resolve(results);
                                      }];
}

- (void)fitness_getDistanceSwimmingOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback API_AVAILABLE(ios(10.0))
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:true];

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceSwimming];

    NSPredicate *dayPredicate = [RCTAppleHealthKit predicateForSamplesOnDay:date];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate]];
    if (includeManuallyAdded == false) {
        NSPredicate *manualDataPredicate = [NSPredicate predicateWithFormat:@"metadata.%K != YES", HKMetadataKeyWasUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate, manualDataPredicate]];
    }
    
    [self fetchSumOfSamplesOnDayForType:quantityType unit:unit day:date predicate:predicate completion:^(double distance, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!distance && distance != 0) {
            callback(@[RCTJSErrorFromNSError(error)]);
            return;
        }

        NSDictionary *response = @{
                @"value" : @(distance),
                @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
        };

        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getDailyDistanceSwimmingSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject API_AVAILABLE(ios(10.0))
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];

    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    
    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL includeWatch = [RCTAppleHealthKit boolFromOptions:input key:@"includeWatch" withDefault:false];
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

    if (ignoredDevices != nil) {
        NSPredicate *ignoredDevicesPredicate = [RCTAppleHealthKit predicateToIgnoreDevices:ignoredDevices];
        if(ignoredDevicesPredicate != nil) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ignoredDevicesPredicate]];
        }
    }

    if (includeWatch) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateIncludeWatch];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
    }
    

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceSwimming];

    [self fetchCumulativeSumStatisticsCollection:quantityType
                                            unit:unit
                                            period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *results, NSError *err){
                                          if (err != nil) {
                                              reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting swimming distance: %@", err.localizedDescription], err);
                                              return;
                                          }
                                            resolve(results);
//                                          callback(@[[NSNull null], arr]);
                                      }];
}

- (void)fitness_getDistanceCyclingOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:true];

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];

    NSPredicate *dayPredicate = [RCTAppleHealthKit predicateForSamplesOnDay:date];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate]];
    if (includeManuallyAdded == false) {
        NSPredicate *manualDataPredicate = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[manualDataPredicate]];
    }
    
    [self fetchSumOfSamplesOnDayForType:quantityType unit:unit day:date predicate:predicate completion:^(double distance, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!distance && distance != 0) {
            callback(@[RCTJSErrorFromNSError(error)]);
            return;
        }

        NSDictionary *response = @{
                @"value" : @(distance),
                @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
        };

        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getDailyDistanceCyclingSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    
    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL includeWatch = [RCTAppleHealthKit boolFromOptions:input key:@"includeWatch" withDefault:false];
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

    if (ignoredDevices != nil) {
        NSPredicate *ignoredDevicesPredicate = [RCTAppleHealthKit predicateToIgnoreDevices:ignoredDevices];
        if(ignoredDevicesPredicate != nil) {
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ignoredDevicesPredicate]];
        }
    }

    if (includeWatch) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateIncludeWatch];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
    }

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];

    [self fetchCumulativeSumStatisticsCollection:quantityType
                                            unit:unit
                                            period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *results, NSError *err){
                                          if (err != nil) {
                                              reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting cycling distance: %@", err.localizedDescription], err);
//                                              callback(@[RCTJSErrorFromNSError(err)]);
                                              return;
                                          }
                                            resolve(results);
//                                          callback(@[[NSNull null], arr]);
                                      }];
}

- (void)fitness_getFlightsClimbedOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [HKUnit countUnit];
    NSDate *date = [RCTAppleHealthKit dateFromOptions:input key:@"date" withDefault:[NSDate date]];
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:true];

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];

    NSPredicate *dayPredicate = [RCTAppleHealthKit predicateForSamplesOnDay:date];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate]];
    if (includeManuallyAdded == false) {
        NSPredicate *manualDataPredicate = [RCTAppleHealthKit predicateNotUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[manualDataPredicate]];
    }
    
    [self fetchSumOfSamplesOnDayForType:quantityType unit:unit day:date predicate:predicate completion:^(double count, NSDate *startDate, NSDate *endDate, NSError *error) {
        if (!count && count != 0) {
            callback(@[RCTJSErrorFromNSError(error)]);
            return;
        }

        NSDictionary *response = @{
                @"value" : @(count),
                @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:startDate],
                @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:endDate],
        };

        callback(@[[NSNull null], response]);
    }];
}

- (void)fitness_getDailyFlightsClimbedSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit countUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];

    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
  
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

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];

    [self fetchCumulativeSumStatisticsCollection:quantityType
                                            unit:unit
                                            period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *arr, NSError *err){
                                          if (err != nil) {
                                              callback(@[RCTJSErrorFromNSError(err)]);
                                              return;
                                          }
                                          callback(@[[NSNull null], arr]);
                                      }];
}


- (void)fitness_getDailyDistanceDownhillSnowSportsSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject API_AVAILABLE(ios(11.2))
{
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit meterUnit]];
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSUInteger period = [RCTAppleHealthKit uintFromOptions:input key:@"period" withDefault:60];
    
    NSArray *ignoredDevices = [RCTAppleHealthKit arrayFromOptions:input key:@"ignoredDevices" defaultValue:nil];
    
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    BOOL includeWatch = [RCTAppleHealthKit boolFromOptions:input key:@"includeWatch" withDefault:false];
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

    if (includeWatch) {
        NSPredicate *watchPredicate = [RCTAppleHealthKit predicateIncludeWatch];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[watchPredicate]];
    }

    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceDownhillSnowSports];

    [self fetchCumulativeSumStatisticsCollection:quantityType
                                            unit:unit
                                            period:period
                                       predicate:predicate
                                       startDate:startDate
                                         endDate:endDate
                                           limit:limit
                                       ascending:ascending
                                      completion:^(NSArray *results, NSError *err){
                                          if (err != nil) {
                                              reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting downhill snowsports distance: %@", err.localizedDescription], err);
                                              return;
                                          }
                                            resolve(results);
                                      }];
}

/*!
    Register observer from React Native object

    @deprecated This method was deprecated. Favor the initializeBackgroundObservers() approach
 */
- (void)fitness_setObserver:(NSDictionary *)input __deprecated
{
    RCTLogWarn(@"The setObserver() method has been deprecated in favor of initializeBackgroundObservers()");

    NSString *type = [RCTAppleHealthKit stringFromOptions:input key:@"type" withDefault:@"Walking"];
    HKSampleType *sampleType = [RCTAppleHealthKit quantityTypeFromName:type];

    [self setObserverForType:sampleType type:type];
}

/*!
    Register observer for a specifc human readable type

    @param type Human Readable type
 */
- (void)fitness_registerObserver:(NSString *)type
                          bridge:(RCTBridge *)bridge
                    hasListeners:(bool)hasListeners
{
    HKSampleType *sampleType = [RCTAppleHealthKit quantityTypeFromName:type];

    [self setObserverForType:sampleType type:type bridge:bridge hasListeners:hasListeners];
}

@end
