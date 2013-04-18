//
//  RemoteDevice.m
//  Remote Dialer
//
//  Created by Sergey Stasishin on 09.04.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import "RemoteDevice.h"

#define kNameKey    @"name"
#define kUidKey     @"uid"
#define kTypeKey    @"type"
#define kHostKey    @"host"
#define kPortKey    @"port"
#define kModelKey   @"model"

@implementation RemoteDevice

- (BOOL)isEqual:(id)anObject
{
    if (anObject == self)
        return YES;
    if (anObject == nil)
        return NO;
    if (![mUid isEqualToString:@""] && ![((RemoteDevice*)anObject)->mUid isEqualToString:@""])
        return ([mUid caseInsensitiveCompare:((RemoteDevice*)anObject)->mUid] == NSOrderedSame);
    else
        return ([mName caseInsensitiveCompare:((RemoteDevice*)anObject)->mName] == NSOrderedSame);
    
    return NO;
}

- (NSUInteger)hash
{
    if (![mUid isEqualToString:@""])
        return [mUid hash];
    else
        return [mName hash];
}

- (id)initLocalWithName:(NSString*)deviceName andUid:(NSString*)uid
{
    self = [super init];
    if (self)
    {
        mName = [[NSString alloc] initWithString:deviceName];
        mUid =  [[NSString alloc] initWithString:uid];
        mType = DEVICE_TYPE_THIS;
        mModel = [[NSString alloc] init];
        mHost = [[NSString alloc] init];
        mPort = 0;
        mIsAvailable = YES;
    }

    return self;
}

- (id)initWithBroadcastInfo:(NSString*)infoFromPacket ip:(NSString*)deviceIP port:(int)devicePort
{
    self = [super init];
    if (self)
    {
        NSArray * infos = [[NSArray alloc] initWithArray:[infoFromPacket componentsSeparatedByString:@"|"]];
        mName = [[NSString alloc] initWithString:[infos objectAtIndex:1]];
        mUid =  [[NSString alloc] initWithString:infos[2]];
        mType = DEVICE_TYPE_LOCAL_NETWORK;
        mModel = [[NSString alloc] initWithString:infos[3]];
        mHost = [[NSString alloc] initWithString:deviceIP];
        mPort = devicePort;
        mIsAvailable = YES;
    }
    
    return self;
}

- (NSString *)description
{
    return mName;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        NSLog(@"Decode");
        mName =  [aDecoder decodeObjectForKey:kNameKey];
        mUid  =  [aDecoder decodeObjectForKey:kUidKey];
        mType =  [aDecoder decodeIntForKey:   kTypeKey];
        mHost =  [aDecoder decodeObjectForKey:kHostKey];
        mPort =  [aDecoder decodeIntForKey:   kPortKey];
        mModel = [aDecoder decodeObjectForKey:kModelKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSLog(@"Encode");
    [aCoder encodeObject:mName  forKey:kNameKey];
    [aCoder encodeObject:mUid   forKey:kUidKey];
    [aCoder encodeInt:   mType  forKey:kTypeKey];
    [aCoder encodeObject:mHost  forKey:kHostKey];
    [aCoder encodeInt:   mPort  forKey:kPortKey];
    [aCoder encodeObject:mModel forKey:kModelKey];
}

- (id)copyWithZone:(NSZone *)zone
{
    NSLog(@"Copy");
    RemoteDevice * deviceCopy = [[[self class] allocWithZone:zone] init];
    deviceCopy->mName = [mName copyWithZone:zone];
    deviceCopy->mUid = [mUid copyWithZone:zone];
    deviceCopy->mType = mType;
    deviceCopy->mHost = [mHost copyWithZone:zone];
    deviceCopy->mPort = mPort;
    deviceCopy->mModel = [mModel copyWithZone:zone];
    return deviceCopy;
}

@end
