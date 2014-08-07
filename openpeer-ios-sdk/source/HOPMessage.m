/*
 
 Copyright (c) 2012, SMB Phone Inc.
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

#import "HOPMessage.h"
#import "HOPContact.h"

@implementation HOPMessage

@synthesize messageID = _messageID;
@synthesize replacesMessageID = _replacesMessageID;
@synthesize contact = _contact;
@synthesize type = _type;
@synthesize text = _text;
@synthesize date = _date;
@synthesize validated = _validated;


- (id) initWithMessageId:(NSString*) inMessageId andReplacesMessageID:(NSString*) inReplacesMessageID andMessage:(NSString*) messageText andContact:(HOPContact*) inContact andMessageType:(NSString*) inMessageType andMessageDate:(NSDate*) inMessageDate  andValidated:(BOOL) inValidated
{
    self = [super init];
    if (self)
    {
        self.messageID = inMessageId;
        self.replacesMessageID = inReplacesMessageID;
        self.text = messageText;
        self.contact = inContact;
        self.type = inMessageType;
        self.date = inMessageDate;
        self.validated = inValidated;
    }
    return self;
}

@end
