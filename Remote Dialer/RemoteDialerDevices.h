//
//  RemoteDialerDevices.h
//  Remote Dialer
//
//  Created by Sergey Stasishin on 10.04.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemoteDevice.h"

@interface NSMutableOrderedSet (RemoteDialerDevices)


@property (nonatomic, retain) NSString * mThisDeviceName;
@property (nonatomic, retain) NSString * mThisDeviceUid;
@property (nonatomic, retain) NSString * mDefaultDeviceName;
@property (nonatomic, retain) NSString * mDefaultDeviceUid;
@property (nonatomic, retain) UITableView * mParentTable;
@property (nonatomic, retain) NSNumber * mLastSelectedIndex;

- (void)updateThisDeviceName:(NSString *)newName;

- (void)updateDefaultDeviceNameAndUid:(NSString *)newName;

- (void)addDevice:(RemoteDevice *)device;

- (void)removeAllExceptLocal;

- (void)addLocal;

- (void)removeDeviceAtIndex:(NSUInteger)index;

- (void)removeLocal;

- (int)getDefaultDeviceIndex;

- (int)getLocalDeviceIndex;

- (void)reportNewDevices;

- (id)initWithContentsOfFile:(NSString *)fileName;

- (void)writeToFile:(NSString *)fileName;

- (void)markDeviceAtIndex:(NSUInteger)deviceIndex isAvailable:(BOOL)availability;

@end
