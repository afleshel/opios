//
//  NewChatCell.m
//  OpenPeerSampleApp
//
//  Created by Sergej on 3/10/15.
//  Copyright (c) 2015 Hookflash. All rights reserved.
//

#import "NewChatCell.h"
#import <OpenPeerSDK/HOPMessage.h>
#import <OpenPeerSDK/HOPContact+External.h>
#import "ImageManager.h"
#import "Utility.h"

@implementation NewChatCell

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    
    self.chatNameFont =  [UIFont fontWithName:@"Helvetica-Bold" size:9.0];
    self.chatTimestampFont = [UIFont fontWithName:@"Helvetica" size:9.0];
    // [self.imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    //[self.imageView2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:[ImageManager sharedImageManager] action:@selector(showFullscreenImage:)]];
    
    //[self.imageView2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:[ImageManager sharedImageManager] action:@selector(showFullscreenImage:)]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setMessage:(HOPMessage*) inMessage
{
    [super setMessage:inMessage];
    
    if (self.message && self.message.messageID.length > 0)
    {
        UIImage* img = [[ImageManager sharedImageManager] imageForKey:self.message.messageID];
        if (img)
        {
            self.imageView2.image = img;
        }
        else
            [[ImageManager sharedImageManager] downloadSharedImageForMessage:self.message];
        
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
    }
}
@end
