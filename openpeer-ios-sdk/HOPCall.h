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

#import <Foundation/Foundation.h>
#import "HOPTypes.h"

@class HOPConversationThread;
@class HOPContact;
@class HOPRolodexContact;

@interface HOPCall : NSObject

/**
 Creates outgoing call.
 @param conversationThread HOPConversationThread Thread which will own the call
 @param toContact HOPContact Remote contact
 @param includeAudio BOOL YES if call should include audio
 @param includeVideo BOOL YES if call should include video
 @returns HOPCall object if ICallPtr object is created sucessfully, otherwise nil
 */
+ (id) placeCall:(HOPConversationThread*) conversationThread toContact:(HOPContact*) toContact includeAudio:(BOOL) includeAudio includeVideo:(BOOL) includeVideo;
- (id) init __attribute__((unavailable("Use static placeCall:toContact:includeAudio:includeVideo method to create a call object.")));

/**
 Converts call state enum to string
 @param state HOPCallStates Call state enum
 @returns String representation of call state
 */
+ (NSString*) stateToString: (HOPCallStates) state __attribute__((deprecated("use method stringForCallState instead")));
+ (NSString*) stringForCallState:(HOPCallStates) state;

/**
 Converts call closed reason enum to string
 @param reason HOPCallClosedReasons Call closed reason enum
 @returns String representation of call closed reason enum
 */
+ (NSString*) reasonToString: (HOPCallClosedReasons) reason __attribute__((deprecated("use method stringForClosingReason instead")));
+ (NSString*) stringForClosingReason:(HOPCallClosedReasons) reason;

/**
 Retrieves call ID
 @returns String representation of call ID
 */
- (NSString*) getCallID;

/**
 Retrieves conversation thread which owns the call
 @returns Pointer to the conversation thread object
 */
- (HOPConversationThread*) getConversationThread;

/**
 Retrieves caller contact
 @returns Pointer to the caller contact object
 */
- (HOPContact*) getCaller;

/**
 Retrieves callee contact
 @returns Pointer to the callee contact object
 */
- (HOPContact*) getCallee;

/**
 Check if call has audio stream
 @returns YES if call has audio stream
 */
- (BOOL) hasAudio;

/**
 Check if call has video stream
 @returns YES if call has video stream
 */
- (BOOL) hasVideo;

/**
 Retrieves call state
 @returns Call state enum
 */
- (HOPCallStates) getState;

/**
 Retrieves call closed reason
 @returns Call closed reason enum
 */
- (HOPCallClosedReasons) getClosedReason;

/**
 Retrieves call creation time.
 @returns NSDate representation of call creation time
 */
- (NSDate*) getCreationTime;

/**
 Retrieves call ring time.
 @returns NSDate representation of call ring time
 */
- (NSDate*) getRingTime;

/**
 Retrieves call answer time.
 @returns NSDate representation of call answer time
 */
- (NSDate*) getAnswerTime;

/**
 Retrieves call closed time.
 @returns NSDate representation of call closed time
 */
- (NSDate*) getClosedTime;

/**
 Start ringing.
 */
- (void) ring;

/**
 Answer incoming call.
 */
- (void) answer;

/**
 Set call hold ON/OFF.
 @param YES to hold the call, NO to unhold
 */
- (void) hold:(BOOL) hold;

/**
 Ends current call.
 @param HOPCallClosedReasons Reason for call closure.
 */
- (void) hangup:(HOPCallClosedReasons) reason;

/**
 Destroy core object.
 */
- (void) destroyCoreObject;
@end
