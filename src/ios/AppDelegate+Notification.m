//
//  AppDelegate+Notification.m
//
// Created by Olivier Louvignes on 2012-05-06.
//
// Copyright 2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import "AppDelegate+Notification.h"
#import "PushNotification.h"
#import <objc/runtime.h>

@implementation AppDelegate (Notification)

// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load {
    Method original, swizzled;
    original = class_getInstanceMethod(self, @selector(init));
    swizzled = class_getInstanceMethod(self, @selector(swizzled_init));
    method_exchangeImplementations(original, swizzled);
}

- (AppDelegate *)swizzled_init {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNotificationChecker:)
               name:@"UIApplicationDidFinishLaunchingNotification" object:nil];

  // This actually calls the original init method over in AppDelegate. Equivilent to calling super
  // on an overrided method, this is not recursive, although it appears that way. neat huh?
  return [self swizzled_init];
}

// This code will be called immediately after application:didFinishLaunchingWithOptions:. We need
// to process notifications in cold-start situations
- (void)createNotificationChecker:(NSNotification *)notification {
  if(notification) {
    NSDictionary* userInfo = [notification userInfo];
    if(userInfo) {
      PushNotification *pushHandler = [self.viewController getCommandInstance:@"PushNotification"];
      NSMutableDictionary* mutableUserInfo = [userInfo mutableCopy];
      [mutableUserInfo setValue:@"1" forKey:@"applicationLaunchNotification"];
      [mutableUserInfo setValue:@"0" forKey:@"applicationStateActive"];
      [pushHandler.pendingNotifications addObject:mutableUserInfo];
    }
  }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  PushNotification *pushHandler = [self.viewController getCommandInstance:@"PushNotification"];
  [pushHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  PushNotification *pushHandler = [self.viewController getCommandInstance:@"PushNotification"];
  [pushHandler didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  NSLog(@"didReceiveRemoteNotification:%@", userInfo);

  PushNotification* pushHandler = [self.viewController getCommandInstance:@"PushNotification"];
  NSMutableDictionary* mutableUserInfo = [userInfo mutableCopy];

  // Get application state for iOS4.x+ devices, otherwise assume active
  UIApplicationState appState = UIApplicationStateActive;
  if([application respondsToSelector:@selector(applicationState)]) {
    appState = application.applicationState;
  }

  if(appState == UIApplicationStateActive) {
    [mutableUserInfo setValue:@"1" forKey:@"applicationStateActive"];
    [pushHandler didReceiveRemoteNotification:mutableUserInfo];
  } else {
    [mutableUserInfo setValue:@"0" forKey:@"applicationStateActive"];
    [mutableUserInfo setValue:[NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]] forKey:@"timestamp"];
    [pushHandler.pendingNotifications addObject:mutableUserInfo];
  }
}

@end
