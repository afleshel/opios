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

#import "SystemMessageCell.h"
#import <OpenPeerSDK/HOPCallSystemMessage.h>
#import <OpenPeerSDK/HOPMessage.h>
#import "TTTAttributedLabel.h"
#import "Utility.h"
#import "SessionManager.h"

#define SYSTEM_MESSAGE_FONT_TYPE  @"Arial"
#define SYSTEM_MESSAGE_FONT_SIZE  11.0
#define SPACE_BETWEEN_LABEL  5

@interface SystemMessageCell()

@property (nonatomic, copy) NSString* messageText;
@property (nonatomic, strong) HOPCallSystemMessage* callSystemMessage;
@end



@implementation SystemMessageCell

//@synthesize message;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void) setMessage:(HOPMessage*) inMessage
{
    [super setMessage:inMessage];
    //message = inMessage;
    
    if ([inMessage.type isEqualToString:[HOPSystemMessage getMessageType]])
    {
        self.callSystemMessage = [HOPCallSystemMessage callSystemMessageFromJSON:inMessage.text];
        self.messageText = [[SessionManager sharedSessionManager] getSystemMessage:self.message];
    }
}

- (void) drawRect:(CGRect)rect
{
    self.backgroundColor = [UIColor clearColor];
    
    for(UIView *v in self.subviews)
    {
        [v removeFromSuperview];
    }

    // add message
    CGSize sizeOfTheMessage = [self.messageText sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:SYSTEM_MESSAGE_FONT_TYPE size:SYSTEM_MESSAGE_FONT_SIZE]}];

    CGRect f = CGRectMake(5, 10, sizeOfTheMessage.width + 2, sizeOfTheMessage.height + 2);//lblSystemMessage.frame;
    f.origin.x = roundf((self.frame.size.width - f.size.width)/2);

    // add image(if need it)
    NSString *imgPath = nil;

    switch (self.callSystemMessage.messageType)
    {
        case HOPCallSystemMessageTypeCallPlaced:
          imgPath = @"message_indicator_call_started.png";
          break;
        case HOPCallSystemMessageTypeCallHungup:
          imgPath = @"message_indicator_call_ended.png";
          break;
        default:
          break;
    }

    float textX = 0;
    float imgX = 0;
    // add line
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    CGContextSetShouldAntialias(context, NO);
    // draw image
    if(imgPath)
    {
        NSRange r = [imgPath rangeOfString:@"." options:NSBackwardsSearch];
        if(r.location != NSNotFound)
        {
            imgPath = [imgPath substringToIndex:r.location];
        }

        NSData *imgData = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imgPath ofType:@"png"]];
        UIImage *img = [[UIImage alloc] initWithData:imgData];

        imgX = (self.frame.size.width - (img.size.width + sizeOfTheMessage.width + 3*SPACE_BETWEEN_LABEL))/2.0 + SPACE_BETWEEN_LABEL;
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0, img.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, CGRectMake(imgX, -8, img.size.width, img.size.height), img.CGImage);
        CGContextRestoreGState(context);
        
        textX = imgX + img.size.width + SPACE_BETWEEN_LABEL;
    }


    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:89/255.0 green:125/255.0 blue:136/255.0 alpha:1.0].CGColor);
    CGContextMoveToPoint(context, 0, 18);
    CGContextAddLineToPoint(context, imgX - SPACE_BETWEEN_LABEL, 18);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, textX + sizeOfTheMessage.width + SPACE_BETWEEN_LABEL, 18);
    CGContextAddLineToPoint(context, self.frame.size.width, 18);
    CGContextStrokePath(context);

    if ([self.messageText length] > 0)
    {
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:SYSTEM_MESSAGE_FONT_TYPE size:SYSTEM_MESSAGE_FONT_SIZE], NSFontAttributeName,[UIColor whiteColor], NSForegroundColorAttributeName, nil];
        
        NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:self.messageText attributes: attributes];
        
        [currentText drawAtPoint:CGPointMake(textX ,10.0)];
    }
}


@end
