//
//  UIDevicesTable.m
//  Remote Dialer
//
//  Created by Sergey Stasishin on 13.04.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import "UIDevicesTable.h"

@implementation UIDevicesTable

@synthesize numberField;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (numberField != nil)
        [numberField resignFirstResponder];
    [super touchesBegan:touches withEvent:event];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
