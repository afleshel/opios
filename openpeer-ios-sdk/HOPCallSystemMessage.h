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
#import "HOPTypes.h"
#import "HOPSystemMessage.h"

@class HOPCoreContact;
@class HOPIdentity;

@interface HOPCallSystemMessage : HOPSystemMessage <NSCopying>

@property (nonatomic) HOPCallSystemMessageType messageType;
@property (nonatomic,weak) HOPCoreContact* callee;
@property (nonatomic) unsigned short errorCode;
@property (nonatomic, copy) NSString* jsonMessage;
@property (nonatomic, copy) NSString* mediaType;
@property (nonatomic, copy) NSString* callID;

- (id) initWithMessageType:(HOPCallSystemMessageType) inType callee:(HOPIdentity*) inCallee errorCode:(unsigned short) inErrorCode;
- (id) initWithMessageType:(HOPCallSystemMessageType) inType mediaType:(NSString*) mediaType callID:(NSString*) callID callee:(HOPIdentity*) inCallee errorCode:(unsigned short) inErrorCode;

+ (id) callSystemMessageFromJSON:(NSString*) jsonMessage;

+ (NSString*) stringForMessageType:(HOPCallSystemMessageType) messageType;
+ (HOPCallSystemMessageType) messageTypeForString: (NSString*) messageTypeString;

- (BOOL) hasData;

@end
