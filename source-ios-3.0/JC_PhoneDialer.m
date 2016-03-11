/*
 *	Copyright 2013 Jake Chasan
 *
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without modification, are
 *	permitted provided that the following conditions are met:
 *
 *	Redistributions of source code must retain the above copyright notice which includes the
 *	name(s) of the copyright holders. It must also retain this list of conditions and the
 *	following disclaimer.
 *
 *	Redistributions in binary form must reproduce the above copyright notice, this list
 *	of conditions and the following disclaimer in the documentation and/or other materials
 *	provided with the distribution.
 *
 *	Neither the name of David Book, or buzztouch.com nor the names of its contributors
 *	may be used to endorse or promote products derived from this software without specific
 *	prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 *	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 *	OF SUCH DAMAGE.
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JSON.h"
#import "BT_application.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_appDelegate.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "JC_PhoneDialer.h"

#import "BT_item.h"
#import "BT_fileManager.h"
#import "BT_color.h"
#import "BT_downloader.h"
#import "BT_debugger.h"

@implementation JC_PhoneDialer

//viewDidLoad
-(void)viewDidLoad {
    
	[BT_debugger showIt:self theMessage:@"viewDidLoad"];
	[super viewDidLoad];
    
    
    //This will be the nav bar color after the Alert is launched
    [self configureNavBar];
    [self configureBackground];
}

//view will appear
-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[BT_debugger showIt:self theMessage:@"viewWillAppear"];
	
	//flag this as the current screen
	BT_appDelegate *appDelegate = (BT_appDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.rootApp.currentScreenData = self.screenData;
	
	//setup navigation bar and background
    [self configureNavBar];
    [self configureBackground];

    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://111-111-1111"]])
    {
        self.phoneNumber = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"phoneNumber" defaultValue:@""];
        
        NSString *callType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"callType" defaultValue:@"simple"];
        if([callType isEqualToString:@"advanced"])
        {
            [self launchDialerAlert];
        }
        else
        {
            [self placeCallWithFollow];
        }
    }
    else
    {
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"This device cannot make phone calls"]];
        [self incompatibleDevice];
    }
}

//launch dialer
-(void)launchDialerAlert{
	[BT_debugger showIt:self theMessage:@"Launch the Dialer"];

    NSString *title = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"promptTitle" defaultValue:@"Place Call"];
    NSString *message = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"promptMessage" defaultValue:@""];
    NSString *callButtonTitle = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"callButtonTitle" defaultValue:@"Call"];
    NSString *cancelButtonTitle = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"cancelButtonTitle" defaultValue:@"Cancel"];

    
    NSString *alertOrActionSheet = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"alertOrActionSheet" defaultValue:@"alert"];

    if([self.phoneNumber isEqualToString:@""])
    {
        [BT_debugger showIt:self message:@"The phone number was not configured properly"];
        [self phoneNumberProblem];
    }
    else
    {
        if([alertOrActionSheet isEqualToString:@"alert"])
        {
            UIAlertView *dialerAlert = [[UIAlertView alloc] initWithTitle:title
                                                                  message:message
                                                                 delegate:self
                                                        cancelButtonTitle:cancelButtonTitle
                                                        otherButtonTitles:callButtonTitle, nil];
            [dialerAlert show];
        }
        else
        {
            UIActionSheet *dialerActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                           delegate:self
                                                                  cancelButtonTitle:cancelButtonTitle
                                                             destructiveButtonTitle:nil
                                                                  otherButtonTitles:callButtonTitle, nil];
            
            //Launching the Action Sheet
            BT_appDelegate *appDelegate = (BT_appDelegate *)[[UIApplication sharedApplication] delegate];
            BT_navController *theNavController = [appDelegate getNavigationController];
            //Change Launch View for Tabbed Apps
            if([appDelegate.rootApp.tabs count] > 0){
                [dialerActionSheet showFromTabBar:[appDelegate.rootApp.rootTabBarController tabBar]];
            }else{
                [dialerActionSheet showInView:[theNavController view]];
            }
        }
    }
}

//supporting methods
-(void)incompatibleDevice
{
    UIAlertView *incompatibleDevice = [[UIAlertView alloc] initWithTitle:@"Cannot Place Call"
                                                                 message:@"This device is not capable of placing phone calls." delegate:self
                                                       cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [incompatibleDevice show];
}

-(void)phoneNumberProblem
{
    UIAlertView *phoneNumberProblem = [[UIAlertView alloc] initWithTitle:@"Problem with Phone Number"
                                                                 message:@"An error has occured because the phone number was invalid."
                                                                delegate:self
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
    [phoneNumberProblem show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    NSString *callButtonTitle = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"callButtonTitle" defaultValue:@"Call"];

    if([buttonTitle isEqualToString:callButtonTitle])
    {
        [BT_debugger showIt:self message:@"Placing Call from Alert"];
        [self placeCallNoFollow];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *callButtonTitle = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"callButtonTitle" defaultValue:@"Call"];
    
    if([buttonTitle isEqualToString:callButtonTitle])
    {
        [BT_debugger showIt:self message:@"Placing Call from Action Sheet"];
        [self placeCallNoFollow];
    }
}

-(void)placeCallWithFollow
{
    [BT_debugger showIt:self message:@"Placing Phone Call With Follow"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@", self.phoneNumber]]];
}

-(void)placeCallNoFollow
{
    [BT_debugger showIt:self message:@"Placing Phone Call Without Follow"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", self.phoneNumber]]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.navigationController popViewControllerAnimated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

@end

