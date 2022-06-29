//
//  RCTAppleHealthKit+Methods_Workout.h
//  RCTAppleHealthKit
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit.h"

@interface RCTAppleHealthKit (Methods_Workout)

/*@yulianto.kevin: adding anchored workouts routes*/

- (void)workout_loadAllWorkoutLocations:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject API_AVAILABLE(ios(11));

/*end @yulianto.kevin*/
- (void)workout_getAnchoredQuery:(NSDictionary *)input resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;
- (void)workout_save: (NSDictionary *)input callback: (RCTResponseSenderBlock)callback;

@end

