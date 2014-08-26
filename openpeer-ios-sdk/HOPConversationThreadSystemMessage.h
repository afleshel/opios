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

@class HOPContact;
@class HOPConversationThread;
@class HOPMessage;

@interface HOPConversationThreadSystemMessage : NSObject


+ (NSString*) stringForSystemMessageTypes:(HOPSystemMessageType) type;
+ (HOPSystemMessageType) systemMessageTypeFromString:(NSString*) type;

/**
 *  Get the system message type
 *
 *  @return The system message mime type
 */
+ (NSString*) getMessageType;


/**
 *  Creates a system message related to the "call" system message types.
 *
 *  @param type      System message type
 *  @param callee    Callee contact
 *  @param errorCode Optional HTTP style error code (can cast as WORD from ICall::CallClosedReasons
 *
 *  @return JSON element to send as a message
 */
+ (HOPMessage*) createSystemCallMessageForType:(HOPSystemMessageType) type callee:(HOPContact*) callee errorCode:(uint) errorCode;


/**
 *  Given a message and message type, attempt to parse as a system message.
 *
 *  @param message message to parse
 *
 *  @return SystemMessageType_NA - if message is not a system message, SystemMessageType_Unknown - if message is a system message but is not understood,outSystemMessage - JSON structure containing system message information that needs parsing
 */
+ (HOPSystemMessageType) parseSystemMessage:(HOPMessage*) message;



//-----------------------------------------------------------------------
// PURPOSE: Given a JSON system message extract the call information
// RETURNS: outCallee - the callee contact
//          outErrorCode - HTTP style error code
//static void getCallMessageInfo(
//                               IConversationThreadPtr inRelatedConversationThread,
//                               ElementPtr inSystemMessage,
//                               IContactPtr &outCallee,
//                               WORD &outErrorCode
//                               );
@end
