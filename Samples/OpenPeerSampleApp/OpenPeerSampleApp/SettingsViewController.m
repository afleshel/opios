/*
 
 Copyright (c) 2013, SMB Phone Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

#import "SettingsViewController.h"
#import "LoggerSettingsViewController.h"
#import "Settings.h"
#import "AppConsts.h"
#import "InfoViewController.h"
#import "LoginManager.h"
#import <OpenPeerSDK/HOPMediaEngine.h>

typedef enum
{
    SETTINGS_INFO_SECTION,
    SETTINGS_MEDIA_SECTION,
    SETTINGS_LOGGER_SECTION,
    SETTINGS_RESET_QR_SETTINGS_SECTION,
    SETTINGS_LOGOUT_SECTION,
    SETTINGS_OPTIONS_SECTION,//Not supported at the moment
    
    SETTINGS_TOTAL_SECTIONS = 5
}SettingsSections;

typedef enum
{
    SETTINGS_CALL_REDIAL,
    SETTINGS_REMOTE_SESSION_INIT,
    SETTINGS_FACE_DETECTION_MODE,
    
    SETTINS_TOTAL_OPTIONS_NUMBER
} SettingsOptions;

typedef enum
{
    SETTINGS_MEDIA_AEC,
    SETTINGS_MEDIA_AGC,
    SETTINGS_MEDIA_NS,
    
    SETTINGS_MEDIA_TOTAL_NUMBER = 3
} SettingsMediaOptions;

@interface SettingsViewController ()

- (void) switchChanged:(UISwitch*) sender;
- (void) switchMediaChanged:(UISwitch*) sender;
- (void) setSwitchCellData:(UITableViewCell*) tableCell;
- (void) setSwitchCellData:(UITableViewCell*) tableCell atIndexPath:(NSIndexPath*) indexPath;
@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iPhone_background_navigation_mode.png"]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SETTINGS_TOTAL_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int ret = 0;
    
    switch (section)
    {
        case SETTINGS_OPTIONS_SECTION:
            ret = SETTINS_TOTAL_OPTIONS_NUMBER;
            break;
            
        case SETTINGS_MEDIA_SECTION:
            ret = SETTINGS_MEDIA_TOTAL_NUMBER;
            break;
        case SETTINGS_INFO_SECTION:
        case SETTINGS_LOGOUT_SECTION:
        case SETTINGS_LOGGER_SECTION:
        case SETTINGS_RESET_QR_SETTINGS_SECTION:
        default:
            ret = 1;
            break;
    }
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"regularCell";
    static NSString *switchCellIdentifier = @"switchCell";
    static NSString *switchCellMediaIdentifier = @"switchCellMedia";
    static NSString *switchCellResetQRSettings = @"switchCellResetQRSettings";
    
    UITableViewCell *cell = nil;
    
    if (indexPath.section == SETTINGS_OPTIONS_SECTION)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:switchCellIdentifier];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:NO animated:NO];
            [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        cell.tag = indexPath.row;
        //[self setSwitchCellData:cell];
        [self setSwitchCellData:cell atIndexPath:indexPath];
    }
    else if (indexPath.section == SETTINGS_MEDIA_SECTION)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:switchCellMediaIdentifier];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellMediaIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:NO animated:NO];
            [switchView addTarget:self action:@selector(switchMediaChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        cell.tag = indexPath.row;
        [self setSwitchCellData:cell atIndexPath:indexPath];
    }
    else if (indexPath.section == SETTINGS_RESET_QR_SETTINGS_SECTION)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:switchCellMediaIdentifier];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellResetQRSettings];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:NO animated:NO];
            [switchView addTarget:self action:@selector(switchQRSettingsReset:) forControlEvents:UIControlEventValueChanged];
        }
        
        cell.tag = indexPath.row;
        [self setSwitchCellData:cell atIndexPath:indexPath];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
        switch (indexPath.section)
        {
            case SETTINGS_INFO_SECTION:
                cell.textLabel.text = @"User info";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
                
            case SETTINGS_LOGOUT_SECTION:
                cell.textLabel.text = @"Logout";
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                break;
                
            case SETTINGS_LOGGER_SECTION:
                cell.textLabel.text = @"Logger settings";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            default:
                break;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    switch (indexPath.section)
    {
        case SETTINGS_INFO_SECTION:
        {
            InfoViewController *infoViewController = [[InfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
            infoViewController.title = @"User Info";
            
            [self.navigationController pushViewController:infoViewController animated:YES];
        }
            break;
            
        case SETTINGS_LOGGER_SECTION:
        {
            LoggerSettingsViewController *infoViewController = [[LoggerSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            infoViewController.title = @"Logger settings";
            
            [self.navigationController pushViewController:infoViewController animated:YES];
        }
            break;
            
        case SETTINGS_LOGOUT_SECTION:
            [[LoginManager sharedLoginManager] logout];
            break;
            
        default:
            break;
    }
}

- (void) setSwitchCellData:(UITableViewCell*) tableCell
{
    UISwitch* switcher = (UISwitch*) tableCell.accessoryView;
    
    switch (tableCell.tag)
    {
        case SETTINGS_REMOTE_SESSION_INIT:
            [switcher setOn: [[Settings sharedSettings] isRemoteSessionActivationModeOn]];
            tableCell.textLabel.text = @"Remote Session Mode";
            break;
            
        case SETTINGS_FACE_DETECTION_MODE:
            [switcher setOn: [[Settings sharedSettings] isFaceDetectionModeOn]];
            tableCell.textLabel.text = @"Face Detection Mode";
            break;
            
        case SETTINGS_CALL_REDIAL:
            [switcher setOn: [[Settings sharedSettings] isRedialModeOn]];
            tableCell.textLabel.text = @"Redial Mode";
            break;
            
        default:
            break;
    }
}

- (void) setSwitchCellData:(UITableViewCell*) tableCell atIndexPath:(NSIndexPath*) indexPath
{
    UISwitch* switcher = (UISwitch*) tableCell.accessoryView;
    switcher.tag = tableCell.tag;
    
    switch (indexPath.section)
    {
        case SETTINGS_MEDIA_SECTION:
        {
            switch (tableCell.tag)
            {
                case SETTINGS_MEDIA_AEC:
                    [switcher setOn: [[Settings sharedSettings] isMediaAECOn]];
                    tableCell.textLabel.text = @"Acoustic Echo Canceler";
                    break;
                    
                case SETTINGS_MEDIA_AGC:
                    [switcher setOn: [[Settings sharedSettings] isMediaAGCOn]];
                    tableCell.textLabel.text = @"Automatic Gain Control";
                    break;
                    
                case SETTINGS_MEDIA_NS:
                    [switcher setOn: [[Settings sharedSettings] isMediaNSOn]];
                    tableCell.textLabel.text = @"Noise Suppression";
                    break;
                    
                default:
                    break;
            }
        }
        break;
            
            
        case SETTINGS_OPTIONS_SECTION:
        {
            switch (tableCell.tag)
            {
                case SETTINGS_REMOTE_SESSION_INIT:
                    [switcher setOn: [[Settings sharedSettings] isRemoteSessionActivationModeOn]];
                    tableCell.textLabel.text = @"Remote Session Mode";
                    break;
                    
                case SETTINGS_FACE_DETECTION_MODE:
                    [switcher setOn: [[Settings sharedSettings] isFaceDetectionModeOn]];
                    tableCell.textLabel.text = @"Face Detection Mode";
                    break;
                    
                case SETTINGS_CALL_REDIAL:
                    [switcher setOn: [[Settings sharedSettings] isRedialModeOn]];
                    tableCell.textLabel.text = @"Redial Mode";
                    break;
                    
                default:
                    break;
            }
        }
        break;
            
        case SETTINGS_RESET_QR_SETTINGS_SECTION:
        {
            [switcher setOn:[[Settings sharedSettings] isQRSettingsResetEnabled]];
            tableCell.textLabel.text = @"Discard settings applied by QR code";
        }
        default:
            break;
    }
}

- (void) switchChanged:(UISwitch*) sender
{
    switch (sender.tag)
    {
        case SETTINGS_REMOTE_SESSION_INIT:
        {
            [[Settings sharedSettings] enableRemoteSessionActivationMode: [sender isOn]];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationRemoteSessionModeChanged object:nil];
            
            NSString* message = [sender isOn] ? @"Remote session activation mode is turned ON. Please, select two openpeer contacts from your list and remote session will be created." : @"Remote session activation mode is turned OFF";
            
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Remote session activation"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
            break;
            
        case SETTINGS_FACE_DETECTION_MODE:
        {
            [[Settings sharedSettings] enableFaceDetectionMode: [sender isOn]];
            
            NSString* message = [sender isOn] ? @"Face detection mode is turned ON. Please, select contact from the list. Session will be created and face detection activated. As soon face is detected, video call will be started." : @"Face detection mode is turned OFF";
            
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Face detection"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
            break;
            
        case SETTINGS_CALL_REDIAL:
            [[Settings sharedSettings] enableRedialMode: [sender isOn]];
            break;
            
        default:
            break;
    }
}

- (void) switchMediaChanged:(UISwitch*) sender
{
    switch (sender.tag)
    {
        case SETTINGS_MEDIA_AEC:
        {
            [[Settings sharedSettings] enableMediaAEC:[sender isOn]];
            [[HOPMediaEngine sharedInstance] setEcEnabled:[sender isOn]];

        }
            break;
            
        case SETTINGS_MEDIA_AGC:
        {
            [[Settings sharedSettings] enableMediaAGC: [sender isOn]];
            [[HOPMediaEngine sharedInstance] setAgcEnabled:[sender isOn]];

            
        }
            break;
            
        case SETTINGS_MEDIA_NS:
            [[Settings sharedSettings] enableMediaNS: [sender isOn]];
            [[HOPMediaEngine sharedInstance] setNsEnabled:[sender isOn]];
            break;
            
        default:
            break;
    }
}

- (void) switchQRSettingsReset:(UISwitch*) sender
{
    [[Settings sharedSettings] enableQRSettingsReset: [sender isOn]];
}
@end
