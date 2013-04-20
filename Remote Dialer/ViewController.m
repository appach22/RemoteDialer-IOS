//
//  ViewController.m
//  Remote Dialer
//
//  Created by Sergey Stasishin on 30.03.13.
//  Copyright (c) 2013 Sergey Stasishin. All rights reserved.
//

#import "ViewController.h"
#import "AsyncSocket.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize devicesTable;
@synthesize tfNumber;
@synthesize devices;
@synthesize progress;
@synthesize progressTitle;
@synthesize context;

- (void)viewDidLoad
{
    [super viewDidLoad];
    devicesTable.numberField = tfNumber;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    tfNumber.borderStyle = UITextBorderStyleRoundedRect;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Table View Data Souce Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * devicesTableIdentifier = @"DevicesTable";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:devicesTableIdentifier];
    UIButton * deletebtn = nil;
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:devicesTableIdentifier];
        deletebtn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
        deletebtn.frame=CGRectMake(250, 10, 25, 25);
        [deletebtn setTitle:@"x" forState:UIControlStateNormal];
        //[deletebtn setImage:[UIImage imageNamed:@"log_delete_touch.png"] forState:UIControlStateNormal];
        [deletebtn addTarget:self action:@selector(removeDevice:) forControlEvents:UIControlEventTouchUpInside];
        deletebtn.hidden = YES;
        [cell addSubview:deletebtn];
    }
    NSUInteger row = [indexPath row];
    RemoteDevice * device = [self.devices objectAtIndex:row];
    cell.textLabel.text = device->mName;
    cell.detailTextLabel.text = device->mModel;
    if (device->mIsAvailable || device->mType == DEVICE_TYPE_THIS)
    {
        cell.textLabel.textColor = cell.textLabel.highlightedTextColor = [UIColor colorWithRed:0.3 green:1 blue:0.3 alpha:1];
        //cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    else
        cell.textLabel.textColor = cell.textLabel.highlightedTextColor = [UIColor colorWithRed:1 green:0.3 blue:0.3 alpha:1];
    // Reuse cell
    if (!deletebtn)
    {
        // Find button 
        NSArray * views = [cell subviews];
        for (int i = 0; i < views.count; ++i)
            if ([views[i] isKindOfClass:[UIButton class]])
            {
                deletebtn = (UIButton *)views[i];
                deletebtn.hidden = !([tableView indexPathForSelectedRow].row == row);
                break;
            }
    }
    // Assign proper tag
    if (deletebtn)
        deletebtn.tag = row + 1;
    return cell;
}

- (void)removeDevice:(id)sender
{
    NSInteger index = ((UIView *)sender).tag - 1;
    NSInteger nextIndex = 0;
    NSLog(@"delete %d", index);
    if ([self.devices count] == 1)
        nextIndex = -1;
    else if (index == [self.devices count] - 1)
        nextIndex = index - 1;
    else
        nextIndex = index;
    
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [devices removeDeviceAtIndex:index];
    [devicesTable deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
    if (nextIndex != -1)
    {
        for (int i = nextIndex; i < [devicesTable numberOfRowsInSection:0]; ++i)
        {
            indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            UITableViewCell *cell = [self.devicesTable cellForRowAtIndexPath:indexPath];
            [cell viewWithTag:i + 2].tag = i + 1;
        }
        indexPath = [NSIndexPath indexPathForRow:nextIndex inSection:0];
        [devicesTable selectRowAtIndexPath:indexPath animated:YES  scrollPosition:UITableViewScrollPositionBottom];
        [self selectRow:nextIndex];
    }
}

- (void)selectRow:(NSUInteger)row
{
    devices.mLastSelectedIndex = [[NSNumber alloc] initWithInt:row];
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    UITableViewCell *cell = [self.devicesTable cellForRowAtIndexPath:indexPath];
    [cell viewWithTag:row + 1].hidden = NO;
}

- (void)deselectRow:(NSUInteger)row
{
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    UITableViewCell *cell = [devicesTable cellForRowAtIndexPath:indexPath];
    [cell viewWithTag:row + 1].hidden = YES;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectRow: [indexPath row]];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self deselectRow: [indexPath row]];
}


- (IBAction)numberEditingFinished:(id)sender
{
    [sender resignFirstResponder];
}

- (IBAction)backgroundTap:(id)sender
{
    [tfNumber resignFirstResponder];
}

- (void)settingsChanged:(NSNotification *)notification
{
    NSUserDefaults * settings = [NSUserDefaults standardUserDefaults];
    NSLog(@"Settings changed: %@", [settings stringForKey:@"device_name"]);
    [self.devices updateThisDeviceName:[settings stringForKey:@"device_name"]];
}

- (IBAction)dial:(id)sender
{
    if (tfNumber.text.length < 3)
        return;
    NSIndexPath * selectedIndexPath = [[self devicesTable] indexPathForSelectedRow];
    RemoteDevice * selectedDevice = [[self devices] objectAtIndex:selectedIndexPath.row];
    if (selectedDevice->mType == DEVICE_TYPE_THIS)
    {
        NSURL *URL = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"tel://%@", tfNumber.text]];
        [[UIApplication sharedApplication] openURL:URL];
    }
    else
    {
        NSLog(@"Dialing on %@:%d", selectedDevice->mHost, selectedDevice->mPort);
        tcpDialSocket = [[AsyncSocket alloc] initWithDelegate:self];
        NSError *error = nil;
        if (![tcpDialSocket connectToHost:selectedDevice->mHost onPort:selectedDevice->mPort withTimeout:10 error:&error])
        {
            NSLog(@"Error connecting: %@", error);
        }
        [self showDialingAlert];
    }
}

- (IBAction)searchDevices:(id)sender
{
    if (context)
        [context getOthersInfo:context.broadcastAddress];
    [self checkDevicesAvailability];
}

- (void)checkDevicesAvailability
{
    currentDeviceCheckIndex = 0;
    if (currentDeviceCheckIndex < devices.count)
    {
        [progress startAnimating];
        progressTitle.text = NSLocalizedString(@"Devices lookup...", @"");
        if (![self checkDeviceAvailability:[devices objectAtIndex:currentDeviceCheckIndex]])
        {
            [devices markDeviceAtIndex:currentDeviceCheckIndex isAvailable:NO];
            [self checkNextDeviceAvailability];
        }
    }
    else
    {
        [progress stopAnimating];
        progressTitle.text = @"";
    }
}

- (void)checkNextDeviceAvailability
{
    currentDeviceCheckIndex++;
    if (currentDeviceCheckIndex < devices.count)
    {
        if (![self checkDeviceAvailability:[devices objectAtIndex:currentDeviceCheckIndex]])
        {
            [devices markDeviceAtIndex:currentDeviceCheckIndex isAvailable:NO];
            [self checkNextDeviceAvailability];
        }
    }
    else
    {
        [progress stopAnimating];
        progressTitle.text = @"";
    }
}

- (BOOL)checkDeviceAvailability:(RemoteDevice *)device
{
    if (device->mType == DEVICE_TYPE_THIS || device->mType == DEVICE_TYPE_NONE)
        return NO;
    tcpCheckSocket = [[AsyncSocket alloc] initWithDelegate:self];
    NSError *error = nil;
    if (![tcpCheckSocket connectToHost:device->mHost onPort:device->mPort withTimeout:10 error:&error])
    {
        NSLog(@"Error connecting: %@", error);
        return NO;
    }
    return YES;
}

- (void)showDialingAlert
{
    dialingAlert = [[UIAlertView alloc]initWithTitle:@"" message:NSLocalizedString(@"Dialing number...", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [dialingAlert show];
    
    if(dialingAlert != nil) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        indicator.center = CGPointMake(dialingAlert.bounds.size.width/2, dialingAlert.bounds.size.height - 45);
        [indicator startAnimating];
        [dialingAlert addSubview:indicator];
    }
}

- (void)dismissDialingAlert
{
    if (dialingAlert != nil)
    {
        [dialingAlert dismissWithClickedButtonIndex:0 animated:YES];
        dialingAlert = nil;
    }
}

#pragma mark Socket stuff

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSString *requestStr;
    if (sock == tcpDialSocket)
        requestStr = [NSString stringWithFormat:@"DialNumber %@\n", tfNumber.text];
    else if (sock == tcpCheckSocket)
        requestStr = @"CheckAvailability\n";
	NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
	
	[sock writeData:requestData withTimeout:-1 tag:0];
	[sock readDataToData:[AsyncSocket LFData] withTimeout:10 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        NSRange range = [msg rangeOfString:@"Accepted"];
        if (range.location == 0)
        {
            if (sock == tcpDialSocket)
                NSLog(@"Number dialed successfully");
            else if (sock == tcpCheckSocket)
            {
                [devices markDeviceAtIndex:currentDeviceCheckIndex isAvailable:YES];
                NSLog(@"%@ is available", [sock connectedHost]);
            }
        }
        else
        {
            NSLog(@"Device reported: %@", msg);
        }
    }
    [self dismissDialingAlert];
    [sock setDelegate:nil];
    [sock disconnect];
    if (sock == tcpCheckSocket)
        [self checkNextDeviceAvailability];
}

- (void)processConnectionFailureForSocket:(AsyncSocket *)sock
{
    [self dismissDialingAlert];
    [sock setDelegate:nil];
    [sock disconnect];
    if (sock == tcpCheckSocket)
    {
        [devices markDeviceAtIndex:currentDeviceCheckIndex isAvailable:NO];
        [self checkNextDeviceAvailability];
    }    
}

- (NSTimeInterval)onSocket:(AsyncSocket *)sock
  shouldTimeoutReadWithTag:(long)tag
                   elapsed:(NSTimeInterval)elapsed
                 bytesDone:(NSUInteger)length
{
    NSLog(@"Read timed out!");
    [self processConnectionFailureForSocket:sock];
    return 0;
}

- (NSTimeInterval)onSocket:(AsyncSocket *)sock
 shouldTimeoutWriteWithTag:(long)tag
                   elapsed:(NSTimeInterval)elapsed
                 bytesDone:(NSUInteger)length
{
    NSLog(@"Write timed out!");
    [self processConnectionFailureForSocket:sock];
    return 0;
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"onSocket:%p willDisconnectWithError:%@", sock, err);
    if (sock == tcpCheckSocket)
        [devices markDeviceAtIndex:currentDeviceCheckIndex isAvailable:NO];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"onSocketDidDisconnect:%p", sock);
    [self dismissDialingAlert];
    [sock setDelegate:nil];
    if (sock == tcpCheckSocket)
        [self checkNextDeviceAvailability];
}

@end





