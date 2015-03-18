/*
 
 Copyright (c) 2014, Hookflash Inc.
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

#import "ChatCell.h"
#import "Utility.h"
#import <OpenPeerSDK/HOPMessage.h>
#import <OpenPeerSDK/HOPContact+External.h>

@implementation ChatCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.chatNameFont =  [UIFont fontWithName:@"Helvetica-Bold" size:9.0];
        self.chatTimestampFont = [UIFont fontWithName:@"Helvetica" size:9.0];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGSize) calcMessageHeight:(NSString *)message forScreenWidth:(float)width
{
    CGSize maxSize = {width, 200000.0};
    
    CGSize calcSize = [message boundingRectWithSize: maxSize options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: [UIFont systemFontOfSize:14.0] } context: nil].size;
    return calcSize;
}

- (void)setMessage:(HOPMessage *)inMessage
{
    _message = inMessage;
    
    BOOL isHomeUserSender = [inMessage.sender isSelf];
    
//    if (self.senderLabel)
//    {
//        NSString* sender  = [NSString stringWithFormat:@"%@ | %@",[inMessage.sender getName],[Utility formatedMessageTimeStampForDate:inMessage.date]];
//        [self.senderLabel setFont:self.chatNameFont];
//        [self.senderLabel setText:sender];
//    }
    
//    if (isHomeUserSender)
//    {
//        
//    }
}
@end
