/*
 
 Copyright (c) 2012-2015, Hookflash Inc.
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

#import "NewChatCell.h"
#import <OpenPeerSDK/HOPMessage+External.h>
#import <OpenPeerSDK/HOPContact+External.h>
#import "ImageManager.h"
#import "Utility.h"
#import "OpenPeer.h"
#import "MainViewController.h"

@implementation NewChatCell

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    
    self.chatNameFont =  [UIFont fontWithName:@"Helvetica-Bold" size:9.0];
    self.chatTimestampFont = [UIFont fontWithName:@"Helvetica" size:9.0];
    // [self.imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    [self.imageView2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:[[OpenPeer sharedOpenPeer] mainViewController] action:@selector(showImage:)]];
    
    //[self.imageView2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:[ImageManager sharedImageManager] action:@selector(showFullscreenImage:)]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setMessage:(HOPMessage*) inMessage
{
    [super setMessage:inMessage];
    
    BOOL registerForNotifications = NO;
    if (self.message && self.message.messageID.length > 0)
    {
        UIImage* img = [[ImageManager sharedImageManager] imageForKey:self.message.messageID];
        if (img)
        {
            self.imageView2.image = img;
            if (![inMessage.outMessageStatus isEqualToString:@"Delivered"] && [self.message.sender isSelf])
            {
                registerForNotifications = YES;
            }
        }
        else
        {
            registerForNotifications = YES;
            [[ImageManager sharedImageManager] downloadSharedImageForMessage:self.message];
        }
        
        if (registerForNotifications)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationFileUploadProgress object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressBar:) name:notificationFileUploadProgress object:nil];
        }
        
        UIColor* textColor;
        
        if (!self.message.removed.boolValue)
            textColor = [UIColor whiteColor];
        else
            textColor = [UIColor grayColor];
        
        NSString* formatedDate = [Utility formatedMessageTimeStampForDate:self.message.date];
        
        NSDictionary * attributesSenderName = [NSDictionary dictionaryWithObjectsAndKeys:self.chatNameFont, NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil];
        
        NSAttributedString * senderName = [[NSAttributedString alloc] initWithString:[inMessage.sender getName] attributes:attributesSenderName];
  
        NSDictionary * attributesSeparator = [NSDictionary dictionaryWithObjectsAndKeys:self.chatTimestampFont, NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil];
        
        NSAttributedString * separator = [[NSAttributedString alloc] initWithString:@" | " attributes:attributesSeparator];
        
        NSAttributedString * date = [[NSAttributedString alloc] initWithString:formatedDate attributes:attributesSeparator];
        
        NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithAttributedString:senderName];
        [string appendAttributedString:separator];
        [string appendAttributedString:date];
        
        [self.senderLabel setAttributedText:string];
        
        self.senderLabel.textAlignment = [inMessage.sender isSelf] ? NSTextAlignmentRight : NSTextAlignmentLeft;
        
        if(self.message.showStatus.boolValue && self.message.outgoingMessageStatus >= HOPConversationThreadMessageDeliveryStateSent)
            self.messageDeliveryStatusLabel.hidden = NO;
        else
            self.messageDeliveryStatusLabel.hidden = YES;
    }
}

- (void)updateProgressBar:(NSNotification*) notification
{
    NSDictionary* dict = notification.object;
    if (dict)
    {
        NSString* messageID = [dict objectForKey:@"messageID"];
        if ([messageID isEqualToString: self.message.messageID])
        {
            NSNumber* procent = [dict objectForKey:@"procent"];
            if (procent)
            {
                NSString* progressMessage = /*![self.message.outMessageStatus isEqualToString:@"Delivered"] && */[self.message.sender isSelf] ? [NSString stringWithFormat:@"File upload in progress ... %d%", procent.intValue] : [NSString stringWithFormat:@"Download in progress ... %d%", procent.intValue];
                if (progressMessage.length > 0)
                {
                    if (procent.intValue != 100)
                    {
                        self.messageDeliveryStatusLabel.hidden = NO;
                        self.messageDeliveryStatusLabel.text = progressMessage;
                    }
                    else
                    {
                        self.messageDeliveryStatusLabel.text = [self.message.sender isSelf] ? @"Uploaded" : @"Downloaded";
                        [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationFileUploadProgress object:nil];
                    }
                }
            }
        }
    }
}
@end
