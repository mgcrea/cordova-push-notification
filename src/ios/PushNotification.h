//
//  PushNotification.h
//
// Created by Olivier Louvignes on 2012-05-06.
// Inspired by Urban Airship Inc orphaned PushNotification phonegap plugin.
//
// Copyright 2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface PushNotification : CDVPlugin {

	NSMutableDictionary* callbackIds;
	NSMutableArray* pendingNotifications;

}

@property (nonatomic, retain) NSMutableDictionary* callbackIds;
@property (nonatomic, retain) NSMutableArray* pendingNotifications;

- (void)registerDevice:(CDVInvokedUrlCommand *)command;
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;
- (void)didReceiveRemoteNotification:(NSDictionary*)userInfo;
- (void)getPendingNotifications:(CDVInvokedUrlCommand *)command;
+ (NSMutableDictionary*)getRemoteNotificationStatus;
- (void)getRemoteNotificationStatus:(CDVInvokedUrlCommand *)command;
- (void)getApplicationIconBadgeNumber:(CDVInvokedUrlCommand *)command;
- (void)setApplicationIconBadgeNumber:(CDVInvokedUrlCommand *)command;
- (void)cancelAllLocalNotifications:(CDVInvokedUrlCommand *)command;
- (void)getDeviceUniqueIdentifier:(CDVInvokedUrlCommand *)command;

@end
