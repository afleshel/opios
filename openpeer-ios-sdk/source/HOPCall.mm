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


#import <openpeer/core/ICall.h>
#import <openpeer/core/IConversationThread.h>
#import <openpeer/core/IContact.h>
#import <openpeer/core/IHelper.h>

#import "HOPCall_Internal.h"
#import "OpenPeerUtility.h"
#import "HOPConversationThread_Internal.h"
#import "HOPContact_Internal.h"
#import "HOPRolodexContact_Internal.h"
#import "OpenPeerStorageManager.h"

#import "HOPCall.h"
#import "HOPContact.h"
#import "HOPModelManager.h"

ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

using namespace openpeer;
using namespace openpeer::core;

@implementation HOPCall


- (id) initWithCallPtr:(ICallPtr) inCallPtr
{
    self = [super init];
    if (self)
    {
        callPtr = inCallPtr;
    }
    return self;
}

+ (id) placeCall:(HOPConversationThread*) conversationThread toContact:(HOPContact*) toContact includeAudio:(BOOL) includeAudio includeVideo:(BOOL) includeVideo
{
    HOPCall* ret = nil;
    if (conversationThread != nil && toContact != nil)
    {
        //Create the core call object and start placing call procedure
        ICallPtr tempCallPtr = ICall::placeCall([conversationThread getConversationThreadPtr], [toContact getContactPtr], includeAudio, includeVideo);
        
        if (tempCallPtr)
        {
            //If core call object is create, create HOPCall object
            ret = [[self alloc] initWithCallPtr:tempCallPtr];
            [[OpenPeerStorageManager sharedStorageManager] setCall:ret forId:[NSString stringWithUTF8String:tempCallPtr->getCallID()]];
        }
        else
        {
            ZS_LOG_ERROR(Debug, "Call object is not created!");
        }
    }
    return ret;
}

+ (NSString*) stateToString: (HOPCallStates) state
{
    return [NSString stringWithUTF8String: ICall::toString((ICall::CallStates) state)];
}
+ (NSString*) stringForCallState:(HOPCallStates) state
{
    return [NSString stringWithUTF8String: ICall::toString((ICall::CallStates) state)];
}

+ (NSString*) reasonToString: (HOPCallClosedReasons) reason
{
    return [NSString stringWithUTF8String: ICall::toString((ICall::CallClosedReasons) reason)];
}
+ (NSString*) stringForClosingReason:(HOPCallClosedReasons) reason
{
    return [NSString stringWithUTF8String: ICall::toString((ICall::CallClosedReasons) reason)];
}

- (NSString*) getCallID
{
    NSString* callId = @"";
    if(callPtr)
    {
        callId = [NSString stringWithUTF8String: callPtr->getCallID()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call pointer!"];
    }
    return callId;
}

- (HOPConversationThread*) getConversationThread
{
    HOPConversationThread* hopConversationThread = nil;
    if(callPtr)
    {
        IConversationThreadPtr conversationThreaPtr = callPtr->getConversationThread();
        if (conversationThreaPtr)
        {
            hopConversationThread = [[OpenPeerStorageManager sharedStorageManager] getConversationThreadForId:[NSString stringWithUTF8String:conversationThreaPtr->getThreadID()]];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [self log:@"Invalid conversation thread object!"]);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call pointer!"];
    }
    
    return hopConversationThread;
}

- (HOPContact*) getCaller
{
    HOPContact* ret = nil;
    if(callPtr)
    {
        IContactPtr contactPtr = callPtr->getCaller();
        if (contactPtr)
        {
            NSString* peerURI = [NSString stringWithUTF8String:contactPtr->getPeerURI()];
            ret = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:peerURI];
            if (!ret)
                ret = [[HOPContact alloc] initWithCoreContact:contactPtr];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [self log:@"Invalid caller contact object!"]);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    return ret;
}

- (HOPContact*) getCallee
{
    HOPContact* ret = nil;
    if(callPtr)
    {
        IContactPtr contactPtr = callPtr->getCallee();
        if (contactPtr)
        {
            NSString* peerURI = [NSString stringWithUTF8String:contactPtr->getPeerURI()];
            ret = [[OpenPeerStorageManager sharedStorageManager] getContactForPeerURI:peerURI];
            if (!ret)
                ret = [[HOPContact alloc] initWithCoreContact:contactPtr];
        }
        else
        {
            ZS_LOG_ERROR(Debug, [self log:@"Invalid callee contact object!"]);
        }
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    return ret;
}

- (BOOL) hasAudio
{
    BOOL ret = NO;
    if(callPtr)
    {
        ret = callPtr->hasAudio();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    
    return ret;
}

- (BOOL) hasVideo 
{
    BOOL ret = NO;
    if(callPtr)
    {
        ret = callPtr->hasVideo();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    
    return ret;
}

- (HOPCallStates) getState
{
    HOPCallStates hopCallStates = HOPCallStateNone;
    if(callPtr)
    {
        hopCallStates = (HOPCallStates)callPtr->getState();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    
    return hopCallStates;
}


- (HOPCallClosedReasons) getClosedReason
{
    HOPCallClosedReasons hopCallClosedReasons = HOPCallClosedReasonNone;
    if(callPtr)
    {
        hopCallClosedReasons = (HOPCallClosedReasons)callPtr->getClosedReason();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    
    return hopCallClosedReasons;
}


- (NSDate*) getCreationTime
{
    NSDate* date = nil;
    
    if(callPtr)
    {
        date = [OpenPeerUtility convertPosixTimeToDate:callPtr->getcreationTime()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    return date;
}

- (NSDate*) getRingTime
{
    NSDate* date = nil;
    
    if(callPtr)
    {
        date = [OpenPeerUtility convertPosixTimeToDate:callPtr->getRingTime()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    return date;
}

- (NSDate*) getAnswerTime
{
    NSDate* date = nil;
    
    if(callPtr)
    {
        date = [OpenPeerUtility convertPosixTimeToDate:callPtr->getAnswerTime()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    return date;
}


- (NSDate*) getClosedTime
{
    NSDate* date = nil;
    
    if(callPtr)
    {
        date = [OpenPeerUtility convertPosixTimeToDate:callPtr->getClosedTime()];
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
    return date;
}

- (void) ring
{
    if(callPtr)
    {
        callPtr->ring();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
}

- (void) answer
{
    if(callPtr)
    {
        callPtr->answer();
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
}


- (void) hold:(BOOL) hold
{
    if(callPtr)
    {
        callPtr->hold(hold);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
}


- (void) hangup:(HOPCallClosedReasons) reason
{
    if(callPtr)
    {
        callPtr->hangup((ICall::CallClosedReasons)reason);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Invalid call object!"]);
        [NSException raise:NSInvalidArgumentException format:@"Invalid call object!"];
    }
}

- (void) destroyCoreObject
{
    if(callPtr)
        callPtr.reset();
}

-(NSString *)description
{
    return [NSString stringWithUTF8String: IHelper::convertToString(ICall::toDebug([self getCallPtr]))];
}

#pragma mark - Internal methods
- (ICallPtr) getCallPtr
{
    return callPtr;
}

- (String) log:(NSString*) message
{
    if (callPtr)
        return String("HOPCall [") + string(callPtr->getID()) + "] " + [message UTF8String];
    else
        return String("HOPCall: ") + [message UTF8String];
}
@end
