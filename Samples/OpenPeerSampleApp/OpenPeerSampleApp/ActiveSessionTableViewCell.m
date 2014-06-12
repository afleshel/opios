//
//  ActiveSessionTableViewCell.m
//  OpenPeerSampleApp
//
//  Created by Sergej on 6/9/14.
//  Copyright (c) 2014 Hookflash. All rights reserved.
//

#import "ActiveSessionTableViewCell.h"
#import "UIBadgeView.h"
#import <OpenPeerSDK/HOPSessionRecord.h>
#import <OpenPeerSDK/HOPPublicPeerFile.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPRolodexContact.h>
#import <OpenPeerSDK/HOPAvatar.h>

#import "ImageManager.h"
#import "Session.h"
#import "SessionManager.h"

@interface ActiveSessionTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *displayName;
@property (nonatomic, weak) IBOutlet UIImageView *displayImage;
@property (nonatomic, weak) IBOutlet UIImageView* displaySessionTypeImage;
@property (nonatomic, weak) IBOutlet UIBadgeView* badgeView;

@property (nonatomic, weak) HOPSessionRecord* sessionRecord;

@end
@implementation ActiveSessionTableViewCell

- (void)awakeFromNib
{
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setSession:(HOPSessionRecord *)inSessionRecord
{
    self.sessionRecord = inSessionRecord;
    self.displayName.text = self.sessionRecord.name;
    
    HOPPublicPeerFile* publicPeerFile = [[self.sessionRecord.participants allObjects] objectAtIndex:0];
    
    HOPRolodexContact* participant = [[[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:publicPeerFile.peerURI] objectAtIndex:0];
    
    UIImage* img = [[ImageManager sharedImageManager] getAvatarImageForRolodexContact:participant];
    if (img)
        self.displayImage.image = img;
    
    self.displayImage.layer.cornerRadius = 5.0;
    self.displayImage.layer.borderWidth = 1.0;
    self.displayImage.layer.borderColor = [[UIColor whiteColor] CGColor];
    
    Session* session = [[SessionManager sharedSessionManager] getSessionForSessionId:self.sessionRecord.sessionID];
    if ([session.unreadMessageArray count] > 0)
    {
        NSString* numberToDisplay = [NSString stringWithFormat:@"%d",[session.unreadMessageArray count]];
        self.badgeView.hidden = NO;
        self.badgeView.badgeText = numberToDisplay;
    }
    else
    {
        self.badgeView.hidden = YES;
    }
}

@end
