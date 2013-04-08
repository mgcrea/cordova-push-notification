//
//  PushNotification.m
//
// Created by Olivier Louvignes on 2012-05-06.
// Inspired by Urban Airship Inc orphaned PushNotification phonegap plugin.
//
// Copyright 2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import "PushNotification.h"
//#import <Cordova/JSONKit.h>
#import <Cordova/CDVDebug.h>
#import "OpenUDID.h"

@implementation PushNotification

@synthesize callbackIds = _callbackIds;
@synthesize pendingNotifications = _pendingNotifications;

- (NSMutableDictionary*)callbackIds {
	if(_callbackIds == nil) {
		_callbackIds = [[NSMutableDictionary alloc] init];
	}
	return _callbackIds;
}
- (NSMutableArray*)pendingNotifications {
	if(_pendingNotifications == nil) {
		_pendingNotifications = [[NSMutableArray alloc] init];
	}
	return _pendingNotifications;
}

- (void)registerDevice:(CDVInvokedUrlCommand *)command {
	DLog(@"registerDevice:%@", command);

	// The first argument in the arguments parameter is the callbackID.
	[self.callbackIds setValue:command.callbackId forKey:@"registerDevice"];
	NSDictionary *options = [command.arguments objectAtIndex:0];

	UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeNone;
	if ([options objectForKey:@"badge"]) {
		notificationTypes |= UIRemoteNotificationTypeBadge;
	}
	if ([options objectForKey:@"sound"]) {
		notificationTypes |= UIRemoteNotificationTypeSound;
	}
	if ([options objectForKey:@"alert"]) {
		notificationTypes |= UIRemoteNotificationTypeAlert;
	}

	if (notificationTypes == UIRemoteNotificationTypeNone)
		NSLog(@"PushNotification.registerDevice: Push notification type is set to none");

	//[[UIApplication sharedApplication] unregisterForRemoteNotifications];
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];

}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	DLog(@"didRegisterForRemoteNotificationsWithDeviceToken:%@", deviceToken);

	NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
						stringByReplacingOccurrencesOfString:@">" withString:@""]
					   stringByReplacingOccurrencesOfString: @" " withString: @""];

    NSMutableDictionary *results = [PushNotification getRemoteNotificationStatus];
    [results setValue:token forKey:@"deviceToken"];

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
	[self writeJavascript:[pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"registerDevice"]]];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
	DLog(@"didFailToRegisterForRemoteNotificationsWithError:%@", error);

	NSMutableDictionary *results = [NSMutableDictionary dictionary];
	[results setValue:[NSString stringWithFormat:@"%@", error] forKey:@"error"];

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:results];
	[self writeJavascript:[pluginResult toErrorCallbackString:[self.callbackIds valueForKey:@"registerDevice"]]];
}

- (void)didReceiveRemoteNotification:(NSDictionary*)userInfo {
	DLog(@"didReceiveRemoteNotification:%@", userInfo);
    
    // Converting Dict to NSString in JSON format using NSJSONSerialization as per Cordova 2.4.0
    NSError* error = nil;
    NSString *jsStatement = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error: &error];
    if (error != nil){
        jsStatement = [NSString stringWithFormat:@"window.plugins.pushNotification.notificationCallback({error: %@});",[error localizedDescription]];
    }else{
        jsStatement = [NSString stringWithFormat:@"window.plugins.pushNotification.notificationCallback(%@);", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    }

	[self writeJavascript:jsStatement];
}

- (void)getPendingNotifications:(CDVInvokedUrlCommand *)command {
	DLog(@"getPendingNotifications:%@", command);

	// The first argument in the arguments parameter is the callbackID.
	[self.callbackIds setValue:command.callbackId forKey:@"getPendingNotifications"];
	//NSDictionary *options = [command.arguments objectAtIndex:0];

	NSMutableDictionary *results = [NSMutableDictionary dictionary];
	[results setValue:self.pendingNotifications forKey:@"notifications"];

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
	[self writeJavascript:[pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"getPendingNotifications"]]];

	[self.pendingNotifications removeAllObjects];
}

+ (NSMutableDictionary*)getRemoteNotificationStatus {

    NSMutableDictionary *results = [NSMutableDictionary dictionary];

    NSUInteger type = 0;
    // Set the defaults to disabled unless we find otherwise...
    NSString *pushBadge = @"0";
    NSString *pushAlert = @"0";
    NSString *pushSound = @"0";

#if !TARGET_IPHONE_SIMULATOR

    // Check what Notifications the user has turned on.  We registered for all three, but they may have manually disabled some or all of them.
    type = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];

    // Check what Registered Types are turned on. This is a bit tricky since if two are enabled, and one is off, it will return a number 2... not telling you which
    // one is actually disabled. So we are literally checking to see if rnTypes matches what is turned on, instead of by number. The "tricky" part is that the
    // single notification types will only match if they are the ONLY one enabled.  Likewise, when we are checking for a pair of notifications, it will only be
    // true if those two notifications are on.  This is why the code is written this way
    if(type == UIRemoteNotificationTypeBadge){
        pushBadge = @"1";
    }
    else if(type == UIRemoteNotificationTypeAlert) {
        pushAlert = @"1";
    }
    else if(type == UIRemoteNotificationTypeSound) {
        pushSound = @"1";
    }
    else if(type == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)) {
        pushBadge = @"1";
        pushAlert = @"1";
    }
    else if(type == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)) {
        pushBadge = @"1";
        pushSound = @"1";
    }
    else if(type == ( UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)) {
        pushAlert = @"1";
        pushSound = @"1";
    }
    else if(type == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)) {
        pushBadge = @"1";
        pushAlert = @"1";
        pushSound = @"1";
    }

#endif

    // Affect results
    [results setValue:[NSString stringWithFormat:@"%d", type] forKey:@"type"];
	[results setValue:[NSString stringWithFormat:@"%d", type != UIRemoteNotificationTypeNone] forKey:@"enabled"];
    [results setValue:pushBadge forKey:@"pushBadge"];
    [results setValue:pushAlert forKey:@"pushAlert"];
    [results setValue:pushSound forKey:@"pushSound"];

    return results;

}

- (void)getRemoteNotificationStatus:(CDVInvokedUrlCommand *)command {
	DLog(@"getRemoteNotificationStatus:%@", command);

	// The first argument in the arguments parameter is the callbackID.
	[self.callbackIds setValue:command.callbackId forKey:@"getRemoteNotificationStatus"];
	//NSDictionary *options = [command.arguments objectAtIndex:0];

	NSMutableDictionary *results = [PushNotification getRemoteNotificationStatus];

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
	[self writeJavascript:[pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"getRemoteNotificationStatus"]]];
}

- (void)getApplicationIconBadgeNumber:(CDVInvokedUrlCommand *)command {
    DLog(@"getApplicationIconBadgeNumber:%@", command);
    
    [self.callbackIds setValue:command.callbackId forKey:@"getApplicationIconBadgeNumber"];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[UIApplication sharedApplication].applicationIconBadgeNumber];

    
    [self writeJavascript:[pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"getApplicationIconBadgeNumber"]]];
	
}

- (void)setApplicationIconBadgeNumber:(CDVInvokedUrlCommand *)command {
	DLog(@"setApplicationIconBadgeNumber:%@", command);

	// The first argument in the arguments parameter is the callbackID.
	[self.callbackIds setValue:command.callbackId forKey:@"setApplicationIconBadgeNumber"];
	NSDictionary *options = [command.arguments objectAtIndex:0];

    int badge = [[options objectForKey:@"badge"] intValue] ?: 0;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];

    NSMutableDictionary *results = [NSMutableDictionary dictionary];
	[results setValue:[NSNumber numberWithInt:badge] forKey:@"badge"];
    [results setValue:[NSNumber numberWithInt:1] forKey:@"success"];

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:results];
	[self writeJavascript:[pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"setApplicationIconBadgeNumber"]]];
}

- (void)cancelAllLocalNotifications:(CDVInvokedUrlCommand *)command {
	DLog(@"cancelAllLocalNotifications:%@", command);

	// The first argument in the arguments parameter is the callbackID.
	[self.callbackIds setValue:command.callbackId forKey:@"cancelAllLocalNotifications"];
	//NSDictionary *options = [command.arguments objectAtIndex:0];

	[[UIApplication sharedApplication] cancelAllLocalNotifications];

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self writeJavascript:[pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"cancelAllLocalNotifications"]]];
}

- (void)getDeviceUniqueIdentifier:(CDVInvokedUrlCommand *)command {
	DLog(@"getDeviceUniqueIdentifier:%@", command);

	// The first argument in the arguments parameter is the callbackID.
	[self.callbackIds setValue:command.callbackId forKey:@"getDeviceUniqueIdentifier"];
	//NSDictionary *options = [command.arguments objectAtIndex:0];

    NSString* uuid = nil;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        // IOS 6 new Unique Identifier implementation
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        // Before iOS6 you shoud use a custom implementation for uuid
        // Here I use OpenUDID (you have to import it into your project)
        // https://github.com/ylechelle/OpenUDID
        uuid = [OpenUDID value];
        
    }

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:uuid];
	[self writeJavascript:[pluginResult toSuccessCallbackString:[self.callbackIds valueForKey:@"getDeviceUniqueIdentifier"]]];
}

@end
