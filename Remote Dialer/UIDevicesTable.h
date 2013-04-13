//
//  UIDevicesTable.h
//  Remote Dialer
//
//  Created by Sergey Stasishin on 13.04.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevicesTable : UITableView
{
    UITextField * numberField;
}

@property (readwrite, nonatomic) UITextField * numberField;

@end
