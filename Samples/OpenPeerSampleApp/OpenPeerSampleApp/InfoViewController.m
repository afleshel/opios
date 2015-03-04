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

#import "InfoViewController.h"
#import "OpenPeer.h"
#import "Utility.h"
#ifdef APNS_ENABLED
#import "APNSManager.h"
#endif
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPIdentity+External.h>
#import <OpenpeerSDK/HOPAssociatedIdentity.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenpeerSDK/HOPIdentityProvider.h>
#import <OpenpeerSDK/HOPAccountIdentity.h>

const CGFloat cellDefaultHeight = 50.0;
const CGFloat headerDefaultHeight = 40.0;

typedef enum
{
    USER_INFO_NAME,
    USER_INFO_STABLE_ID,
    USER_INFO_PEER_URI,
    USER_INFO_IDENTITIES,
#ifdef APNS_ENABLED
    USER_INFO_DEVICE_TOKEN,
#endif
    USER_INFO_SECTIONS
} UserInfoOptions;

@interface InfoViewController ()

@property (nonatomic, strong) HOPIdentity* contact;
@property (nonatomic) BOOL showContactInfo;

@end

@implementation InfoViewController

- (id) initWithContact:(HOPIdentity*) inContact style:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        self.contact = inContact;
        self.showContactInfo = self.contact != nil;
    }
    return self;
}
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return USER_INFO_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger ret = 0;
    
    switch (section)
    {
        case USER_INFO_NAME:
        case USER_INFO_STABLE_ID:
        case USER_INFO_PEER_URI:
#ifdef APNS_ENABLED
        case USER_INFO_DEVICE_TOKEN:
#endif
            ret = 1;
            break;
            
        case USER_INFO_IDENTITIES:
            ret = self.showContactInfo ? [self.contact getNumberOfAssociatedIdentities] : [[[HOPAccount sharedAccount] getAssociatedIdentities] count];
            break;
            
        default:
            break;
    }
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UITableViewCellStyle cellStyle = indexPath.section == USER_INFO_IDENTITIES ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault;
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    
    switch (indexPath.section)
    {
        case USER_INFO_NAME:
            cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = self.showContactInfo ? self.contact.name : [[HOPAccount sharedAccount] getName];
            break;
            
        case USER_INFO_STABLE_ID:
            cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = self.showContactInfo ? [self.contact getStableID]  : [[HOPAccount sharedAccount] getStableID];
            break;
            
        case USER_INFO_PEER_URI:
            cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = self.showContactInfo ? [self.contact getPeerURI]: [[HOPAccount sharedAccount] getPeerURI];
            break;
            
        case USER_INFO_IDENTITIES:
        {
            HOPIdentity* identity = nil;
            if (self.showContactInfo)
            {
                identity = self.contact;
            }
            else
            {
                HOPAccountIdentity* accountIdentity = [[[HOPAccount sharedAccount] getAssociatedIdentities] objectAtIndex:indexPath.row];
                identity = [[HOPModelManager sharedModelManager] getIdentityByIdentityURI:[accountIdentity getIdentityURI]];
            }
            cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = identity.associatedIdentity.identityProvider.name;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Identity URI: %@",identity.identityURI];
        }
            break;
#ifdef APNS_ENABLED
        case USER_INFO_DEVICE_TOKEN:
        {
            cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = self.showContactInfo ?  [self.contact getPushNotificationDeviceToken] : [[APNSManager sharedAPNSManager] getSelfDeviceToken];
        }
            break;
#endif
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat ret = 0;
    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
    
    switch (indexPath.section)
    {
        case USER_INFO_NAME:
        {
            NSString* value = self.showContactInfo ? self.contact.name : [[HOPAccount sharedAccount] getName];
            UIFont* cellFont = [UIFont boldSystemFontOfSize:17.0];
            CGSize labelSize = [value boundingRectWithSize: constraintSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: cellFont } context: nil].size;
            ret = (labelSize.height) > cellDefaultHeight ? labelSize.height : cellDefaultHeight;
        }
            break;
            
        case USER_INFO_STABLE_ID:
        {
            NSString* value = self.showContactInfo ? [self.contact getStableID] : [[HOPAccount sharedAccount] getStableID];
            UIFont* cellFont = [UIFont boldSystemFontOfSize:17.0];

            CGSize labelSize = [value boundingRectWithSize: constraintSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: cellFont } context: nil].size;

            ret = (labelSize.height) > cellDefaultHeight ? labelSize.height : cellDefaultHeight;
        }
            break;
            
        case USER_INFO_PEER_URI:
        {
            UIFont* cellFont = [UIFont boldSystemFontOfSize:17.0];

            NSString* str = self.showContactInfo ? [self.contact getPeerURI] : [[HOPAccount sharedAccount] getPeerURI];

            CGSize labelSize = [str boundingRectWithSize: constraintSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: cellFont } context: nil].size;
            ret = labelSize.height > cellDefaultHeight ? labelSize.height : cellDefaultHeight;
        }
            break;
            
        case USER_INFO_IDENTITIES:
        {
            HOPAccountIdentity* accountIdentity = [[[HOPAccount sharedAccount] getAssociatedIdentities] objectAtIndex:indexPath.row];
            
            HOPIdentity* identity = nil;
            if (self.showContactInfo)
            {
                identity = self.contact;
            }
            else
            {
                identity = [[HOPModelManager sharedModelManager] getIdentityByIdentityURI:[accountIdentity getIdentityURI]];
            }
            
            UIFont* cellFont = [UIFont boldSystemFontOfSize:17.0];
            UIFont* cellDetailFont = [UIFont boldSystemFontOfSize:14.0];

            
            CGSize labelSize = [[accountIdentity getIdentityProviderDomain] boundingRectWithSize: constraintSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: cellFont } context: nil].size;
            NSString* str = [NSString stringWithFormat:@"Identity URI: %@",identity.identityURI];
            CGSize labelDetailSize = [str boundingRectWithSize: constraintSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: cellDetailFont } context: nil].size;            CGFloat totalCellHeight = labelSize.height + labelDetailSize.height;
            ret = (totalCellHeight) > cellDefaultHeight ? totalCellHeight: cellDefaultHeight;
        }
            break;
#ifdef APNS_ENABLED
        case USER_INFO_DEVICE_TOKEN:
        {
            UIFont* cellFont = [UIFont boldSystemFontOfSize:17.0];
            NSString* str = self.showContactInfo ? [self.contact getPushNotificationDeviceToken] : [[APNSManager sharedAPNSManager] getSelfDeviceToken];
            CGSize labelSize = [str boundingRectWithSize: constraintSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: cellFont } context: nil].size;
            ret = (labelSize.height) > cellDefaultHeight ? labelSize.height : cellDefaultHeight;
        }
            break;
#endif
        default:
            break;
    }
    
    return ret;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return headerDefaultHeight;
}

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *customTitleView = [ [UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, headerDefaultHeight)];
    
    UILabel* ret = [[UILabel alloc] initWithFrame:CGRectMake(25.0, 0.0, tableView.frame.size.width, headerDefaultHeight)];
    ret.backgroundColor = [UIColor clearColor];
    ret.textColor = [UIColor whiteColor];
    
    switch (section)
    {
        case USER_INFO_NAME:
            ret.text = @"Name";
            break;
            
        case USER_INFO_STABLE_ID:
            ret.text = @"Stable Id";
            break;
            
        case USER_INFO_PEER_URI:
            ret.text = @"Peer URI";
            break;
            
        case USER_INFO_IDENTITIES:
            ret.text = @"Associated Identities";
            break;
#ifdef APNS_ENABLED
        case USER_INFO_DEVICE_TOKEN:
            ret.text = @"Device Token";
            break;
#endif
        default:
            break;
    }
    
    [customTitleView addSubview:ret];
    return customTitleView;
}

@end
