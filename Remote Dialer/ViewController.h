//
//  ViewController.h
//  Remote Dialer
//
//  Created by Sergey Stasishin on 30.03.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteDialerDevices.h"
#import "AsyncSocket.h"
#import "UIDevicesTable.h"
#import "AppDelegate.h"

#define RDIALER_SERVICE_PORT 52836

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UIDevicesTable * devicesTable;
    UITextField * tfNumber;
    NSMutableOrderedSet * devices;
    AsyncSocket * tcpDialSocket;
    AsyncSocket * tcpCheckSocket;
    NSUInteger currentDeviceCheckIndex;
    UIAlertView * dialingAlert;
    UIActivityIndicatorView * progress;
    UILabel * progressTitle;
    AppDelegate * context;
}

@property (nonatomic, strong) IBOutlet UIDevicesTable * devicesTable;
@property (nonatomic, strong) IBOutlet UITextField * tfNumber;
@property (readwrite, nonatomic) NSMutableOrderedSet * devices;
@property (readwrite, nonatomic) AppDelegate * context;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * progress;
@property (nonatomic, strong) IBOutlet UILabel * progressTitle;

- (IBAction)dial:(id)sender;
- (IBAction)searchDevices:(id)sender;
- (IBAction)numberEditingFinished:(id)sender;
- (IBAction)backgroundTap:(id)sender;

- (void)selectRow:(NSUInteger)row;
- (void)deselectRow:(NSUInteger)row;

- (BOOL)checkDeviceAvailability:(RemoteDevice *)device;
- (void)checkDevicesAvailability;
- (void)checkNextDeviceAvailability;

@end
