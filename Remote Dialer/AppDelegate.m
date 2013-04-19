//
//  AppDelegate.m
//  Remote Dialer
//
//  Created by Sergey Stasishin on 30.03.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

#import "RemoteDevice.h"

#import <ifaddrs.h>
#import <sys/socket.h>
#include <arpa/inet.h>

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#define kDevicesFileName            @"devices.plist"
#define kSelectedDeviceFileName     @"selected_device.plist"

@implementation AppDelegate

@synthesize broadcastAddress;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    }
    [self loadDevicesList];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    self.viewController.context = self;
    self.viewController.devices.mParentTable = self.viewController.devicesTable;
    [self.viewController checkDevicesAvailability];
    
    NSUserDefaults * settings = [NSUserDefaults standardUserDefaults];
    NSString * thisDeviceName = [settings stringForKey:@"device_name"];
    NSLog(@"model %@", [[UIDevice currentDevice] model]);
    NSLog(@"localized model %@", [[UIDevice currentDevice] localizedModel]);
    NSLog(@"name %@", [[UIDevice currentDevice] name]);
    NSLog(@"system name %@", [[UIDevice currentDevice] systemName]);
    NSLog(@"system version %@", [[UIDevice currentDevice] systemVersion]);
    if (thisDeviceName.length == 0)
    {
        [settings setValue:[[UIDevice currentDevice] name] forKey:@"device_name"];
    }

    BOOL carrierAvailable = [self isCarrierAvailable];
    if (carrierAvailable)
        [self.viewController.devices addLocal];
    else
        [self.viewController.devices removeLocal];

    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:self.viewController.devices.mLastSelectedIndex.intValue inSection:0];
    [self.viewController.devicesTable selectRowAtIndexPath:indexPath animated:YES  scrollPosition:UITableViewScrollPositionBottom];
    [self.viewController selectRow:indexPath.row];
    

//==================================== TCP ===========================================
    tcpServerSocket = [[AsyncSocket alloc] initWithDelegate:self];
    // Advanced options - enable the socket to contine operations even during modal dialogs, and menu browsing
	[tcpServerSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];

    NSError *error = nil;
    if (![tcpServerSocket acceptOnPort:RDIALER_SERVICE_PORT error:&error])
    {
        NSLog(@"Error starting server (accept): %@", error);
        return YES;
    }
    
//==================================== UDP ===========================================
    broadcastServerSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    error = nil;
    if (![broadcastServerSocket bindToPort:RDIALER_SERVICE_PORT error:&error])
    {
        NSLog(@"Error starting server (bind): %@", error);
        return YES;
    }
    
    if(![broadcastServerSocket enableBroadcast:YES error:&error])
    {
        NSLog(@"Error setting broadcast: %@", error);
        return YES;
    }
    
    [broadcastServerSocket receiveWithTimeout:-1 tag:0];
    
    broadcastAddress = [self getBroadcastForIface:@"en0"];
    if (broadcastAddress)
    {
        [self getOthersInfo:broadcastAddress];
        
        if (carrierAvailable)
            [self sendMyInfo:broadcastAddress];
    }
    else
        NSLog(@"Unable to get broacast address for interface en0");

    NSLog(@"didFinishLaunchingWithOptions()");
    return YES;
}

- (BOOL)isCarrierAvailable
{
    CTTelephonyNetworkInfo * phoneInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier * phoneCarrier = [phoneInfo subscriberCellularProvider];
    NSLog(@"carrierName = %@", phoneCarrier.carrierName);
    NSLog(@"isoCountryCode = %@", phoneCarrier.isoCountryCode);
    NSLog(@"mobileCountryCode = %@", phoneCarrier.mobileCountryCode);
    NSLog(@"mobileNetworkCode = %@", phoneCarrier.mobileNetworkCode);
    NSLog(@"allowsVOIP = %d", phoneCarrier.allowsVOIP);
    if (phoneCarrier.isoCountryCode != nil)
        return YES;
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    NSLog(@"applicationWillResignActive()");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    //[self.viewController.devices writeToFile:[self devicesFilePath]];
    [self saveDevicesList];
    NSLog(@"applicationDidEnterBackground()");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground()");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive()");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"applicationWillTerminate()");
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock
     didReceiveData:(NSData *)data
            withTag:(long)tag
           fromHost:(NSString *)host
               port:(UInt16)port
{
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg)
	{
		NSLog(@"%@", [[NSString alloc] initWithFormat:@"Received broadcast: %@", msg]);
	}
    if ([msg isEqual:@"GetDeviceInfo\n"])
    {
        [self sendMyInfo:host];
        NSLog(@"My info sent");
    }
    else
    {
        NSRange range = [msg rangeOfString:@"DeviceInfo"];
        if (range.location == 0)
        {
            NSRange ipv6sign = [host rangeOfString:@"::ffff:"];
            if (ipv6sign.location == NSNotFound)
            {
                NSLog(@"Got info from %@:%d", host, port);
                RemoteDevice * device = [[RemoteDevice alloc] initWithBroadcastInfo:msg ip:host port:RDIALER_SERVICE_PORT];
                [self.viewController.devices addDevice:device];
            }
        }
    }

	[broadcastServerSocket receiveWithTimeout:-1 tag:0];
    
	return YES;
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    NSLog(@"Accepted new connection");
    connectionSocket = newSocket;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connected");
    [sock readDataToData:[AsyncSocket LFData] withTimeout:3.0 tag:0];
}


- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg)
	{
		NSLog(@"%@", [[NSString alloc] initWithFormat:@"Received command: %@", msg]);
        if ([msg isEqual:@"CheckAvailability\n"])
        {
            NSString *reply = @"Accepted\n";
            NSData *replyData = [reply dataUsingEncoding:NSUTF8StringEncoding];
            [sock writeData:replyData withTimeout:-1 tag:0];
        }
        else
        {
            NSRange range = [msg rangeOfString:@"DialNumber"];
            if (range.location == 0)
            {
                NSString *reply = @"Accepted\n";
                NSData *replyData = [reply dataUsingEncoding:NSUTF8StringEncoding];
                [sock writeData:replyData withTimeout:-1 tag:0];
                range = [msg rangeOfString:@" "];
                NSString * number = [msg substringFromIndex:range.location + 1];
                NSLog(@"%@", [[NSString alloc] initWithFormat:@"Number: %@", number]);
                NSURL *URL = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"tel://%@", number]];
                [[UIApplication sharedApplication] openURL:URL];
            }
        }
	}
}
     
- (NSString *) getBroadcastForIface:(NSString *)iface
{
    struct ifaddrs *ifa = NULL, *ifList;
    if (0 != getifaddrs(&ifList)) // should check for errors
    {
        NSLog(@"Error getting interfaces list!");
        return NULL;
    }
    for (ifa = ifList; ifa != NULL; ifa = ifa->ifa_next)
    {
        if(ifa->ifa_addr->sa_family == AF_INET)
        {
            if([[NSString stringWithUTF8String:ifa->ifa_name] isEqualToString:iface])
            {
                return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)ifa->ifa_broadaddr)->sin_addr)];
            }
        }
    }
    return NULL;
}

- (void)sendMyInfo:(NSString *)address
{
    if (!broadcastServerSocket)
        return;
    
    NSString * info = [[NSString alloc] initWithFormat:@"DeviceInfo|%@|%@|%@", self.viewController.devices.mThisDeviceName, self.viewController.devices.mThisDeviceUid, [[UIDevice currentDevice] localizedModel]];
    [broadcastServerSocket sendData:[info dataUsingEncoding:NSUTF8StringEncoding] toHost:address port:RDIALER_SERVICE_PORT withTimeout:-1 tag:0];
}

- (void)getOthersInfo:(NSString *)address
{
    NSString * request = @"GetDeviceInfo\n";
    [broadcastServerSocket sendData:[request dataUsingEncoding:NSUTF8StringEncoding] toHost:address port:RDIALER_SERVICE_PORT withTimeout:-1 tag:0];
}

- (NSString *)devicesFilePath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:kDevicesFileName];
}

- (NSString *)selectedDeviceFilePath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:kSelectedDeviceFileName];
}

- (void)loadDevicesList
{
    NSString * filePath = [self devicesFilePath];
    NSMutableOrderedSet * devices = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    self.viewController.devices = [[NSMutableOrderedSet alloc] initWithOrderedSet:devices];
    [self.viewController.devicesTable reloadData];
    filePath = [self selectedDeviceFilePath];
    self.viewController.devices.mLastSelectedIndex = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
}

- (void)saveDevicesList
{
    BOOL success = [NSKeyedArchiver archiveRootObject:self.viewController.devices toFile:[self devicesFilePath]];
    if (!success)
        NSLog(@"Archiving 1 error");
    success = [NSKeyedArchiver archiveRootObject:self.viewController.devices.mLastSelectedIndex toFile:[self selectedDeviceFilePath]];
    if (!success)
        NSLog(@"Archiving 2 error");
}

@end
