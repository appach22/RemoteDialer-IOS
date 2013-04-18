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
    RemoteDevice * selectedDevice = [self objectAtIndex:self.mLastSelectedIndex.intValue];
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
    self.mLastSelectedIndex = [[NSNumber alloc] initWithInt:[self indexOfObject:selectedDevice]];
    [self reportNewDevices];
}

- (void)removeAllExceptLocal
{
    RemoteDevice * selectedDevice = [self objectAtIndex:self.mLastSelectedIndex.intValue];
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
    self.mLastSelectedIndex = [[NSNumber alloc] initWithInt:[self indexOfObject:selectedDevice]];
    [self reportNewDevices];
}

- (void)addLocal
{
    NSUserDefaults * settings = [NSUserDefaults standardUserDefaults];
    self.mThisDeviceName = [settings stringForKey:@"device_name"];
    self.mThisDeviceUid = @"1234567890";
    [self addDevice:[[RemoteDevice alloc] initLocalWithName:self.mThisDeviceName andUid:self.mThisDeviceUid]];
}

- (void)removeDeviceAtIndex:(NSUInteger)index
{
    [self removeObjectAtIndex:index];
    //[self reportNewDevices];
}

- (void)removeLocal
{
    RemoteDevice * selectedDevice = [self objectAtIndex:self.mLastSelectedIndex.intValue];
    int localIndex = [self getLocalDeviceIndex];
    if (localIndex != NSNotFound)
    {
        [self removeObjectAtIndex:localIndex];
        self.mLastSelectedIndex = [[NSNumber alloc] initWithInt:[self indexOfObject:selectedDevice]];
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

- (void)markDeviceAtIndex:(NSUInteger)deviceIndex isAvailable:(BOOL)availability
{
    ((RemoteDevice *)[self objectAtIndex:deviceIndex])->mIsAvailable = availability;
    [self reportNewDevices];
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
    if (self.mLastSelectedIndex.intValue != NSNotFound)
    {
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:self.mLastSelectedIndex.intValue inSection:0];
        [self.mParentTable selectRowAtIndexPath:indexPath animated:YES  scrollPosition:UITableViewScrollPositionBottom];
    }
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

@dynamic mLastSelectedIndex;
static char const * const kMLastSelectedIndex = "kMLastSelectedIndex";
- (void)setMLastSelectedIndex:(NSNumber *)mLastSelectedIndex
{
    objc_setAssociatedObject(self, kMLastSelectedIndex, mLastSelectedIndex, OBJC_ASSOCIATION_ASSIGN);
}
- (NSNumber *)mLastSelectedIndex
{
    return objc_getAssociatedObject(self, kMLastSelectedIndex);
}

@end
