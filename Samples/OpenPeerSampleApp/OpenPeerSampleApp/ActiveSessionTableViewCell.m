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

#import "ActiveSessionTableViewCell.h"
#import "UIBadgeView.h"
//#import <OpenPeerSDK/HOPConversationEvent+External.h>
#import <OpenPeerSDK/HOPAvatar.h>
#import <OpenPeerSDK/HOPConversationRecord+External.h>
#import <OpenPeerSDK/HOPConversation.h>
#import "ImageManager.h"
#import "SessionManager.h"
#import "Utility.h"

@interface ActiveSessionTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *displayName;
@property (nonatomic, weak) IBOutlet UIImageView *displayImage;
@property (nonatomic, weak) IBOutlet UIImageView* displaySessionTypeImage;
@property (nonatomic, weak) IBOutlet UIBadgeView* badgeView;
@property (nonatomic, weak) IBOutlet UILabel *labelCreationDate;
@property (nonatomic, weak) IBOutlet UILabel *labelLastMessage;
@property (nonatomic, weak) IBOutlet UIView *messageView;



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

- (void)setLastMessage
{
    self.labelLastMessage.text = [[SessionManager sharedSessionManager] getLastTextMessageForConversationRecord:self.conversationRecord];
    
    self.labelLastMessage.hidden = [self.labelLastMessage.text length] == 0;
}

- (void)updateBadge:(HOPConversation *)conversation
{
    if (conversation.numberOfUnreadMessages > 0)
    {
        NSString* numberToDisplay = [NSString stringWithFormat:@"%lu",(unsigned long)conversation.numberOfUnreadMessages];
        self.badgeView.hidden = NO;
        self.badgeView.badgeText = numberToDisplay;
    }
    else
    {
        self.badgeView.hidden = YES;
    }
}

- (void)updateIcon:(HOPConversationRecord *)record
{
    NSArray* participants = [record getContacts];
    if (participants.count > 1)
    {
        NSMutableArray* avatars = [[NSMutableArray alloc] init];
        for (HOPIdentity* identity in participants)
        {
            UIImage* img = [[ImageManager sharedImageManager] getAvatarImageForIdentity:identity];
            if (img)
                [avatars addObject:img];
            else
                [avatars addObject:[UIImage imageNamed:@"avatar.png"]];
        }
        
        UIImage* avatarsImage = [Utility createImageFromImages:avatars inFrame:self.displayImage.frame];
        if (avatarsImage)
            self.displayImage.image = avatarsImage;
    }
    else if (participants.count == 1)
    {
        HOPIdentity* identity = [participants objectAtIndex:0];
        UIImage* img = [[ImageManager sharedImageManager] getAvatarImageForIdentity:identity];
        if (img)
            self.displayImage.image = img;
    }
    else
        return;
    
    self.displayImage.layer.cornerRadius = 5.0;
    self.displayImage.layer.borderWidth = 1.0;
    self.displayImage.layer.borderColor = [[UIColor whiteColor] CGColor];
}

- (void) setRecord:(HOPConversationRecord *)record
{
    HOPConversation* conversation = [record getConversation];
    
    if (self.displayImage)
        [self.displayImage stopAnimating];
    
    _conversationRecord = record;
    //self.event = event;
    self.displayName.text = record.name.length > 0 ? record.name : [conversation getDefaultTitle];
    
    [self updateIcon:record];
    
    [self updateBadge:conversation];
    
    self.labelCreationDate.text = [Utility stringFromDate:self.conversationRecord.lastActivity];
    [self setLastMessage];
}

-(void)drawInnerShadowOnView:(UIView *)view
{
    UIImageView *innerShadowView = [[UIImageView alloc] initWithFrame:view.bounds];
    
    innerShadowView.contentMode = UIViewContentModeScaleToFill;
    innerShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [view addSubview:innerShadowView];
    
    [innerShadowView.layer setMasksToBounds:YES];
    
    [innerShadowView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [innerShadowView.layer setShadowColor:[UIColor blackColor].CGColor];
    [innerShadowView.layer setBorderWidth:1.0f];
    
    [innerShadowView.layer setShadowOffset:CGSizeMake(0, 0)];
    [innerShadowView.layer setShadowOpacity:1.0];
    
    [innerShadowView.layer setCornerRadius:5.0];
    
    // this is the inner shadow thickness
    [innerShadowView.layer setShadowRadius:1.5];
}

- (void) setBackground
{
    [self setBackgroundColor:[UIColor clearColor]];
    
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = self.bounds;
    grad.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor colorWithRed:237.0/255.0 green:237.0/255.0 blue:237.0/255.0 alpha:1] CGColor], nil];
    
    [self setBackgroundView:[[UIView alloc] init]];
    [self.backgroundView.layer insertSublayer:grad atIndex:0];
    
    self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tableViewCell_selected.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
}

- (void) updateActivity
{
    self.labelCreationDate.text = [Utility stringFromDate:self.conversationRecord.lastActivity];
    [self setLastMessage];
    self.displayName.text = self.conversationRecord.name;
    [self updateIcon:self.conversationRecord];
    [self updateBadge:[self.conversationRecord getConversation]];
}
@end
