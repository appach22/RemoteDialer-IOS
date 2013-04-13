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

@property (nonatomic, assign) NSString * mThisDeviceName;
@property (nonatomic, readwrite) NSString * mThisDeviceUid;
@property (nonatomic, readwrite) NSString * mDefaultDeviceName;
@property (nonatomic, readwrite) NSString * mDefaultDeviceUid;
@property (nonatomic, readwrite) UITableView * mParentTable;

- (void)updateThisDeviceName:(NSString *)newName;

- (void)updateDefaultDeviceNameAndUid:(NSString *)newName;

- (void)addDevice:(RemoteDevice *)device;

- (void)removeAllExceptLocal;

- (void)addLocal;

- (void)removeLocal;

- (int)getDefaultDeviceIndex;

- (int)getLocalDeviceIndex;

- (void)reportNewDevices;

- (id)initWithContentsOfFile:(NSString *)fileName;

- (void)writeToFile:(NSString *)fileName;

@end
