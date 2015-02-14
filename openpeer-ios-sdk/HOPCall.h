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
@class HOPConversation;
@class HOPContact;


@interface HOPCall : NSObject

/**
 Creates outgoing call.
 @param conversationThread Thread which will own the call
 @param includeAudio BOOL YES if call should include audio
 @param includeVideo BOOL YES if call should include video
 @return HOPCall object if ICallPtr object is created sucessfully, otherwise nil
 */
+ (id) placeCall:(HOPConversationThread*) conversationThread includeAudio:(BOOL) includeAudio includeVideo:(BOOL) includeVideo;

+ (id) placeCallForConversation:(HOPConversation*) conversation includeAudio:(BOOL) includeAudio includeVideo:(BOOL) includeVideo;
+ (id) placeCallForConversation:(HOPConversation*) conversation partcipants:(NSArray*) participants includeAudio:(BOOL) includeAudio includeVideo:(BOOL) includeVideo;
/**
 *  This init method is not available. You need to use class method placeCall:toContact:includeAudio:includeVideo.
 *
 */
- (id) init __attribute__((unavailable("Use static placeCall:toContact:includeAudio:includeVideo method to create a call object.")));

/**
 Converts call state enum to string.
 @param state Call state
 @return A string representation of call state.
 */
+ (NSString*) stateToString: (HOPCallState) state __attribute__((deprecated("use method stringForCallState instead")));

/**
 *  Converts call state enum to string. (Deprecated)
 *
 *  @param state Call state
 *
 *  @return A string representation of call state.
 */
+ (NSString*) stringForCallState:(HOPCallState) state;

/**
 Converts call closed reason enum to string. (Deprecated)
 @param reason Call closed reason enum
 @return A String representation of call closed reason enum
 */
+ (NSString*) reasonToString: (HOPCallClosingReason) reason __attribute__((deprecated("use method stringForClosingReason instead")));

/**
 Converts call closed reason enum to string.
 @param reason Call closed reason enum
 @return A String representation of call closed reason enum
 */
+ (NSString*) stringForClosingReason:(HOPCallClosingReason) reason;

/**
 Returns call ID.
 @return A string representation of call ID
 */
- (NSString*) getCallID;

/**
 Returns conversation thread which owns the call
 @return Pointer to the conversation thread object
 */
- (HOPConversationThread*) getConversationThread;

/**
 *  Returns conversation which owns the call
 *
 *  @return Conversation thread object
 */
- (HOPConversation*) getConversation;

/**
 Returns caller contact.
 @return Pointer to the caller HOPIdentity object
 */
- (HOPContact*) getCaller;

/**
 Returns callee contact.
 @return Pointer to the callee HOPIdentity object
 */
- (HOPContact*) getCallee;

/**
 Checks if call has audio stream.
 @return YES if call has audio stream, otherwise NO
 */
- (BOOL) hasAudio;

/**
 Checks if call has a video stream.
 @return YES if call has video stream, otherwise NO
 */
- (BOOL) hasVideo;

/**
 Returns call state.
 @return Call state enum
 */
- (HOPCallState) getState;

/**
 Returns call closed reason.
 @return Call closed reason enum
 */
- (HOPCallClosingReason) getClosedReason;

/**
 Returns call creation time.
 @returns Call creation time
 */
- (NSDate*) getCreationTime;

/**
 Returns call ring time.
 @returns Call ring time
 */
- (NSDate*) getRingTime;

/**
 Retrieves call answer time.
 @returns Call answer time
 */
- (NSDate*) getAnswerTime;

/**
 Retrieves call closed time.
 @returns Call closing time
 */
- (NSDate*) getClosedTime;

/**
 Starts ringing.
 */
- (void) ring;

/**
 Answers on incoming call.
 */
- (void) answer;

/**
 Sets call hold ON/OFF.
 @param YES to hold the call, NO to unhold
 */
- (void) hold:(BOOL) hold;

/**
 Ends current call.
 @param Call closure reason.
 */
- (void) hangup:(HOPCallClosingReason) reason;

/**
 Destroya call core object.
 */
- (void) destroyCoreObject;

- (BOOL) isOutgoing;
@end
