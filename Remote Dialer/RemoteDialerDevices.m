//
//  RemoteDialerDevices.m
//  Remote Dialer
//
//  Created by Sergey Stasishin on 10.04.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import "RemoteDialerDevices.h"
#import <objc/runtime.h>

@implementation NSMutableOrderedSet (RemoteDialerDevices)

- (void)updateThisDeviceName:(NSString *)newName
{
    for (int i = 0; i < [self count]; ++i)
    {
        RemoteDevice * device = (RemoteDevice *)[self objectAtIndex:i];
        if (device->mType == DEVICE_TYPE_THIS && [device->mName isEqualToString:self.mThisDeviceName])
        {
            self.mThisDeviceName = newName;
            device->mName = self.mThisDeviceName;
        }
    }
    
    [self reportNewDevices];
}


- (void)updateDefaultDeviceNameAndUid:(NSString *)newName
{
    NSArray * nameAndUid = [newName componentsSeparatedByString:@"|"];
    self.mDefaultDeviceName = nameAndUid[0];
    if ([nameAndUid count] > 1)
        self.mDefaultDeviceUid = [[NSString alloc] initWithString: nameAndUid[1]];
    else
        self.mDefaultDeviceUid = @"";
    [self reportNewDevices];
}

- (void)addDevice:(RemoteDevice *)device
{
    int index = [self indexOfObject:device];
    if (index != NSNotFound)
    {
        RemoteDevice * existingDevice = [self objectAtIndex:index];
        if (existingDevice->mType == DEVICE_TYPE_THIS && device->mType != DEVICE_TYPE_THIS)
            return;
        [self removeObject:existingDevice];
        [self insertObject:device atIndex:index];
    }
    else
        [self addObject:device];
    [self reportNewDevices];
}

- (void)removeAllExceptLocal
{
    RemoteDevice * thisDevice = nil;
    for (int i = 0; i < [self count]; ++i)
        if (((RemoteDevice *)[self objectAtIndex:i])->mType == DEVICE_TYPE_THIS)
        {
            thisDevice = [self objectAtIndex:i];
            break;
        }
    [self removeAllObjects];
    if (thisDevice)
        [self addObject:thisDevice];
    [self reportNewDevices];
}

- (void)addLocal
{
    NSUserDefaults * settings = [NSUserDefaults standardUserDefaults];
    self.mThisDeviceName = [settings stringForKey:@"device_name"];
    self.mThisDeviceUid = @"1234567890";
    [self addDevice:[[RemoteDevice alloc] initLocalWithName:self.mThisDeviceName andUid:self.mThisDeviceUid]];
}

- (void)removeLocal
{
    int localIndex = [self getLocalDeviceIndex];
    if (localIndex != NSNotFound)
    {
        [self removeObjectAtIndex:localIndex];
        [self reportNewDevices];
    }
}

- (int)getDefaultDeviceIndex
{
    return [self indexOfObject:[[RemoteDevice alloc] initLocalWithName:self.mDefaultDeviceName andUid:self.mDefaultDeviceUid]];
}

- (int)getLocalDeviceIndex
{
    return [self indexOfObject:[[RemoteDevice alloc] initLocalWithName:self.mThisDeviceName andUid:self.mThisDeviceUid]];
}

- (void)reportNewDevices
{
    for (int i = 0; i < [self count]; ++i)
    {
        RemoteDevice * device = [self objectAtIndex:i];
        if (device->mType == DEVICE_TYPE_THIS)
        {
            device->mModel = @"(Это устройство)";
            [self setObject:device atIndex:i];
        }
    }
    if (self.mParentTable)
        [self.mParentTable reloadData];
    return;
}

@dynamic mThisDeviceName;
static char const * const kMThisDeviceNameKey = "kMThisDeviceNameKey";
- (void)setMThisDeviceName:(NSString *)mThisDeviceName
{
    objc_setAssociatedObject(self, kMThisDeviceNameKey, mThisDeviceName, OBJC_ASSOCIATION_ASSIGN);
}
- (NSString *)mThisDeviceName
{
    return objc_getAssociatedObject(self, kMThisDeviceNameKey);
}

@dynamic mThisDeviceUid;
static char const * const kMThisDeviceUidKey = "kMThisDeviceUidKey";
- (void)setMThisDeviceUid:(NSString *)mThisDeviceUid
{
    objc_setAssociatedObject(self, kMThisDeviceUidKey, mThisDeviceUid, OBJC_ASSOCIATION_ASSIGN);
}
- (NSString *)mThisDeviceUid
{
    return objc_getAssociatedObject(self, kMThisDeviceUidKey);
}

@dynamic mDefaultDeviceName;
static char const * const kMDefaultDeviceNameKey = "kMDefaultDeviceNameKey";
- (void)setMDefaultDeviceName:(NSString *)mDefaultDeviceName
{
    objc_setAssociatedObject(self, kMDefaultDeviceNameKey, mDefaultDeviceName, OBJC_ASSOCIATION_ASSIGN);
}
- (NSString *)mDefaultDeviceName
{
    return objc_getAssociatedObject(self, kMDefaultDeviceNameKey);
}

@dynamic mDefaultDeviceUid;
static char const * const kMDefaultDeviceUidKey = "kMDefaultDeviceUidKey";
- (void)setMDefaultDeviceUid:(NSString *)mDefaultDeviceUid
{
    objc_setAssociatedObject(self, kMDefaultDeviceUidKey, mDefaultDeviceUid, OBJC_ASSOCIATION_ASSIGN);
}
- (NSString *)mDefaultDeviceUid
{
    return objc_getAssociatedObject(self, kMDefaultDeviceUidKey);
}

@dynamic mParentTable;
static char const * const kMParentTable = "kMParentTable";
- (void)setMParentTable:(UITableView *)mParentTable
{
    objc_setAssociatedObject(self, kMParentTable, mParentTable, OBJC_ASSOCIATION_ASSIGN);
}
- (UITableView *)mParentTable
{
    return objc_getAssociatedObject(self, kMParentTable);
}

@end
