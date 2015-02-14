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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HOPConversationEvent, HOPConversationRecord, HOPMessageEvent, HOPContact;

@interface HOPMessageRecord : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * removed;
@property (nonatomic, retain) NSNumber * edited;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSNumber * incomingMessageStatus;
@property (nonatomic, retain) NSString * messageID;
@property (nonatomic, retain) NSString * outMessageStatus;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * showStatus;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * visible;
@property (nonatomic, retain) NSNumber * validated;
@property (nonatomic, retain) NSString * replacedMessageID;
@property (nonatomic, retain) HOPConversationEvent *conversationEvent;
@property (nonatomic, retain) NSSet *messageEvent;
@property (nonatomic, retain) HOPContact *sender;
@property (nonatomic, retain) HOPConversationRecord *session;
@end

@interface HOPMessageRecord (CoreDataGeneratedAccessors)

- (void)addMessageEventObject:(HOPMessageEvent *)value;
- (void)removeMessageEventObject:(HOPMessageEvent *)value;
- (void)addMessageEvent:(NSSet *)values;
- (void)removeMessageEvent:(NSSet *)values;

@end
