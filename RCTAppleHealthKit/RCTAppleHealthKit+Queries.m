//
//  RCTAppleHealthKit+Queries.m
//  RCTAppleHealthKit
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"
#import "RCTAppleHealthKit+TypesAndPermissions.h"

#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
// #import "OMHSerializer.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@implementation RCTAppleHealthKit (Queries)

- (void)fetchMostRecentQuantitySampleOfType:(HKQuantityType *)quantityType
                                  predicate:(NSPredicate *)predicate
                                 completion:(void (^)(HKQuantity *, NSDate *, NSDate *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc]
            initWithKey:HKSampleSortIdentifierEndDate
              ascending:NO
    ];

    HKSampleQuery *query = [[HKSampleQuery alloc]
            initWithSampleType:quantityType
                     predicate:predicate
                         limit:1
               sortDescriptors:@[timeSortDescriptor]
                resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {

                      if (!results) {
                          if (completion) {
                              completion(nil, nil, nil, error);
                          }
                          return;
                      }

                      if (completion) {
                          // If quantity isn't in the database, return nil in the completion block.
                          HKQuantitySample *quantitySample = results.firstObject;
                          HKQuantity *quantity = quantitySample.quantity;
                          NSDate *startDate = quantitySample.startDate;
                          NSDate *endDate = quantitySample.endDate;
                          completion(quantity, startDate, endDate, error);
                      }
                }
    ];
    [self.healthStore executeQuery:query];
}

- (void)fetchQuantitySamplesOfType:(HKQuantityType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];

    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKQuantitySample *sample in results) {

                    HKQuantity *quantity = sample.quantity;
                    double value = [quantity doubleValueForUnit:unit];

                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];

                    NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];
                    bool isFromWatch = [RCTAppleHealthKit validateFromWatch:sample];
                    bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:sample];
                    id sourceType = [RCTAppleHealthKit getSourceType:sample];
      
                    NSDictionary *elem = @{
                            @"value" : @(value),
                            @"id" : [[sample UUID] UUIDString],
                            @"sourceName" : [[[sample sourceRevision] source] name],
                            @"sourceId" : [[[sample sourceRevision] source] bundleIdentifier],
                            @"sourceType": sourceType,
                            @"startDate" : startDateString,
                            @"endDate" : endDateString,
                            @"metadata": [sample metadata],
                            @"device": device,
                            @"isUserEntered": @(isUserEntered),
                            @"isFromWatch": @(isFromWatch)
                    };

                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

- (void)fetchQuantitySamplesOfType:(HKQuantityType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                         watchOnly:(BOOL)watchOnly
              includeManuallyAdded:(BOOL)includeManuallyAdded
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];

    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKQuantitySample *sample in results) {

                    bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:sample];
                    bool isFromWatch = [RCTAppleHealthKit validateFromWatch:sample];
                    if (!includeManuallyAdded && isUserEntered) {
                        // if user doesn't want to get manual data input and the data is from manual input, then continue
                        continue;
                    }
                    
                    if (watchOnly && !isFromWatch) {
                        // if user wanted to get watchonly source data and the data is not from watch, then continue
                        continue;
                    }
                    HKQuantity *quantity = sample.quantity;
                    double value = [quantity doubleValueForUnit:unit];

                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];

                    NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];

                    id sourceType = [RCTAppleHealthKit getSourceType:sample];
      
                    NSDictionary *elem = @{
                            @"value" : @(value),
                            @"id" : [[sample UUID] UUIDString],
                            @"sourceName" : [[[sample sourceRevision] source] name],
                            @"sourceId" : [[[sample sourceRevision] source] bundleIdentifier],
                            @"sourceType": sourceType,
                            @"startDate" : startDateString,
                            @"endDate" : endDateString,
                            @"metadata": [sample metadata],
                            @"device": device,
                            @"isUserEntered": @(isUserEntered),
                            @"isFromWatch": @(isFromWatch)
                    };

                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

// for vo2max data (not returning device)
- (void)fetchQuantitySamplesOfTypeWithNoDevice:(HKQuantityType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                         watchOnly:(BOOL)watchOnly
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];

    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKQuantitySample *sample in results) {
                        
                    HKQuantity *quantity = sample.quantity;
                    double value = [quantity doubleValueForUnit:unit];

                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];
                    
                    NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];
//                    bool isFromWatch = [RCTAppleHealthKit validateFromWatch:sample];
                    bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:sample];
                    id sourceType = [RCTAppleHealthKit getSourceType:sample];
                    
                    NSDictionary *elem = @{
                            @"value" : @(value),
                            @"id" : [[sample UUID] UUIDString],
                            @"sourceName" : [[[sample sourceRevision] source] name],
                            @"sourceId" : [[[sample sourceRevision] source] bundleIdentifier],
                            @"sourceType": sourceType,
                            @"startDate" : startDateString,
                            @"endDate" : endDateString,
                            @"metadata": [sample metadata],
                            @"device": device,
                            @"isUserEntered": @(isUserEntered),
                            @"isFromWatch": [NSNull null] // vo2max data not storing the device model
                    };

                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

/* Actxa **/
- (void)fetchCompleteQuantitySamplesOfType:(HKQuantityType *)quantityType
                              unit:(HKUnit *)unit
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];

    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKQuantitySample *sample in results) {
            
                    HKQuantity *quantity = sample.quantity;
                    double value = [quantity doubleValueForUnit:unit];

                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];
                    
                    
//                    bool isUserEntered = false;
//                    if ([[sample metadata][HKMetadataKeyWasUserEntered] intValue] == 1) {
//                        isUserEntered = true;
//                    }
//
//                    id sourceType = [NSNull null];
//                    if (@available(iOS 11.0, *)) {
//                        sourceType = [[sample sourceRevision] productType];
//                    } else {
//                        sourceType = [[sample device] name];
//                        if (!sourceType) {
//                            sourceType = [NSNull null];
//                        }
//                    }

//                    NSDictionary *device = @{
//                        @"name": [[sample device] name] ?: [NSNull null],
//                        @"model": [[sample device] model] ?: [NSNull null],
//                        @"manufacturer": [[sample device] manufacturer] ?: [NSNull null],
//                        @"UDIDDevice": [[sample device] UDIDeviceIdentifier] ?: [NSNull null],
//                        @"LocalID": [[sample device] localIdentifier] ?: [NSNull null],
//                    };
//                    NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];
                    
                    NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];
                    bool isFromWatch = [RCTAppleHealthKit validateFromWatch:sample];
                    bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:sample];
                    id sourceType = [RCTAppleHealthKit getSourceType:sample];
                    
                    NSDictionary *elem = @{
                            @"value" : @(value),
                            @"id" : [[sample UUID] UUIDString],
                            @"sourceName" : [[[sample sourceRevision] source] name],
                            @"sourceId" : [[[sample sourceRevision] source] bundleIdentifier],
                            @"sourceType": sourceType,
                            @"startDate" : startDateString,
                            @"endDate" : endDateString,
                            @"metadata": [sample metadata],
                            @"device": device,
                            @"isUserEntered": @(isUserEntered),
                            @"isFromWatch": @(isFromWatch)
                    };

                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

- (void)fetchSamplesOfType:(HKSampleType *)type
                      unit:(HKUnit *)unit
                 predicate:(NSPredicate *)predicate
                 ascending:(BOOL)asc
                     limit:(NSUInteger)lim
                completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];

    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);

    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (type == [HKObjectType workoutType]) {
                    for (HKWorkout *sample in results) {
                        @try {
                            double energy =  [[sample totalEnergyBurned] doubleValueForUnit:[HKUnit kilocalorieUnit]];
                            double distance = [[sample totalDistance] doubleValueForUnit:[HKUnit mileUnit]];
                            NSString *workoutType = [RCTAppleHealthKit stringForHKWorkoutActivityType:[sample workoutActivityType]];

                            NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                            NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];

//                            bool isUserEntered = false;
//                            if ([[sample metadata][HKMetadataKeyWasUserEntered] intValue] == 1) {
//                                isUserEntered = true;
//                            }
//
//                            NSString* device = @"";
//                            if (@available(iOS 11.0, *)) {
//                                device = [[sample sourceRevision] productType];
//                            } else {
//                                device = [[sample device] name];
//                                if (!device) {
//                                    device = @"iPhone";
//                                }
//                            }
                            
                            NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];
                            bool isFromWatch = [RCTAppleHealthKit validateFromWatch:sample];
                            bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:sample];
                            id sourceType = [RCTAppleHealthKit getSourceType:sample];

                            NSDictionary *elem = @{
                                                   @"activityId" : [NSNumber numberWithInt:[sample workoutActivityType]],
                                                   
                                                   @"id" : [[sample UUID] UUIDString],
                                                   @"activityName" : workoutType,
                                                   @"calories" : @(energy),
                                                   @"metadata" : [sample metadata],
                                                   @"sourceName" : [[[sample sourceRevision] source] name],
                                                   @"sourceId" : [[[sample sourceRevision] source] bundleIdentifier],
                                                   @"sourceType": sourceType,
                                                   @"device": device,
                                                   @"distance" : @(distance),
                                                   @"start" : startDateString,
                                                   @"end" : endDateString,
                                                   @"isUserEntered" : @(isUserEntered),
                                                   @"isFromWatch" : @(isFromWatch),
                                                   };

                            [data addObject:elem];
                        } @catch (NSException *exception) {
                            NSLog(@"RNHealth: An error occured while trying to add sample from: %@ ", [[[sample sourceRevision] source] bundleIdentifier]);
                        }
                    }
                } else {
                    for (HKQuantitySample *sample in results) {
                        @try {
                            HKQuantity *quantity = sample.quantity;
                            double value = [quantity doubleValueForUnit:unit];

                            NSString * valueType = @"quantity";
                            if (unit == [HKUnit mileUnit]) {
                                valueType = @"distance";
                            }

                            NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                            NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];

//                            bool isTracked = true;
//                            if ([[sample metadata][HKMetadataKeyWasUserEntered] intValue] == 1) {
//                                isTracked = false;
//                            }
//
//                            NSString* device = @"";
//                            if (@available(iOS 11.0, *)) {
//                                device = [[sample sourceRevision] productType];
//                            } else {
//                                device = [[sample device] name];
//                                if (!device) {
//                                    device = @"iPhone";
//                                }
//                            }
                            
                            NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];
                            bool isFromWatch = [RCTAppleHealthKit validateFromWatch:sample];
                            bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:sample];
                            id sourceType = [RCTAppleHealthKit getSourceType:sample];

                            NSDictionary *elem = @{
                                                   valueType : @(value),
                                                   @"isUserEntered" : @(isUserEntered),
                                                   @"isFromWatch": @(isFromWatch),
                                                   @"sourceName" : [[[sample sourceRevision] source] name],
                                                   @"sourceId" : [[[sample sourceRevision] source] bundleIdentifier],
                                                   @"sourceType": sourceType,
                                                   @"device": device,
                                                   @"start" : startDateString,
                                                   @"end" : endDateString
                                                   };

                            [data addObject:elem];
                        } @catch (NSException *exception) {
                            NSLog(@"RNHealth: An error occured while trying to add sample from: %@ ", [[[sample sourceRevision] source] bundleIdentifier]);
                        }
                    }
                }

                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:type
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

- (void)fetchClinicalRecordsOfType:(HKClinicalType *)type
                         predicate:(NSPredicate *)predicate
                         ascending:(BOOL)asc
                             limit:(NSUInteger)lim
                        completion:(void (^)(NSArray *, NSError *))completion
API_AVAILABLE(ios(12.0))
{
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:asc];
    
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);

    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                for (HKClinicalRecord *record in results) {
                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:record.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:record.endDate];
                    
                    NSError *jsonE = nil;
                    NSArray *fhirData = [NSJSONSerialization JSONObjectWithData:record.FHIRResource.data options: NSJSONReadingMutableContainers error: &jsonE];

                    if (!fhirData) {
                      completion(nil, jsonE);
                    }
                    
                    NSString *fhirRelease;
                    NSString *fhirVersion;
                    if (@available(iOS 14.0, *)) {
                        HKFHIRVersion *fhirResourceVersion = record.FHIRResource.FHIRVersion;
                        fhirRelease = fhirResourceVersion.FHIRRelease;
                        fhirVersion = fhirResourceVersion.stringRepresentation;
                    } else {
                        // iOS < 14 uses DSTU2
                        fhirRelease = @"DSTU2";
                        fhirVersion = @"1.0.2";
                    }
                        
                    NSDictionary *elem = @{
                        @"id" : [[record UUID] UUIDString],
                        @"sourceName" : [[[record sourceRevision] source] name],
                        @"sourceId" : [[[record sourceRevision] source] bundleIdentifier],
                        @"startDate" : startDateString,
                        @"endDate" : endDateString,
                        @"displayName" : record.displayName,
                        @"fhirData": fhirData,
                        @"fhirRelease": fhirRelease,
                        @"fhirVersion": fhirVersion,
                    };
                    [data addObject:elem];
                }
                completion(data, error);
            });
        }
    };
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:type predicate:predicate limit:lim sortDescriptors:@[timeSortDescriptor] resultsHandler:handlerBlock];
    [self.healthStore executeQuery:query];
}

//- (void)fetchWorkouts:(HKSampleType *)type
//                    predicate:(NSPredicate *)predicate
//                       anchor:(HKQueryAnchor *)anchor
//                        limit:(NSUInteger)lim
//                   completion:(void (^)(NSDictionary *, NSError *))completion {
//    // declare the block
//    void (^handlerBlock)(HKAnchoredObjectQuery *query, NSArray<__kindof HKSample *> *sampleObjects, NSArray<HKDeletedObject *> *deletedObjects, HKQueryAnchor *newAnchor, NSError *error);
//
//    // create and assign the block
//    handlerBlock = ^(HKAnchoredObjectQuery *query, NSArray<__kindof HKSample *> *sampleObjects, NSArray<HKDeletedObject *> *deletedObjects, HKQueryAnchor *newAnchor, NSError *error) {
//
//        if (!sampleObjects) {
//            if (completion) {
//                completion(nil, error);
//            }
//            return;
//        }
//
//        if (completion) {
//            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//                for (HKWorkout *sample in sampleObjects) {
//
//                    OMHSerializer *serializer = [OMHSerializer new];
//                    NSString* jsonString = [serializer jsonForSample:sample error:nil];
//                    NSLog(@"sample json: %@", jsonString);
//
//                    [data addObject:jsonString];
//                }
//
//                NSData *anchorData = [NSKeyedArchiver archivedDataWithRootObject:newAnchor];
//                NSString *anchorString = [anchorData base64EncodedStringWithOptions:0];
//                completion(@{
//                            @"anchor": anchorString,
//                            @"data": data,
//                        }, error);
//            });
//        }
//    };
//
//    HKAnchoredObjectQuery *query = [[HKAnchoredObjectQuery alloc] initWithType:type
//                                                                     predicate:predicate
//                                                                        anchor:anchor
//                                                                         limit:lim
//                                                                resultsHandler:handlerBlock];
//
//    [self.healthStore executeQuery:query];
//}

- (void)fetchAnchoredWorkouts:(HKSampleType *)type
                    predicate:(NSPredicate *)predicate
                       anchor:(HKQueryAnchor *)anchor
                        limit:(NSUInteger)lim
                    ascending:(BOOL)asc
                   completion:(void (^)(NSDictionary *, NSError *))completion {
    
    // declare the block
    void (^handlerBlock)(HKAnchoredObjectQuery *query, NSArray<__kindof HKSample *> *sampleObjects, NSArray<HKDeletedObject *> *deletedObjects, HKQueryAnchor *newAnchor, NSError *error);

    // create and assign the block
    handlerBlock = ^(HKAnchoredObjectQuery *query, NSArray<__kindof HKSample *> *sampleObjects, NSArray<HKDeletedObject *> *deletedObjects, HKQueryAnchor *newAnchor, NSError *error) {

        if (!sampleObjects) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{
                for (HKWorkout *sample in sampleObjects) {
                    @try {
                        NSDictionary *elem = [RCTAppleHealthKit serializeWorkout:sample];

                        [data addObject:elem];
                    } @catch (NSException *exception) {
                        NSLog(@"RNHealth: An error occured while trying to add workout sample from: %@ ", [[[sample sourceRevision] source] bundleIdentifier]);
                    }
                }
                
                NSData *anchorData = [NSKeyedArchiver archivedDataWithRootObject:newAnchor];
                NSString *anchorString = [anchorData base64EncodedStringWithOptions:0];
                completion(@{
                            @"anchor": anchorString,
                            @"data": data,
                        }, error);
            });
        }
    };
    
    HKAnchoredObjectQuery *query = [[HKAnchoredObjectQuery alloc] initWithType:type
                                                                     predicate:predicate
                                                                        anchor:anchor
                                                                         limit:lim
                                                                resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

- (void)fetchSleepCategorySamplesForPredicate:(NSPredicate *)predicate
                                        limit:(NSUInteger)lim
                                    ascending:(BOOL)asc
                         includeManuallyAdded:(BOOL)includeManuallyAdded
                              appleHealthOnly:(BOOL)appleHealthOnly
                                   completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
        ascending:asc];


    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{
                
                for (HKCategorySample *sample in results) {
                    NSString *sourceId = [[[sample sourceRevision] source] bundleIdentifier];
                    
                    bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:sample];
                    if (!includeManuallyAdded && isUserEntered) {
                        continue;
                    }
                    
                    if (appleHealthOnly && [sourceId rangeOfString:@"com.apple.health" options:NSCaseInsensitiveSearch].location == NSNotFound)
                    {
                        continue;
                    }
                    

                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];
                    
                    NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];
                    id sourceType = [RCTAppleHealthKit getSourceType:sample];
                    
                    NSDictionary *elem = @{
                        @"id" : [[sample UUID] UUIDString],
                        @"sleepCategory" : @(sample.value),
                        @"startDate" : startDateString,
                        @"endDate" : endDateString,
                        @"device" : device,
                        @"sourceType": sourceType,
                        @"operatingSystemVersion": @{
                            @"minor": @([[sample sourceRevision] operatingSystemVersion].minorVersion),
                            @"major": @([[sample sourceRevision] operatingSystemVersion].majorVersion),
                            @"patchVersion": @([[sample sourceRevision] operatingSystemVersion].patchVersion)
                        },
                        @"version": [[sample sourceRevision] version],
                        @"sourceName" : [[[sample sourceRevision] source] name] ?: [NSNull null],
                        @"metadata" : [sample metadata] ?: [NSNull null],
                        @"sourceId" : [[[sample sourceRevision] source] bundleIdentifier] ?: [NSNull null],
                        @"isUserEntered": @(isUserEntered),
                        @"isFromWatch": [NSNull null], // sleep data unable to check data is from apple watch.
                    };
                    
                    [data addObject: elem];
            
                }

                completion(data, error);
            });
        }
    };

    HKCategoryType *categoryType = [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:categoryType
                                                          predicate:predicate
                                                              limit:lim
                                                    sortDescriptors:@[timeSortDescriptor]
                                                     resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

- (void)fetchCorrelationSamplesOfType:(HKQuantityType *)quantityType
                                 unit:(HKUnit *)unit
                            predicate:(NSPredicate *)predicate
                            ascending:(BOOL)asc
                                limit:(NSUInteger)lim
                           completion:(void (^)(NSArray *, NSError *))completion {

    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate
                                                                       ascending:asc];

    // declare the block
    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    // create and assign the block
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

            dispatch_async(dispatch_get_main_queue(), ^{

                for (HKCorrelation *sample in results) {
                    NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate];
                    NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate];

                    NSDictionary *elem = @{
                      @"correlation" : sample,
                      @"startDate" : startDateString,
                      @"endDate" : endDateString,
                    };
                    [data addObject:elem];
                }

                completion(data, error);
            });
        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType
                                                           predicate:predicate
                                                               limit:lim
                                                     sortDescriptors:@[timeSortDescriptor]
                                                      resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType
                                 unit:(HKUnit *)unit
                           completion:(void (^)(double, NSError *))completionHandler {

    NSPredicate *predicate = [RCTAppleHealthKit predicateForSamplesToday];
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType
                                                          quantitySamplePredicate:predicate
                                                          options:HKStatisticsOptionCumulativeSum
                                                          completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                                                                HKQuantity *sum = [result sumQuantity];
                                                                if (completionHandler) {
                                                                    double value = [sum doubleValueForUnit:unit];
                                                                    completionHandler(value, error);
                                                                }
                                                          }];

    [self.healthStore executeQuery:query];
}

- (void)fetchSumOfSamplesOnDayForType:(HKQuantityType *)quantityType
                                 unit:(HKUnit *)unit
                                  day:(NSDate *)day
                            predicate:(NSPredicate *)predicate
                           completion:(void (^)(double, NSDate *, NSDate *, NSError *))completionHandler {
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType
      quantitySamplePredicate:predicate
      options:HKStatisticsOptionCumulativeSum
      completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        if ([error.localizedDescription isEqualToString:@"No data available for the specified predicate."] && completionHandler) {
          completionHandler(0, day, day, nil);
        } else if (completionHandler) {
            NSLog(@"result.description %@",result.description);
            HKQuantity *sum = [result sumQuantity];
            NSDate *startDate = result.startDate;
            NSDate *endDate = result.endDate;
            double value = [sum doubleValueForUnit:unit];
            completionHandler(value, startDate, endDate, error);
        }
    }];

    [self.healthStore executeQuery:query];
}

- (void)fetchSumOfSamplesOnDayForType:(HKQuantityType *)quantityType
                                 unit:(HKUnit *)unit
                                 includeManuallyAdded:(BOOL)includeManuallyAdded
                                  day:(NSDate *)day
                           completion:(void (^)(double, NSDate *, NSDate *, NSError *))completionHandler {
    NSPredicate *dayPredicate = [RCTAppleHealthKit predicateForSamplesOnDay:day];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate]];
    if (includeManuallyAdded == false) {
        NSPredicate *manualDataPredicate = [NSPredicate predicateWithFormat:@"metadata.%K != YES", HKMetadataKeyWasUserEntered];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[dayPredicate, manualDataPredicate]];
    }
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType
                                                          quantitySamplePredicate:predicate
                                                          options:HKStatisticsOptionCumulativeSum
                                                          completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                                                              if ([error.localizedDescription isEqualToString:@"No data available for the specified predicate."] && completionHandler) {
                                                                  completionHandler(0, day, day, nil);
                                                                } else if (completionHandler) {
                                                                    HKQuantity *sum = [result sumQuantity];
                                                                    NSDate *startDate = result.startDate;
                                                                    NSDate *endDate = result.endDate;
                                                                    double value = [sum doubleValueForUnit:unit];
                                                                    completionHandler(value, startDate, endDate, error);
                                                              }
                                                          }];

    [self.healthStore executeQuery:query];
}

- (void)fetchCumulativeSumStatisticsCollection:(HKQuantityType *)quantityType
                                          unit:(HKUnit *)unit
                                        period:(NSUInteger)period
                                     predicate:(NSPredicate *)predicate
                                     startDate:(NSDate *)startDate
                                       endDate:(NSDate *)endDate
                                         limit:(NSUInteger)lim
                                     ascending:(BOOL)asc
                                    completion:(void (^)(NSArray *, NSError *))completionHandler {

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.second = period;

    NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                     fromDate:startDate];
//    anchorComponents.hour = 0;
    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];

    // Create the query
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                                                           quantitySamplePredicate:predicate
                                                                                           options:HKStatisticsOptionCumulativeSum
                                                                                        anchorDate:anchorDate
                                                                                intervalComponents:interval];

    // Set the results handler
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***", error.localizedDescription);
            completionHandler(data, error);
            return;
        }

        [results enumerateStatisticsFromDate:startDate
                                      toDate:endDate
                                   withBlock:^(HKStatistics *result, BOOL *stop) {

                                       HKQuantity *quantity = result.sumQuantity;

                                       if (quantity) {
                                           NSDate *startDate = result.startDate;
                                           NSDate *endDate = result.endDate;

                                           double value = [quantity doubleValueForUnit:unit];

                                           NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:startDate];
                                           NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:endDate];

                                           NSDictionary *elem = @{
                                                   @"value" : @(value),
                                                   @"startDate" : startDateString,
                                                   @"endDate" : endDateString,
                                           };
                                           [data addObject:elem];
                                       }
                                   }];
        // is descending by default
        if(asc == false) {
            [RCTAppleHealthKit reverseNSMutableArray:data];
        }

        if((lim > 0) && ([data count] > lim)) {
            NSArray* slicedArray = [data subarrayWithRange:NSMakeRange(0, lim)];
            NSError *err;
            completionHandler(slicedArray, err);
        } else {
            NSError *err;
            completionHandler(data, err);
        }
    };

    [self.healthStore executeQuery:query];
}

- (void)fetchCumulativeSumStatisticsCollection:(HKQuantityType *)quantityType
                                          unit:(HKUnit *)unit
                                     startDate:(NSDate *)startDate
                                       endDate:(NSDate *)endDate
                                     ascending:(BOOL)asc
                                         limit:(NSUInteger)lim
                                    completion:(void (^)(NSArray *, NSError *))completionHandler {

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.day = 1;

    NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                     fromDate:[NSDate date]];
    anchorComponents.hour = 0;
    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"metadata.%K != YES AND %K >= %@ AND %K <= %@",
                              HKMetadataKeyWasUserEntered,
                              HKPredicateKeyPathEndDate, startDate,
                              HKPredicateKeyPathStartDate, endDate];
    // Create the query
    HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                                                           quantitySamplePredicate:predicate
                                                                                           options:HKStatisticsOptionCumulativeSum
                                                                                        anchorDate:anchorDate
                                                                                intervalComponents:interval];

    // Set the results handler
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***", error.localizedDescription);
        }

        NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

        [results enumerateStatisticsFromDate:startDate
                                      toDate:endDate
                                   withBlock:^(HKStatistics *result, BOOL *stop) {

                                       HKQuantity *quantity = result.sumQuantity;
                                       if (quantity) {
                                           NSDate *startDate = result.startDate;
                                           NSDate *endDate = result.endDate;
                                           double value = [quantity doubleValueForUnit:unit];

                                           NSString *startDateString = [RCTAppleHealthKit buildISO8601StringFromDate:startDate];
                                           NSString *endDateString = [RCTAppleHealthKit buildISO8601StringFromDate:endDate];

                                           NSDictionary *elem = @{
                                                   @"value" : @(value),
                                                   @"startDate" : startDateString,
                                                   @"endDate" : endDateString,
                                           };
                                           [data addObject:elem];
                                       }
                                   }];
        // is ascending by default
        if(asc == false) {
            [RCTAppleHealthKit reverseNSMutableArray:data];
        }

        if((lim > 0) && ([data count] > lim)) {
            NSArray* slicedArray = [data subarrayWithRange:NSMakeRange(0, lim)];
            NSError *err;
            completionHandler(slicedArray, err);
        } else {
            NSError *err;
            completionHandler(data, err);
        }
    };

    [self.healthStore executeQuery:query];
}

 - (void)fetchWorkoutForPredicate:(NSPredicate *)predicate
                        ascending:(BOOL)ascending
                            limit:(NSUInteger)limit
                       completion:(void (^)(NSArray *, NSError *))completion {

    void (^handlerBlock)(HKSampleQuery *query, NSArray *results, NSError *error);
    NSSortDescriptor *endDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:ascending];
    handlerBlock = ^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if(!results) {
            if(completion) {
                completion(nil, error);
            }
            return;
        }

        if(completion) {
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];
            NSDictionary *numberToWorkoutNameDictionary = [RCTAppleHealthKit getNumberToWorkoutNameDictionary];

            dispatch_async(dispatch_get_main_queue(), ^{
                for (HKWorkout * sample in results) {
                    double energy = [[sample totalEnergyBurned] doubleValueForUnit:[HKUnit kilocalorieUnit]];
                    double distance = [[sample totalDistance] doubleValueForUnit:[HKUnit mileUnit]];
                    NSNumber *activityNumber =  [NSNumber numberWithInt:(int)sample.workoutActivityType];

                    NSString *activityName = [numberToWorkoutNameDictionary objectForKey: activityNumber];

                    NSDictionary *device = [RCTAppleHealthKit serializeDevice:sample];
                    bool isFromWatch = [RCTAppleHealthKit validateFromWatch:sample];
                    bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:sample];
                    id sourceType = [RCTAppleHealthKit getSourceType:sample];
                    
                    NSDictionary *elem = @{
                        @"id": [[sample UUID] UUIDString],
                        @"sourceName" : [[[sample sourceRevision] source] name] ?: [NSNull null],
                        @"sourceMetaData" : [sample metadata] ?: [NSNull null],
                        @"sourceId" : [[[sample sourceRevision] source] bundleIdentifier] ?: [NSNull null],
                        @"activityName" : activityName,
                        @"calories" : @(energy),
                        @"distance" : @(distance),
                        @"startDate" : [RCTAppleHealthKit buildISO8601StringFromDate:sample.startDate],
                        @"endDate" : [RCTAppleHealthKit buildISO8601StringFromDate:sample.endDate],
                        @"isUserEntered": @(isUserEntered),
                        @"isFromWatch": @(isFromWatch),
                        @"sourceType": sourceType,
                        @"device": device,
                    };
                    [data addObject:elem];
                }
                completion(data, error);
            });

        }
    };

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:[HKObjectType workoutType] predicate:predicate limit:limit sortDescriptors:@[endDateSortDescriptor] resultsHandler:handlerBlock];

    [self.healthStore executeQuery:query];
}

/*!
    Set background observer for the given HealthKit sample type. This method should only be called by
    the native code and not injected by any Javascript code, as that might imply in unstable behavior

    @deprecated The setObserver() method has been deprecated in favor of initializeBackgroundObservers()

    @param sampleType The type of samples to add a listener for
    @param type A human readable description for the sample type
 */
- (void)setObserverForType:(HKSampleType *)sampleType
                      type:(NSString *)type __deprecated
{
    HKObserverQuery* query = [
        [HKObserverQuery alloc] initWithSampleType:sampleType
                                         predicate:nil
                                     updateHandler:^(HKObserverQuery* query,
                                                     HKObserverQueryCompletionHandler completionHandler,
                                                     NSError * _Nullable error) {
        NSLog(@"[HealthKit] New sample received from Apple HealthKit - %@", type);

        NSString *successEvent = [NSString stringWithFormat:@"healthKit:%@:sample", type];

        if (error) {
            completionHandler();

            NSLog(@"[HealthKit] An error happened when receiving a new sample - %@", error.localizedDescription);

            return;
        }

        [self sendEventWithName:successEvent body:@{}];

        completionHandler();

        NSLog(@"[HealthKit] New sample from Apple HealthKit processed - %@", type);
    }];


    [self.healthStore enableBackgroundDeliveryForType:sampleType
                                            frequency:HKUpdateFrequencyImmediate
                                       withCompletion:^(BOOL success, NSError * _Nullable error) {
        NSString *successEvent = [NSString stringWithFormat:@"healthKit:%@:enabled", type];

        if (error) {
            NSLog(@"[HealthKit] An error happened when setting up background observer - %@", error.localizedDescription);

            return;
        }

        [self.healthStore executeQuery:query];

        [self sendEventWithName:successEvent body:@{}];
    }];
}

/*!
    Set background observer for the given HealthKit sample type. This method should only be called by
    the native code and not injected by any Javascript code, as that might imply in unstable behavior

    @param sampleType The type of samples to add a listener for
    @param type A human readable description for the sample type
    @param bridge React Native bridge instance
 */
- (void)setObserverForType:(HKSampleType *)sampleType
                      type:(NSString *)type
                    bridge:(RCTBridge *)bridge
                    hasListeners:(bool)hasListeners
{
    HKObserverQuery* query = [
        [HKObserverQuery alloc] initWithSampleType:sampleType
                                         predicate:nil
                                     updateHandler:^(HKObserverQuery* query,
                                                     HKObserverQueryCompletionHandler completionHandler,
                                                     NSError * _Nullable error) {
        NSLog(@"[HealthKit] New sample received from Apple HealthKit - %@", type);

        NSString *successEvent = [NSString stringWithFormat:@"healthKit:%@:new", type];
        NSString *failureEvent = [NSString stringWithFormat:@"healthKit:%@:failure", type];

        if (error) {
            completionHandler();

            NSLog(@"[HealthKit] An error happened when receiving a new sample - %@", error.localizedDescription);
            if(self.hasListeners) {
                [self sendEventWithName:failureEvent body:@{}];
            }
            return;
        }
        if(self.hasListeners) {
            [self sendEventWithName:successEvent body:@{}];
        }
        completionHandler();

        NSLog(@"[HealthKit] New sample from Apple HealthKit processed - %@", type);
    }];


    [self.healthStore enableBackgroundDeliveryForType:sampleType
                                            frequency:HKUpdateFrequencyImmediate
                                       withCompletion:^(BOOL success, NSError * _Nullable error) {
        NSString *successEvent = [NSString stringWithFormat:@"healthKit:%@:setup:success", type];
        NSString *failureEvent = [NSString stringWithFormat:@"healthKit:%@:setup:failure", type];

        if (error) {
            NSLog(@"[HealthKit] An error happened when setting up background observer - %@", error.localizedDescription);
            if(self.hasListeners) {
                [self sendEventWithName:failureEvent body:@{}];
            }
            return;
        }

        [self.healthStore executeQuery:query];
        if(self.hasListeners) {
            [self sendEventWithName:successEvent body:@{}];
        }
        }];
}

- (void)fetchActivitySummary:(NSDate *)startDate
                     endDate:(NSDate *)endDate
                  completion:(void (^)(NSArray *, NSError *))completionHandler
API_AVAILABLE(ios(9.3))
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *startComponent = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitEra
                                                     fromDate:startDate];
    startComponent.calendar = calendar;
    NSDateComponents *endComponent = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitEra
                                                     fromDate:endDate];
    endComponent.calendar = calendar;
    NSPredicate *predicate = [HKQuery predicateForActivitySummariesBetweenStartDateComponents:startComponent endDateComponents:endComponent];
    
    HKActivitySummaryQuery *query = [[HKActivitySummaryQuery alloc] initWithPredicate:predicate
                                        resultsHandler:^(HKActivitySummaryQuery *query, NSArray *results, NSError *error) {
        
        if (error) {
            // Perform proper error handling here
            NSLog(@"*** An error occurred while fetching the summary: %@ ***",error.localizedDescription);
            completionHandler(nil, error);
            return;
        }
        
        NSMutableArray *data = [NSMutableArray arrayWithCapacity:1];

        dispatch_async(dispatch_get_main_queue(), ^{
            for (HKActivitySummary *summary in results) {
                int aebVal = [summary.activeEnergyBurned doubleValueForUnit:[HKUnit kilocalorieUnit]];
                int aebgVal = [summary.activeEnergyBurnedGoal doubleValueForUnit:[HKUnit kilocalorieUnit]];
                int aetVal = [summary.appleExerciseTime doubleValueForUnit:[HKUnit minuteUnit]];
                int aetgVal = [summary.appleExerciseTimeGoal doubleValueForUnit:[HKUnit minuteUnit]];
                int ashVal = [summary.appleStandHours doubleValueForUnit:[HKUnit countUnit]];
                int ashgVal = [summary.appleStandHoursGoal doubleValueForUnit:[HKUnit countUnit]];

                NSDictionary *elem = @{
                        @"activeEnergyBurned" : @(aebVal),
                        @"activeEnergyBurnedGoal" : @(aebgVal),
                        @"appleExerciseTime" : @(aetVal),
                        @"appleExerciseTimeGoal" : @(aetgVal),
                        @"appleStandHours" : @(ashVal),
                        @"appleStandHoursGoal" : @(ashgVal),
                };

                [data addObject:elem];
            }

            completionHandler(data, error);
        });
    }];

    [self.healthStore executeQuery:query];
    
}

/*@yulianto.kevin: adding anchored workouts routes*/

- (void)fetchWorkoutsHealthStore:(HKSampleType *)type
                      predicate:(NSPredicate *)predicate
                         anchor:(HKQueryAnchor *)anchor
                          limit:(NSUInteger)lim
                     completion:(void (^)(NSArray<HKWorkout *> *workouts, HKQueryAnchor * _Nullable newAnchor, NSError *error))completion {
    HKAnchoredObjectQuery *query = [[HKAnchoredObjectQuery alloc] initWithType:type
                                                                     predicate:predicate
                                                                        anchor:anchor
                                                                         limit:lim
                                                                resultsHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable samples, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error) {
        if (error && completion) {
            completion(nil, newAnchor, error);
            return;
        } else if (!samples){
            completion([NSArray array], newAnchor, nil);
            return;
        }
        
        completion(samples, newAnchor, nil);
    }];

    [self.healthStore executeQuery:query];
}

- (void)fetchWorkoutRouteHealthStore:(HKWorkout *)workoutSample
                          completion:(void (^)(NSArray<CLLocation *> *, NSError *))completion
{
    
    if (@available(iOS 11.0, *)) {
        NSPredicate *workoutPredicate = [HKQuery predicateForObjectsFromWorkout:workoutSample];
        HKAnchoredObjectQuery *query = [[HKAnchoredObjectQuery alloc]
                                        initWithType:[HKSeriesType workoutRouteType]
                                        predicate:workoutPredicate
                                        anchor:nil
                                        limit:HKObjectQueryNoLimit
                                        resultsHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable workoutRoutesSamples, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error) {
            
            if (error && completion) {
                completion(nil, error);
                return;
            }
            
            if (!workoutRoutesSamples || [workoutRoutesSamples count] <= 0) {
                completion([NSArray array], nil);
                return;
            }
            
            NSMutableArray *routeLocations = [NSMutableArray arrayWithCapacity:1];
            
            HKQuery *routeLocationQuery = nil;
            routeLocationQuery = [[HKWorkoutRouteQuery alloc]initWithRoute:workoutRoutesSamples.firstObject dataHandler:^(HKWorkoutRouteQuery * _Nonnull query, NSArray<CLLocation *> * _Nullable routeData, BOOL done, NSError * _Nullable error) {
                if (error) {
                    [self.healthStore stopQuery:routeLocationQuery];
                    if (completion) {
                        completion(nil, error);
                    }
                    return;
                }
                if (routeData != nil) {
                    [routeLocations addObjectsFromArray:routeData];
                } else {
                    [routeLocations addObjectsFromArray:[NSArray array]];
                }
                
                if (done) {
                    completion(routeLocations, nil);
                }
            }];
            
            if (routeLocationQuery != nil) {
                [self.healthStore executeQuery:routeLocationQuery];
            }
        }];
        
        [self.healthStore executeQuery:query];
    } else {
        // Fallback on earlier versions, unable to query the route locations
        completion([NSArray array], nil);
    }
};

- (void)fetchAllWorkoutLocations:(HKSampleType *)type
                       predicate:(NSPredicate *)predicate
                          anchor:(HKQueryAnchor *)anchor
                           limit:(NSUInteger)lim
                       ascending:(BOOL)ascending
            includeManuallyAdded:(BOOL)includeManuallyAdded
                       watchOnly:(BOOL)watchOnly
                      completion:(void (^)(NSDictionary *, NSError *))completion {
    
    [self fetchWorkoutsHealthStore:type
                 predicate:predicate
                    anchor:anchor
                     limit:lim
                completion:^(NSArray<HKWorkout *> *workouts, HKQueryAnchor * _Nullable newAnchor, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (!workouts) {
            completion(@{
                @"data": [NSArray array],
                @"anchor": [NSNull null]
            }, nil);
            return;
        }
        
        NSMutableArray<HKWorkout *> *validWorkouts = [NSMutableArray arrayWithCapacity:1];
        
        for (HKWorkout *workout in workouts) {
            bool isFromWatch = [RCTAppleHealthKit validateFromWatch:workout];
            bool isUserEntered = [RCTAppleHealthKit validateUserManualInput:workout];
            if (!includeManuallyAdded && isUserEntered) {
                continue;
            }
            
            if (watchOnly && !isFromWatch) {
                // if user wanted to get watchonly source data and the data is not from watch, then continue
                continue;
            }
            
            [validWorkouts addObject:workout];
        }
        
        if (validWorkouts.count == 0) {
            completion(@{
                @"data": [NSArray array],
                @"anchor": [NSNull null]
            }, nil);
            return;
        }
        
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:1];
        
        __block NSUInteger tally = 0;
                
        for (HKWorkout *workout in validWorkouts) {
            
            [self fetchWorkoutRouteHealthStore:workout
                completion:^(NSArray<CLLocation *> *locations, NSError *error) {
                tally += 1;
                if (error) {
                    if (tally == [validWorkouts count]) {
                        completion(@{
                            @"data": results,
                            @"anchor": newAnchor
                        }, nil);
                        return;
                    } else {
                        completion(nil, error);
                    }
                    return;
                }
                
                [results addObject:[RCTAppleHealthKit serializeWorkoutRouteLocations:workout locations:locations]];
                if (tally == [validWorkouts count]) {
                    completion(@{
                        @"data": results,
                        @"anchor": newAnchor
                    }, error);
                }
            }];
        }
        
    }];
};

- (void)fetchCalories:(HKUnit *)unit
                    period:(NSUInteger)period
                    predicate:(NSPredicate *)predicate
                    startDate:(NSDate *)startDate
                    endDate:(NSDate *)endDate
                    limit:(NSUInteger)lim
                    ascending:(BOOL)asc
                    completion:(void (^)(NSArray *, NSError *))completionHandler {
    
    HKQuantityType *activeEnergyType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    HKQuantityType *basalEnergyType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned];
    
    [self fetchCumulativeSumStatisticsCollection:basalEnergyType
        unit:unit
      period:period
    predicate:predicate
    startDate:startDate
     endDate:endDate
       limit:lim
    ascending:true
  completion:^(NSArray *basalResults, NSError *error) {
        
      if(basalResults){
          [self fetchCumulativeSumStatisticsCollection:activeEnergyType
                      unit:unit
                    period:period
                 predicate:predicate
                 startDate:startDate
                   endDate:endDate
                     limit:lim
                 ascending:true
                completion:^(NSArray *activeResults, NSError *error) {
                    if(activeResults){
                        NSMutableDictionary *dict = [NSMutableDictionary new];
                        for (id activeResult in activeResults) {
                            NSString *startDateStr =  [activeResult objectForKey:@"startDate"];
                            NSString *endDateStr =  [activeResult objectForKey:@"endDate"];
                            int calories = [[activeResult valueForKey:@"value"] intValue] + 0;
                            [dict setObject:@{
                                @"value" : @(calories), // to sum using human's manual way for active energy burned + basal energy burned
                                @"basal": @(0),
                                @"active": @([[activeResult valueForKey:@"value"] doubleValue]),
                                @"startDate" : startDateStr,
                                @"endDate" : endDateStr,
                            } forKey:startDateStr];
                        }
                        
                        for (id basalResult in basalResults) {
                            NSString *startDateStr = [basalResult objectForKey:@"startDate"];
                            NSDictionary *caloryDict = [dict objectForKey:startDateStr];
                            if (caloryDict != nil) {
                                id active = [caloryDict objectForKey:@"active"];
                                id basal = [basalResult valueForKey:@"value"];
                                NSString *startDateStr =  [basalResult objectForKey:@"startDate"];
                                NSString *endDateStr =  [basalResult objectForKey:@"endDate"];
                                int calories = [active intValue] + [basal intValue];
                                [dict setObject:@{
                                    @"value" : @(calories), // to sum using human's manual way for active energy burned + basal energy burned
                                    @"basal": @([basal doubleValue]),
                                    @"active": @([active doubleValue]),
                                    @"startDate" : startDateStr,
                                    @"endDate" : endDateStr,
                                } forKey:startDateStr];
                            } else {
                                id basal = [basalResult valueForKey:@"value"];
                                NSString *startDateStr =  [basalResult objectForKey:@"startDate"];
                                NSString *endDateStr =  [basalResult objectForKey:@"endDate"];
                                int calories = 0 + [basal intValue];
                                [dict setObject:@{
                                    @"value": @(calories), // to sum using human's manual way for active energy burned + basal energy burned
                                    @"basal": @([basal doubleValue]),
                                    @"active": @(0),
                                    @"startDate" : startDateStr,
                                    @"endDate" : endDateStr,
                                } forKey:startDateStr];
                            }
                        }
                        
                        NSArray *values = [dict allValues];
                        NSMutableArray *results = [(NSArray*)values mutableCopy];
                        if (asc == false) {
                            [RCTAppleHealthKit reverseNSMutableArray:results];
                        }
                        
                        completionHandler(results, nil);
                        return;
                    } else {
                        NSLog(@"error getting active energy burned samples: %@", error);
                        completionHandler(nil, error);
                        return;
                    }
          }];
      } else {
          NSLog(@"error getting basal energy burned samples: %@", error);
          completionHandler(nil, error);
      }
        
  }];
    
}

/*end @yulianto.kevin*/

@end
