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

#import "ChatMessageCell.h"
#import "TTTAttributedLabel.h"
#import "Utility.h"

#import <OpenpeerSDK/HOPIdentity+External.h>
#import <OpenpeerSDK/HOPMessageRecord+External.h>
#import <OpenpeerSDK/HOPConversation.h>
#import <OpenPeerSDK/HOPContact+External.h>

#define SPACE_BETWEEN_LABELS 2.0
#define TRAILING_SPACE 10.0
#define LEADING_SPACE 10.0
#define TOP_SPACE 2.0

@interface ChatMessageCell()

@property (nonatomic, strong) UIFont *chatNameFont;
@property (nonatomic, strong) UIFont *chatTimestampFont;
@property (nonatomic, strong) NSString *unicodeMessageText;
@property (nonatomic, strong) UILabel *messageStatus;
@property (nonatomic, strong) UIImage *baloonImageLeft;
@property (nonatomic, strong) UIImage *baloonImageRight;

- (void) setUnicodeChars:(NSString *)str;

@end

@implementation ChatMessageCell

@synthesize message;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.backgroundColor = [UIColor clearColor];
        self.chatNameFont =  [UIFont fontWithName:@"Helvetica-Bold" size:9.0];
        self.chatTimestampFont = [UIFont fontWithName:@"Helvetica" size:9.0];
        self.messageLabel = [[TTTAttributedLabel alloc] init];
        self.messageStatus = [[UILabel alloc] init];
        
        self.baloonImageLeft = [[UIImage imageNamed:@"chat_bubble_left.png"] stretchableImageWithLeftCapWidth:38.0 topCapHeight:14];
        self.baloonImageRight = [[UIImage imageNamed:@"chat_bubble_right.png"] stretchableImageWithLeftCapWidth:13.0 topCapHeight:14];
    }
    return self;
}

-(void)setUnicodeChars:(NSString *)str
{
    // replace emotions
    if(str != _unicodeMessageText)
    {
        _unicodeMessageText = nil;
        
        NSMutableString *ms1 = [[NSMutableString alloc] initWithString:str];
        
        [ms1 replaceOccurrencesOfString:@":)" withString:@"\ue415" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":)" withString:@"\ue415" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-)" withString:@"\ue415" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":]" withString:@"\ue415" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"=)" withString:@"\ue415" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=)" withString:@"\ue415" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@";)" withString:@"\ue405" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@";=)" withString:@"\ue405" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@";-)" withString:@"\ue405" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":D" withString:@"\ue057" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-D" withString:@"\ue057" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=D" withString:@"\ue057" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":d" withString:@"\ue057" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-d" withString:@"\ue057" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=d" withString:@"\ue057" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":(" withString:@"\ue403" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-(" withString:@"\ue403" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":[" withString:@"\ue403" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=(" withString:@"\ue403" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@";(" withString:@"\ue413" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@";-(" withString:@"\ue413" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@";=(" withString:@"\ue413" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":o" withString:@"\ue40d" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-o" withString:@"\ue40d" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=o" withString:@"\ue40d" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":O" withString:@"\ue40d" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-O" withString:@"\ue40d" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=O" withString:@"\ue40d" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":*" withString:@"\ue418" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=*" withString:@"\ue418" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-*" withString:@"\ue418" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":p" withString:@"\ue105" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-p" withString:@"\ue105" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=p" withString:@"\ue105" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":P" withString:@"\ue105" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-P" withString:@"\ue105" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=P" withString:@"\ue105" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":$" withString:@"\ue414" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-$" withString:@"\ue414" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=$" withString:@"\ue414" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"|-)" withString:@"\ue13c" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"I-)" withString:@"\ue13c" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"I=)" withString:@"\ue13c" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(snooze)" withString:@"\ue13c" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"|(" withString:@"\ue40e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"|-(" withString:@"\ue40e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"|=(" withString:@"\ue40e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(inlove)" withString:@"\ue106" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":&" withString:@"\ue408" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-&" withString:@"\ue408" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=&" withString:@"\ue408" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(puke)" withString:@"\ue408" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@":@" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":-@" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@":=@" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"x(" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"x-(" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"x=(" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"X(" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"X-(" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"X=(" withString:@"\ue059" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(party)" withString:@"\ue312" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(call)" withString:@"\ue009" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(devil)" withString:@"\ue11a" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(wait)" withString:@"\ue012" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(clap)" withString:@"\ue41f" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(rofl)" withString:@"\ue412" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(happy)" withString:@"\ue056" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(punch)" withString:@"\ue00d" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(y)" withString:@"\ue00e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(Y)" withString:@"\ue00e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(ok)" withString:@"\ue00e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(n)" withString:@"\ue421" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(N)" withString:@"\ue421" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(handshake)" withString:@"\ue420" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(h)" withString:@"\ue022" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(H)" withString:@"\ue022" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(l)" withString:@"\ue022" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(L)" withString:@"\ue022" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(u)" withString:@"\ue023" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(U)" withString:@"\ue023" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(e)" withString:@"\ue103" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(m)" withString:@"\ue103" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(f)" withString:@"\ue305" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(F)" withString:@"\ue305" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(rain)" withString:@"\ue331" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(london)" withString:@"\ue331" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(sun)" withString:@"\ue04a" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(music)" withString:@"\ue03e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(coffee)" withString:@"\ue045" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(beer)" withString:@"\ue047" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(cash)" withString:@"\ue12f" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(mo)" withString:@"\ue12f" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"($)" withString:@"\ue12f" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(muscle)" withString:@"\ue14c" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(flex)" withString:@"\ue14c" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(^)" withString:@"\ue34b" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(cake)" withString:@"\ue34b" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(d)" withString:@"\ue044" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(D)" withString:@"\ue044" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(*)" withString:@"\ue32f" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        [ms1 replaceOccurrencesOfString:@"(smoking)" withString:@"\ue30e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(smoke)" withString:@"\ue30e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        [ms1 replaceOccurrencesOfString:@"(ci)" withString:@"\ue30e" options:NSLiteralSearch range:NSMakeRange(0, [ms1 length])];
        
        _unicodeMessageText = [NSString stringWithString:ms1];
        //OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"******************setUnicodeChars: _unicodeMessageText:%@",_unicodeMessageText);
    }
}


- (void)setMessageStatus
{
    //Show delivery
    float labelHeight = 0;
    float headerLabelXpos;
    
    if(self.message.showStatus.boolValue && message.outgoingMessageStatus >= HOPConversationThreadMessageDeliveryStateSent)
    {
        NSString* statusString = [HOPConversation stringForMessageDeliveryState:(HOPConversationThreadMessageDeliveryState)self.message.outgoingMessageStatus];
        
        if ((HOPConversationThreadMessageDeliveryState)self.message.outgoingMessageStatus == HOPConversationThreadMessageDeliveryStateUserNotAvailable)
            statusString = @"Send failed, try again by tapping this message";
        
        labelHeight = [statusString sizeWithAttributes:@{NSFontAttributeName:self.chatNameFont}].height;
        
        CGSize statusLabelSize = [statusString sizeWithAttributes:@{NSFontAttributeName:self.chatNameFont}];
        headerLabelXpos = self.frame.size.width  - 40.0 - statusLabelSize.width;
        float y = self.messageLabel.frame.origin.y + self.messageLabel.frame.size.height + 6*TOP_SPACE;
        self.messageStatus.frame = CGRectMake(headerLabelXpos, y, statusLabelSize.width + SPACE_BETWEEN_LABELS, labelHeight);
        self.messageStatus.backgroundColor = [UIColor clearColor];
        self.messageStatus.textColor = !self.message.removed.boolValue ? [UIColor whiteColor] : [UIColor grayColor];

        self.messageStatus.font = self.chatNameFont;
        self.messageStatus.text = statusString;
        
        if (self.messageStatus)
            [self.contentView addSubview:self.messageStatus];
    }
    else
        [self.messageStatus removeFromSuperview];
}

-(void)layoutSubviews
{
    BOOL isHomeUserSender = [self.message.sender isSelf];
    UIImage *msgBaloonImg;
    
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.contentView.frame = self.bounds;
    
    if (self.message)
    {
        if ([self.message.text length] > 0)
        {
            
            CGSize participantNameSize;
            CGSize dateSize;
            
            float labelHeight;
            float headerLabelXpos = TRAILING_SPACE;
            
            NSString *messageSenderName;
            
            
            [self setUnicodeChars:self.message.text];
            

            messageSenderName = [self.message.sender getDefaultIdentity].name;
            
            UIColor* textColor;
            
            if (!self.message.removed.boolValue)
                textColor = [UIColor whiteColor];
            else
                textColor = [UIColor grayColor];
            
            
            UIImage* image = nil;
            UIImageView* imageView = nil;
            CGRect rectEditedIcon = CGRectMake(0.0, 0.0, 0.0, 0.0);
            
            if (message.edited.boolValue && !self.message.removed.boolValue)
            {
                image = [UIImage imageNamed:@"chat_edited_message_icon.png"];
                imageView = [[UIImageView alloc] initWithImage:image];
                rectEditedIcon = imageView.frame;
                rectEditedIcon.origin.y = 0;
                
                if(!isHomeUserSender)
                {
                    rectEditedIcon.origin.x = headerLabelXpos;
                    headerLabelXpos += imageView.frame.size.width + SPACE_BETWEEN_LABELS;
                }
            }
            
            
            //Label participant
            participantNameSize = [messageSenderName sizeWithAttributes:@{NSFontAttributeName:self.chatNameFont}];
            labelHeight = participantNameSize.height + TOP_SPACE;
            UILabel *labelParticipant = [[UILabel alloc] initWithFrame:CGRectMake(headerLabelXpos, TOP_SPACE, participantNameSize.width + SPACE_BETWEEN_LABELS, labelHeight)];
            labelParticipant.backgroundColor = [UIColor clearColor];
            labelParticipant.textColor = textColor;
            labelParticipant.font = self.chatNameFont;
            labelParticipant.text = messageSenderName;
            
            headerLabelXpos += labelParticipant.frame.size.width;
            
            //Label separator
            UILabel *labelSeparator = [[UILabel alloc] initWithFrame:CGRectMake(headerLabelXpos, TOP_SPACE, 10.0, labelHeight)];
            labelSeparator.backgroundColor =[UIColor clearColor];
            labelSeparator.textColor = textColor;
            labelSeparator.textAlignment = NSTextAlignmentCenter;
            labelSeparator.font = self.chatTimestampFont;
            labelSeparator.text = @" | ";
            
            headerLabelXpos += labelSeparator.frame.size.width;
            
            // Label date
            NSString* formatedDate = [Utility formatedMessageTimeStampForDate:self.message.date];
            dateSize = [formatedDate sizeWithAttributes:@{NSFontAttributeName:self.chatNameFont}];//[formatedDate sizeWithFont:self.chatTimestampFont];
            UILabel *lblChatMessageTimestamp = [[UILabel alloc] initWithFrame:CGRectMake(headerLabelXpos, TOP_SPACE, dateSize.width + TRAILING_SPACE, labelHeight)];
            
            lblChatMessageTimestamp.textColor = textColor;
            
            lblChatMessageTimestamp.backgroundColor = [UIColor clearColor];
            lblChatMessageTimestamp.font = self.chatTimestampFont;
            lblChatMessageTimestamp.text = formatedDate;
            
            
            CGSize messageSize;
            if (!self.message.removed.boolValue)
                messageSize = [ChatCell calcMessageHeight:_unicodeMessageText forScreenWidth:(self.frame.size.width - (2*TRAILING_SPACE + LEADING_SPACE + TRAILING_SPACE))];
            else
                messageSize = [ChatCell calcMessageHeight:stringDeletedeMessageText forScreenWidth:(self.frame.size.width - (2*TRAILING_SPACE + LEADING_SPACE + TRAILING_SPACE))];
            
            NSString* imgName = nil;
            //NSInteger streachCapWidth = 0;
            float bubbleXpos = TRAILING_SPACE;
            
            if(isHomeUserSender)
            {
                msgBaloonImg = self.baloonImageRight;
                
                bubbleXpos = self.frame.size.width - (messageSize.width + 2*TRAILING_SPACE + LEADING_SPACE + TRAILING_SPACE);
                
                if (message.edited.boolValue)
                {
                    // set header labels position
                    headerLabelXpos = self.frame.size.width  - rectEditedIcon.size.width - TRAILING_SPACE;
                    
                    rectEditedIcon.origin.x = headerLabelXpos;
                    
                    headerLabelXpos = headerLabelXpos - (lblChatMessageTimestamp.frame.size.width + rectEditedIcon.size.width) + 2*LEADING_SPACE;
                }
                else
                {
                    headerLabelXpos = self.frame.size.width  - lblChatMessageTimestamp.frame.size.width;
                }
                CGRect f = lblChatMessageTimestamp.frame;
                f.origin.x = headerLabelXpos;
                lblChatMessageTimestamp.frame = f;
                
                headerLabelXpos -= labelSeparator.frame.size.width;
                
                f = labelSeparator.frame;
                f.origin.x = headerLabelXpos;
                labelSeparator.frame = f;
                
                headerLabelXpos -= labelParticipant.frame.size.width;
                
                f = labelParticipant.frame;
                f.origin.x = headerLabelXpos;
                labelParticipant.frame = f;
                
                f = self.messageLabel.frame;
                f.origin.x = headerLabelXpos;
                self.messageLabel.frame = f;
            }
            else
            {
                msgBaloonImg = self.baloonImageLeft;
            }
            
            if (message.edited.boolValue)
                imageView.frame = rectEditedIcon;
            
            //Label message
            [self.messageLabel setFrame:CGRectMake(bubbleXpos + 15.0, 25.0, messageSize.width + 10.0, messageSize.height)];
            self.messageLabel.dataDetectorTypes = NSTextCheckingTypeLink;
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.font = [UIFont systemFontOfSize:14.0];
            self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            if (!self.message.removed.boolValue)
            {
                self.messageLabel.text = _unicodeMessageText;
                self.messageLabel.textColor = [UIColor blackColor];
            }
            else
            {
                self.messageLabel.text = stringDeletedeMessageText;
                self.messageLabel.textColor = textColor;
            }
            
            self.messageLabel.numberOfLines = 0;
            [self.messageLabel sizeToFit];
            
            float baloonViewH = messageSize.height + 34 < 52.0 ? 52.0 : messageSize.height + 34;
            
            

            UIImageView *msgBaloonView = [[UIImageView alloc] initWithFrame:CGRectMake(bubbleXpos, 20, messageSize.width + 30, baloonViewH)];
            
            [msgBaloonView setImage:msgBaloonImg];
            if (!self.message.removed.boolValue)
                [self.contentView addSubview:msgBaloonView];
            
            [self.contentView addSubview:self.messageLabel];
            [self.contentView addSubview:imageView];
            [self.contentView addSubview:labelParticipant];
            [self.contentView addSubview:labelSeparator];
            [self.contentView addSubview:lblChatMessageTimestamp];
            
            if (isHomeUserSender && !self.message.removed.boolValue)
                [self setMessageStatus];
        }
    }
}

- (void) setMessage:(HOPMessageRecord*) inMessage
{
    message = inMessage;
    
    if (!self.message.removed.boolValue)
    {
        self.messageLabel.textColor = [UIColor blackColor];
    }
    else
    {
        self.messageLabel.textColor = [UIColor grayColor];
    }
    
    if ([self.message.sender isSelf] && !self.message.removed.boolValue)
        [self setMessageStatus];
}

@end
