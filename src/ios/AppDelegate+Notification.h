//
//  AppDelegate+Notification.h
//
// Created by Olivier Louvignes on 2012-05-06.
//
// Copyright 2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import "AppDelegate.h"

@interface AppDelegate (Notification)
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)applicationDidBecomeActive:(UIApplication *)application;

@end
