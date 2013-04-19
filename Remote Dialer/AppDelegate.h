//
//  AppDelegate.h
//  Remote Dialer
//
//  Created by Sergey Stasishin on 30.03.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncUdpSocket.h"
#import "AsyncSocket.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    AsyncUdpSocket * broadcastServerSocket;
    NSString * broadcastAddress;
    AsyncSocket * tcpServerSocket;
    AsyncSocket * connectionSocket;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;
@property (readwrite, nonatomic) NSString * broadcastAddress;

- (void)getOthersInfo:(NSString *)address;

@end
