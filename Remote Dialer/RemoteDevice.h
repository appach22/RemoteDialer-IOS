//
//  RemoteDevice.h
//  Remote Dialer
//
//  Created by Sergey Stasishin on 09.04.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEVICE_TYPE_NONE            0
#define DEVICE_TYPE_THIS            1
#define DEVICE_TYPE_LOCAL_NETWORK   2

@interface RemoteDevice : NSObject <NSCoding, NSCopying>
{
@public
    NSString * mName;
    int mType;
    NSString * mHost;
    int mPort;
    NSString * mModel;
    NSString * mUid;
}

- (id)initLocalWithName:(NSString*)deviceName andUid:(NSString*)uid;
- (id)initWithBroadcastInfo:(NSString*)infoFromPacket ip:(NSString*)deviceIP port:(int)devicePort;


@end
