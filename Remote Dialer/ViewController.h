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

#define RDIALER_SERVICE_PORT 52836

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UIDevicesTable * devicesTable;
    UITextField * tfNumber;
    NSMutableOrderedSet * devices;
    AsyncSocket * tcpDialSocket;
    UIAlertView * dialingAlert;
}

@property (nonatomic, strong) IBOutlet UIDevicesTable * devicesTable;
@property (nonatomic, strong) IBOutlet UITextField * tfNumber;
@property (readwrite, nonatomic) NSMutableOrderedSet * devices;

- (IBAction)dial:(id)sender;
- (IBAction)numberEditingFinished:(id)sender;
- (IBAction)backgroundTap:(id)sender;

@end
