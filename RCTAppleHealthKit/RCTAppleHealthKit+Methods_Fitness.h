//
//  RCTAppleHealthKit+Methods_Fitness.h
//  RCTAppleHealthKit
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit.h"

@interface RCTAppleHealthKit (Methods_Fitness)

- (void)fitness_getStepCountOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDailyStepSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;
- (void)fitness_saveSteps:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_initializeStepEventObserver:(NSDictionary *)input hasListeners:(bool)hasListeners callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDistanceWalkingRunningOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDailyDistanceWalkingRunningSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;
- (void)fitness_getDistanceSwimmingOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback API_AVAILABLE(ios(10.0));
- (void)fitness_getDailyDistanceSwimmingSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject API_AVAILABLE(ios(10.0));
- (void)fitness_getDistanceCyclingOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDailyDistanceCyclingSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;
- (void)fitness_getFlightsClimbedOnDay:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDailyFlightsClimbedSamples:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)fitness_getDailyDistanceDownhillSnowSportsSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject API_AVAILABLE(ios(11.2));
- (void)fitness_getDailyDistanceWheelchairSamples:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject API_AVAILABLE(ios(10.0));
- (void)fitness_setObserver:(NSDictionary *)input __deprecated;
- (void)fitness_registerObserver:(NSString *)type
                          bridge:(RCTBridge *)bridge
                    hasListeners:(bool)hasListeners;

@end
