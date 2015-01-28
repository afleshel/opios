/*
 
 Copyright (c) 2014, SMB Phone Inc.
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

#import "AppInfoViewController.h"
#import "AppConsts.h"
#import "Settings.h"
#ifdef APNS_ENABLED
#import "APNSManager.h"
#endif
const CGFloat cellDefaultHeight = 50.0;
const CGFloat headerDefaultHeight = 40.0;

typedef enum
{
    
    APP_VERSION,
    APP_BUILD_VERSION,
    APP_SETTINGS_VERSION,
    APP_SETTINGS_DOWNLOAD_URL,
    APP_SETTINGS_OUTER_FRAME_URL,
    APP_SETTINGS_IDENTITY_PROVIDER_DOMAIN,
    APP_SETTINGS_IDENTITY_FEDERATE_BASE_URI,
    APP_SETTINGS_NAMESPACE_GRANT_SERVICE_URL,
    APP_SETTINGS_LOCKBOX_SERVICE_DOMAIN,
#ifdef APNS_ENABLED
    APP_SETTINGS_DEVICE_TOKEN_DOWNLOAD_URL,
    APP_SETTINGS_DEVICE_TOKEN_UPLOAD_URL,
    APP_SETTINGS_PUSH_PROVIDER,
#endif
    APP_INFO_SECTIONS
} AppInfoOptions;

@interface AppInfoViewController ()

@end

@implementation AppInfoViewController

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

    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"iPhone_back_button.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: backButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return APP_INFO_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.numberOfLines = 0;
    
    switch (indexPath.section)
    {
        case APP_VERSION:
            cell.textLabel.text =  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            break;
            
        case APP_BUILD_VERSION:
            cell.textLabel.text =  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            break;
            
        case APP_SETTINGS_VERSION:
            cell.textLabel.text = [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeySettingsVersion];
            break;
            
        case APP_SETTINGS_DOWNLOAD_URL:
            cell.textLabel.text =  [[[NSUserDefaults standardUserDefaults] stringForKey:settingsKeySettingsDownloadURL] length] > 0 ? [[NSUserDefaults standardUserDefaults] stringForKey:settingsKeySettingsDownloadURL] : @"None";
            break;
            
        
        case APP_SETTINGS_OUTER_FRAME_URL:
            cell.textLabel.text =  [[[Settings sharedSettings] getOuterFrameURL] length] > 0 ? [[Settings sharedSettings] getOuterFrameURL]: @"None";
            break;
            
        case APP_SETTINGS_IDENTITY_PROVIDER_DOMAIN:
            cell.textLabel.text =  [[[Settings sharedSettings] getIdentityProviderDomain] length] > 0 ? [[Settings sharedSettings] getIdentityProviderDomain]: @"None";
            break;
            
        case APP_SETTINGS_IDENTITY_FEDERATE_BASE_URI:
            cell.textLabel.text =  [[[Settings sharedSettings] getIdentityFederateBaseURI] length] > 0 ? [[Settings sharedSettings] getIdentityFederateBaseURI]: @"None";
            break;
            
        case APP_SETTINGS_NAMESPACE_GRANT_SERVICE_URL:
            cell.textLabel.text =  [[[Settings sharedSettings] getNamespaceGrantServiceURL] length] > 0 ? [[Settings sharedSettings] getNamespaceGrantServiceURL]: @"None";
            break;
            
        case APP_SETTINGS_LOCKBOX_SERVICE_DOMAIN:
            cell.textLabel.text =  [[[Settings sharedSettings] getLockBoxServiceDomain] length] > 0 ? [[Settings sharedSettings] getLockBoxServiceDomain]: @"None";
            break;
#ifdef APNS_ENABLED
        case APP_SETTINGS_DEVICE_TOKEN_DOWNLOAD_URL:
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell.textLabel.text =  [[[Settings sharedSettings] getDeviceTokenDownloadURL] length] > 0 ? [[Settings sharedSettings] getDeviceTokenDownloadURL]: @"None";
            break;
            
        case APP_SETTINGS_DEVICE_TOKEN_UPLOAD_URL:
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell.textLabel.text =  [[[Settings sharedSettings] getDeviceTokenUploadURL] length] > 0 ? [[Settings sharedSettings] getDeviceTokenUploadURL]: @"None";
            break;
           
        case APP_SETTINGS_PUSH_PROVIDER:
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell.textLabel.text =  [[[APNSManager sharedAPNSManager] pushProvider] length] > 0 ? [[APNSManager sharedAPNSManager] pushProvider] : @"None";
            break;
#endif
        default:
            break;
    }

    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* ret = @"";
    switch (section)
    {
        case APP_VERSION:
            ret = @"Application Version";
            break;
            
        case APP_BUILD_VERSION:
            ret = @"Application Build Version";
            break;
           
        case APP_SETTINGS_VERSION:
            ret = @"Settings Version";
            break;
            
        case APP_SETTINGS_DOWNLOAD_URL:
            ret = @"Settings Download URL";
            break;
            
        case APP_SETTINGS_OUTER_FRAME_URL:
            ret = @"Outer Frame URL";
            break;
            
        case APP_SETTINGS_IDENTITY_PROVIDER_DOMAIN:
            ret = @"Settings Identity Provider Domain";
            break;
            
        case APP_SETTINGS_IDENTITY_FEDERATE_BASE_URI:
            ret = @"Identity Federate Base URI";
            break;
            
        case APP_SETTINGS_NAMESPACE_GRANT_SERVICE_URL:
            ret = @"Namespace Grant Service URL";
            break;
            
        case APP_SETTINGS_LOCKBOX_SERVICE_DOMAIN:
            ret = @"Settings Lockbox Service Domain";
            break;
#ifdef APNS_ENABLED
        case APP_SETTINGS_DEVICE_TOKEN_DOWNLOAD_URL:
            ret = @"Device Token Download URL";
            break;
          
        case APP_SETTINGS_DEVICE_TOKEN_UPLOAD_URL:
            ret = @"Device Token Upload URL";
            break;
            
        case APP_SETTINGS_PUSH_PROVIDER:
            ret = @"Push Provider";
            break;
#endif
        default:
            break;
    }
    
    return ret;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat ret = 0;
    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
    
    switch (indexPath.section)
    {
#ifdef APNS_ENABLED
        case APP_SETTINGS_DEVICE_TOKEN_DOWNLOAD_URL:
        {
            UIFont* cellFont = [UIFont boldSystemFontOfSize:17.0];
            CGSize labelSize = [[[Settings sharedSettings] getDeviceTokenDownloadURL] boundingRectWithSize: constraintSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: cellFont } context: nil].size;
            ret = (labelSize.height) > cellDefaultHeight ? labelSize.height + 20.0: cellDefaultHeight;
        }
            break;
            
        case APP_SETTINGS_DEVICE_TOKEN_UPLOAD_URL:
        {
            UIFont* cellFont = [UIFont boldSystemFontOfSize:17.0];
            CGSize labelSize = [[[Settings sharedSettings] getDeviceTokenUploadURL] boundingRectWithSize: constraintSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: cellFont } context: nil].size;
            ret = (labelSize.height) > cellDefaultHeight ? labelSize.height + 20.0: cellDefaultHeight;
        }
            break;
#endif
        default:
            ret = cellDefaultHeight;
            break;
    }
    
    return ret;
}

@end
