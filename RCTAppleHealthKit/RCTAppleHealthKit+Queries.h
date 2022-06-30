//
//  RCTAppleHealthKit+Queries.h
//  RCTAppleHealthKit
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit.h"

@interface RCTAppleHealthKit (Queries)

- (void)fetchMostRecentQuantitySampleOfType:(HKQuantityType *)quantityType
                                  predicate:(NSPredicate *)predicate
                                 completion:(void (^)(HKQuantity *mostRecentQuantity, NSDate *startDate, NSDate *endDate, NSError *error))completion;

- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType
                                 unit:(HKUnit *)unit
                           completion:(void (^)(double, NSError *))completionHandler;

- (void)fetchSumOfSamplesOnDayForType:(HKQuantityType *)quantityType
                                   unit:(HKUnit *)unit
                                   day:(NSDate *)day
                            predicate:(NSPredicate *)predicate
                           completion:(void (^)(double, NSDate *, NSDate *, NSError *))completionHandler;

- (void)fetchSamplesOfType:(HKSampleType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion;

- (void)fetchClinicalRecordsOfType:(HKClinicalType *)type
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion;

- (void)fetchAnchoredWorkouts:(HKSampleType *)type
                    predicate:(NSPredicate *)predicate
                       anchor:(HKQueryAnchor *)anchor
                        limit:(NSUInteger)lim
                    ascending:(BOOL)asc
                   completion:(void (^)(NSDictionary *, NSError *))completion;

- (void)fetchQuantitySamplesOfType:(HKQuantityType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion;


- (void)fetchQuantitySamplesOfTypeWithNoDevice:(HKQuantityType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                         watchOnly:(BOOL)watchOnly
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion;

- (void)fetchCompleteQuantitySamplesOfType:(HKQuantityType *)quantityType
                                      unit:(HKUnit *)unit
                                 predicate:(NSPredicate *)predicate
                                 ascending:(BOOL)asc
                                     limit:(NSUInteger)lim
                                completion:(void (^)(NSArray *, NSError *))completion;

- (void)fetchCorrelationSamplesOfType:(HKQuantityType *)quantityType
                                 unit:(HKUnit *)unit
                            predicate:(NSPredicate *)predicate
                            ascending:(BOOL)asc
                                limit:(NSUInteger)lim
                           completion:(void (^)(NSArray *, NSError *))completion;

//- (void)fetchCumulativeSumStatisticsCollection:(HKQuantityType *)quantityType
//                                          unit:(HKUnit *)unit
//                                     startDate:(NSDate *)startDate
//                                       endDate:(NSDate *)endDate
//                                    completion:(void (^)(NSArray *, NSError *))completionHandler;
//
//- (void)fetchCumulativeSumStatisticsCollection:(HKQuantityType *)quantityType
//                                          unit:(HKUnit *)unit
//                                     startDate:(NSDate *)startDate
//                                       endDate:(NSDate *)endDate
//                                     ascending:(BOOL)asc
//                                         limit:(NSUInteger)lim
//                                    completion:(void (^)(NSArray *, NSError *))completionHandler;

- (void)fetchCumulativeSumStatisticsCollection:(HKQuantityType *)quantityType
                                          unit:(HKUnit *)unit
                                        period:(NSUInteger)period
                                     predicate:(NSPredicate *)predicate
                                     startDate:(NSDate *)startDate
                                       endDate:(NSDate *)endDate
                                         limit:(NSUInteger)lim
                                     ascending:(BOOL)asc
                                    completion:(void (^)(NSArray *, NSError *))completionHandler;

- (void)fetchSleepCategorySamplesForPredicate:(NSPredicate *)predicate
                                   limit:(NSUInteger)lim
                                    ascending:(BOOL)asc
                                    watchOnly:(BOOL)watchOnly
                                   completion:(void (^)(NSArray *, NSError *))completion;

- (void)fetchWorkoutForPredicate:(NSPredicate *)predicate
                       ascending:(BOOL)ascending
                           limit:(NSUInteger)limit
                      completion:(void (^)(NSArray *, NSError *))completion;

- (void)setObserverForType:(HKSampleType *)quantityType
                      type:(NSString *)type __deprecated;

- (void)setObserverForType:(HKSampleType *)quantityType
                      type:(NSString *)type
                    bridge:(RCTBridge *)bridge
                    hasListeners:(bool)hasListeners;

- (void)fetchActivitySummary:(NSDate *)startDate
                     endDate:(NSDate *)endDate
                  completion:(void (^)(NSArray *, NSError *))completionHandler;

/*@yulianto.kevin add workout route*/

- (void)fetchAllWorkoutLocations:(HKSampleType *)type
                    predicate:(NSPredicate *)predicate
                       anchor:(HKQueryAnchor *)anchor
                        limit:(NSUInteger)lim
                       ascending:(BOOL)ascending
                      completion:(void (^)(NSDictionary *, NSError *))completion;

- (void)fetchWorkoutRouteHealthStore: (HKWorkout *)workout
                    completion:(void (^)(NSArray<CLLocation *> *, NSError *))completion;


- (void)fetchWorkoutsHealthStore: (HKSampleType *)type
                                predicate:(NSPredicate *)predicate
                                   anchor:(HKQueryAnchor *)anchor
                                    limit:(NSUInteger)lim
                                completion:(void (^)(NSArray<HKWorkout *> *workouts, HKQueryAnchor * _Nullable newAnchor, NSError *error))completion;

-(void)fetchCalories:(HKUnit *)unit
              period:(NSUInteger)period
              predicate:(NSPredicate *)predicate
              startDate:(NSDate *)startDate
              endDate:(NSDate *)endDate
              limit:(NSUInteger)lim
              ascending:(BOOL)asc
          completion:(void (^)(NSArray *, NSError *))completion;

/*@yulianto.kevin end*/
@end
