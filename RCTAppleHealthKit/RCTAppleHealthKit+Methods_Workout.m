//
//  RCTAppleHealthKit+Methods_Workout.m
//  RCTAppleHealthKit
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit+Methods_Workout.h"
#import "RCTAppleHealthKit+Utils.h"
#import "RCTAppleHealthKit+Queries.h"

@implementation RCTAppleHealthKit (Methods_Workout)

- (void)workout_loadAllWorkoutLocations:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    HKSampleType *workoutType = [HKSeriesType workoutType];
    HKQueryAnchor *anchor = [RCTAppleHealthKit hkAnchorFromOptions:input];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];
    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    
    if(startDate == nil){
        reject(@"Invalid Argument", @"startDate is required in options", nil);
        return;
    }
    
    NSPredicate *predicate = [RCTAppleHealthKit predicateForAnchoredQueries:anchor startDate:startDate endDate:endDate];

    
    void (^completion)(NSDictionary *results, NSError *error);
    
    completion = ^(NSDictionary *results, NSError *error) {
        if (results){
            resolve(results);
//            callback(@[[NSNull null], results]);
            
            return;
        } else {
            NSLog(@"error getting samples: %@", error);
//            callback(@[RCTMakeError(@"error getting samples", error, nil)]);
            reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting active energy burned samples: %@", error.localizedDescription], error);
            
            return;
        }
    };
    
    [self fetchAllWorkoutLocations:workoutType
                      predicate:predicate
                         anchor:anchor
                          limit:limit
                         ascending:ascending
              includeManuallyAdded:includeManuallyAdded
                         watchOnly:watchOnly
                     completion:completion];
}

- (void)workout_getAnchoredQuery:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    NSUInteger limit = [RCTAppleHealthKit uintFromOptions:input key:@"limit" withDefault:HKObjectQueryNoLimit];
    
    HKSampleType *workoutType = [HKObjectType workoutType];
    HKQueryAnchor *anchor = [RCTAppleHealthKit hkAnchorFromOptions:input];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    
    BOOL includeManuallyAdded = [RCTAppleHealthKit boolFromOptions:input key:@"includeManuallyAdded" withDefault:false];
//    BOOL watchOnly = [RCTAppleHealthKit boolFromOptions:input key:@"watchOnly" withDefault:false];
    BOOL ascending = [RCTAppleHealthKit boolFromOptions:input key:@"ascending" withDefault:false];
    
    if(startDate == nil){
        reject(@"Invalid Argument", @"startDate is required in options", nil);
//        callback(@[RCTMakeError(@"startDate is required in options", nil, nil)]);
        return;
    }
    
    NSPredicate *predicate = [RCTAppleHealthKit predicateForAnchoredQueries:anchor startDate:startDate endDate:endDate];
    
//    if (includeManuallyAdded == false) {
//        NSPredicate *manualDataPredicate = [RCTAppleHealthKit predicateNotUserEntered];
//        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[manualDataPredicate]];
//    }
    
//    if (watchOnly) {
//        NSPredicate *watchOnlyPredicate = [RCTAppleHealthKit predicateWatchOnly];
//        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[watchOnlyPredicate]];
//    }
    
    void (^completion)(NSDictionary *results, NSError *error);

    completion = ^(NSDictionary *results, NSError *error) {
        if (results){
//            callback(@[[NSNull null], results]);
            resolve(results);
            return;
        } else {
            NSLog(@"error getting samples: %@", error);
            reject(@"ErrorCallback", [NSString stringWithFormat:@"error getting active energy burned samples: %@", error.localizedDescription], error);

            return;
        }
    };

    [self fetchAnchoredWorkouts:workoutType predicate:predicate anchor:anchor limit:limit ascending:ascending completion:completion];
}

- (void)workout_save: (NSDictionary *)input callback: (RCTResponseSenderBlock)callback {
    HKWorkoutActivityType type = [RCTAppleHealthKit hkWorkoutActivityTypeFromOptions:input key:@"type" withDefault:HKWorkoutActivityTypeAmericanFootball];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:nil];
    NSTimeInterval duration = [RCTAppleHealthKit doubleFromOptions:input key:@"duration" withDefault:(NSTimeInterval)0];
    HKQuantity *totalEnergyBurned = [RCTAppleHealthKit hkQuantityFromOptions:input valueKey:@"energyBurned" unitKey:@"energyBurnedUnit"];
    HKQuantity *totalDistance = [RCTAppleHealthKit hkQuantityFromOptions:input valueKey:@"distance" unitKey:@"distanceUnit"];


    HKWorkout *workout = [
                          HKWorkout workoutWithActivityType:type startDate:startDate endDate:endDate workoutEvents:nil totalEnergyBurned:totalEnergyBurned totalDistance:totalDistance metadata: nil
                          ];

    void (^completion)(BOOL success, NSError *error);

    completion = ^(BOOL success, NSError *error){
        if (!success) {
            NSLog(@"An error occured saving the workout %@. The error was: %@.", workout, error);
            callback(@[RCTMakeError(@"An error occured saving the workout", error, nil)]);

            return;
        }
        callback(@[[NSNull null], [[workout UUID] UUIDString]]);
    };

    [self.healthStore saveObject:workout withCompletion:completion];
}
@end
