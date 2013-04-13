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
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:devicesTableIdentifier];
    }
    NSUInteger row = [indexPath row];
    RemoteDevice * device = [self.devices objectAtIndex:row];
    cell.textLabel.text = device->mName;
    cell.detailTextLabel.text = device->mModel;
    return cell;
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

- (void)showDialingAlert
{
    dialingAlert = [[UIAlertView alloc]initWithTitle:@"" message:@"Набираем номер..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [dialingAlert show];
    
    if(dialingAlert != nil) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        indicator.center = CGPointMake(dialingAlert.bounds.size.width/2, dialingAlert.bounds.size.height-45);
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
    if (tfNumber.text.length < 3)
        return;
	NSString *requestStr = [NSString stringWithFormat:@"DialNumber %@\n", tfNumber.text];
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
            NSLog(@"Number dialed successfully");
        }
        else
        {
            NSLog(@"Device reported: %@", msg);
        }
    }
    [self dismissDialingAlert];
    [sock setDelegate:nil];
    [sock disconnect];
}

- (NSTimeInterval)onSocket:(AsyncSocket *)sock
  shouldTimeoutReadWithTag:(long)tag
                   elapsed:(NSTimeInterval)elapsed
                 bytesDone:(NSUInteger)length
{
    NSLog(@"Read timed out!");
    [self dismissDialingAlert];
    [sock setDelegate:nil];
    [sock disconnect];
    return 0;
}

- (NSTimeInterval)onSocket:(AsyncSocket *)sock
 shouldTimeoutWriteWithTag:(long)tag
                   elapsed:(NSTimeInterval)elapsed
                 bytesDone:(NSUInteger)length
{
    NSLog(@"Write timed out!");
    [self dismissDialingAlert];
    [sock setDelegate:nil];
    [sock disconnect];
    return 0;
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"onSocket:%p willDisconnectWithError:%@", sock, err);
}
                  
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"onSocketDidDisconnect:%p", sock);
    [self dismissDialingAlert];
}

@end





