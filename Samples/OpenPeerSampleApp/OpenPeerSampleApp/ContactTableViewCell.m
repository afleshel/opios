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

#import "ContactTableViewCell.h"
#import <OpenpeerSDK/HOPRolodexContact+External.h>
#import <OpenpeerSDK/HOPAssociatedIdentity.h>
#import <OpenpeerSDK/HOPIdentityProvider.h>
#import <OpenpeerSDK/HOPAvatar+External.h>
#import "AppConsts.h"
#import "ImageManager.h"
#import "SessionManager.h"
#import "Session.h"
#import "UIBadgeView.h"


@interface ContactTableViewCell ()

@end

@implementation ContactTableViewCell

- (void) setContact:(HOPRolodexContact *)inContact inTable:(UITableView*) table atIndexPath:(NSIndexPath *)indexPath
{
    self.contact = inContact;
    
    self.displayName.text = [self.contact name];
    
    self.displayImage.contentMode = UIViewContentModeScaleAspectFill;
    self.displayImage.clipsToBounds = YES;
    
    self.username.textColor = [UIColor colorWithRed:112.0/255.0 green:116.0/255.0 blue:119.0/255.0 alpha:1.0];
    self.username.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.username.text = _contact.identityURI;
    
    HOPAvatar* avatar = [inContact getAvatarForWidth:[NSNumber numberWithFloat:AVATAR_WIDTH] height:[NSNumber numberWithFloat:AVATAR_HEIGHT]];
    if (avatar)
    {
        UIImage* img = [avatar getImage];
        if (!img)
            [[ImageManager sharedImageManager] donwloadImageForAvatar:avatar tableView:table indexPath:indexPath];
        else
            self.displayImage.image = img;
    }
    
    self.displayImage.layer.cornerRadius = 5.0;
    self.displayImage.layer.borderWidth = 1.0;
    self.displayImage.layer.borderColor = [[UIColor whiteColor] CGColor];
    
    if ([inContact.associatedIdentity.identityProvider.baseURI isEqualToString:identityFacebookBaseURI])
    {
        UIImageView *facebookTag = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"facebook_tag.png"]];
        [facebookTag setFrame:CGRectMake(self.displayImage.frame.size.width - 10.0, self.displayImage.frame.size.height-10.0, 10.0, 10.0)];
        [self.displayImage addSubview:facebookTag];
    }
    
    if (inContact.identityContact)
    {
        self.userInteractionEnabled = YES;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        self.userInteractionEnabled = NO;
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    
    //if (self.contact.status != OFFLINE)
    {
        self.displayName.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
        self.displayName.textColor = [UIColor blackColor];
    }
    /*else
     {
     self.displayName.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
     self.displayName.textColor = [UIColor colorWithRed:112.0/255.0 green:116.0/255.0 blue:119.0/255.0 alpha:1.0];
     //[self.displayImage setAlpha:0.8];
     [_displayChatImage setAlpha:0.4];
     [_displayVoiceImage setAlpha:0.4];
     [_displayVideoImage setAlpha:0.4];
     }*/
    
    Session* session = [[SessionManager sharedSessionManager] getSessionForContact:inContact];
    if ([session.unreadMessageArray count] > 0)
    {
        NSString* numberToDisplay = [NSString stringWithFormat:@"%d",[session.unreadMessageArray count]];
        self.badgeView.hidden = NO;
        self.badgeView.badgeText = numberToDisplay;
    }
}
@end
