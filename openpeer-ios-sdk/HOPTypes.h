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

#ifndef openpeer_ios_sdk_OpenPeerTypes_h
#define openpeer_ios_sdk_OpenPeerTypes_h

#pragma mark - HOPCall enums
/**
 *  Call states.
 */
typedef enum 
{
    HOPCallStateNone,       // call has no state yet
    HOPCallStatePreparing,  // call is negotiating in the background - do not present this call to a user yet...
    HOPCallStateIncoming,   // call is incoming from a remote party
    HOPCallStatePlaced,     // call has been placed to the remote party
    HOPCallStateEarly,      // call is outgoing to a remote party and is receiving early media (media before being answered)
    HOPCallStateRinging,    // call is incoming from a remote party and is ringing
    HOPCallStateRingback,   // call is outgoing to a remote party and remote party is ringing
    HOPCallStateOpen,       // call is open
    HOPCallStateActive,     // call is open, and participant is actively communicating
    HOPCallStateInactive,   // call is open, and participant is inactive
    HOPCallStateHold,       // call is open but on hold
    HOPCallStateClosing,    // call is hanging up
    HOPCallStateClosed,     // call has ended
} HOPCallState;

/**
 *  Ending call reasons.
 */
typedef enum
{
    HOPCallClosedReasonNone                     = 0,
    
    HOPCallClosedReasonUser                     = 200,
    
    HOPCallClosedReasonRequestTimeout           = 408,
    HOPCallClosedReasonTemporarilyUnavailable   = 480,
    HOPCallClosedReasonBusy                     = 486,
    HOPCallClosedReasonRequestTerminated        = 487,
    HOPCallClosedReasonNotAcceptableHere        = 488,
    
    CallClosedReasonServerInternalError      = 500,
    
    CallClosedReasonDecline                  = 603,
} HOPCallClosingReason;

#pragma mark - HOPConversationThread enums

/**
 *  Message delivery states.
 */
typedef enum 
{
    HOPConversationThreadMessageDeliveryStateDiscovering      = 0,
    HOPConversationThreadMessageDeliveryStateUserNotAvailable = 1,
    HOPConversationThreadMessageDeliveryStateSent             = 2,
    HOPConversationThreadMessageDeliveryStateDelivered        = 3,
    HOPConversationThreadMessageDeliveryStateRead             = 4,
} HOPConversationThreadMessageDeliveryState;

/**
 *  Thread's contact states.
 */
typedef enum 
{
    HOPConversationThreadContactConnectionStateNotApplicable,
    HOPConversationThreadContactConnectionStateFinding,
    HOPConversationThreadContactConnectionStateConnected,
    HOPConversationThreadContactConnectionStateDisconnected
} HOPConversationThreadContactConnectionState;

/**
 *  Thread's contact statuses.
 */
typedef enum
{
    HOPComposingStateNone,      // contact has no composing status
    
    HOPComposingStateInactive,  // contact is not actively participating in conversation (assumed default if "none")
    HOPComposingStateActive,    // contact is active in the conversation
    HOPComposingStateGone,      // contact is effectively gone from conversation
    HOPComposingStateComposing, // contact is composing a message
    HOPComposingStatePaused    // contact was composing a message but is no longer composing
} HOPConversationThreadContactStatus;

typedef enum
{
    HOPConversationThreadTypeNone,
    
    HOPConversationThreadTypeContactBased,
    HOPConversationThreadTypeThreadBased,
    HOPConversationThreadTypeRoomBased
} HOPConversationThreadType;

typedef enum
{
    HOPSystemMessageTypeNA,           // not a system message
    HOPSystemMessageTypeUnknown,      // unknown system message type
    
    HOPSystemMessageTypeCall,   // call system message
} HOPSystemMessageType;

typedef enum
{
    HOPCallSystemMessageTypeUnknown,      // unknown system message type
    
    HOPCallSystemMessageTypeCallPlaced,   // call was placed
    HOPCallSystemMessageTypeCallAnswered, // call was answered
    HOPCallSystemMessageTypeCallHungup,   // call was hung-up
} HOPCallSystemMessageType;
#pragma mark - Provisioning account for future use enum
/**
 Account states.
 */
typedef enum 
{
    HOPAccountStatePending,
    HOPAccountPendingPeerFilesGeneration,
    HOPAccountWaitingForAssociationToIdentity,
    HOPAccountWaitingForBrowserWindowToBeLoaded,
    HOPAccountWaitingForBrowserWindowToBeMadeVisible,
    HOPAccountWaitingForBrowserWindowToClose,
    HOPAccountStateReady,
    HOPAccountStateShuttingDown,
    HOPAccountStateShutdown,
} HOPAccountState;

#pragma mark - HOPIdentity enums
/**
 *  Identity state.
 */
typedef enum
{
    HOPIdentityStatePending,
    HOPIdentityStatePendingAssociation,
    HOPIdentityStateWaitingAttachmentOfDelegate,
    HOPIdentityStateWaitingForBrowserWindowToBeLoaded,
    HOPIdentityStateWaitingForBrowserWindowToBeMadeVisible,
    HOPIdentityStateWaitingForBrowserWindowToClose,
    HOPIdentityStateReady,
    HOPIdentityStateShutdown
} HOPIdentityState;


#pragma mark - HOPClientLog enums
/**
 *  Log severities.
 */
typedef enum
{
    HOPLoggerSeverityInformational,
    HOPLoggerSeverityWarning,
    HOPLoggerSeverityError,
    HOPLoggerSeverityFatal
} HOPLoggerSeverity;

typedef enum
{
    HOPLoggerLevelNone,
    HOPLoggerLevelBasic,
    HOPLoggerLevelDetail,
    HOPLoggerLevelDebug,
    HOPLoggerLevelTrace,
    HOPLoggerLevelInsane,

    HOPLoggerTotalNumberOfLevels
} HOPLoggerLevel; //Replacing HOPClientLogSeverities

#pragma mark - Client enums
typedef enum 
{
    HOPContactTypeOpenPeer,
    HOPContactTypeExternal
} HOPContactType;

#pragma mark - HOPMediaEngine enums
typedef enum 
{
    HOPMediaEngineCameraTypeNone,
    HOPMediaEngineCameraTypeFront,
    HOPMediaEngineCameraTypeBack
} HOPMediaEngineCameraType;

typedef enum
{
    HOPMediaEngineVideoOrientationLandscapeLeft,
    HOPMediaEngineVideoOrientationPortraitUpsideDown,
    HOPMediaEngineVideoOrientationLandscapeRight,
    HOPMediaEngineVideoOrientationPortrait
} HOPMediaEngineVideoOrientation;

typedef enum
{
    HOPMediaEngineOutputAudioRouteHeadphone,
    HOPMediaEngineOutputAudioRouteBuiltInReceiver,
    HOPMediaEngineOutputAudioRouteBuiltInSpeaker
} HOPMediaEngineOutputAudioRoute;
#endif
