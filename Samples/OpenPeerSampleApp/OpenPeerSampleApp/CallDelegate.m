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

#import "CallDelegate.h"
#import "OpenPeer.h"
#import <OpenpeerSDK/HOPCall.h>
#import <OpenpeerSDK/HOPTypes.h>
#import <OpenpeerSDK/HOPConversationThread.h>
#import "SessionManager.h"
#import "MessageManager.h"
#import "SoundsManager.h"

#import "Session.h"
#import "MainViewController.h"
#import "SessionViewController_iPhone.h"
#import "Utility.h"

@implementation CallDelegate

- (void) onCallStateChanged:(HOPCall*) call callState:(HOPCallStates) callState
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"Call state: %@", [Utility getCallStateAsString:[call getState]]);
    
    NSString* sessionId = [[call getConversationThread] getThreadId];
    dispatch_async(dispatch_get_main_queue(), ^{

        SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:sessionId];
        
        [sessionViewController updateCallState];
        
        switch (callState)
        {
            case HOPCallStatePreparing:             //Receives both parties, caller and callee.
                [[SessionManager sharedSessionManager] onCallPreparing:call];
                break;
                
            case HOPCallStateIncoming:              //Receives just callee
                [[SessionManager sharedSessionManager] onCallIncoming:call];
                break;
                
            case HOPCallStatePlaced:                //Receives just calller
                break;
                
            case HOPCallStateEarly:                 //Currently is not in use
                break;
                
            case HOPCallStateRinging:               //Receives just callee side. Now should play ringing sound
                [[SoundManager sharedSoundsManager] playRingingSound];
                break;
                
            case HOPCallStateRingback:              //Receives just caller side
                [[SoundManager sharedSoundsManager] playCallingSound];
                break;
                
            case HOPCallStateOpen:                  //Receives both parties. Call is established
                [[SoundManager sharedSoundsManager] stopCallingSound];
                [[SoundManager sharedSoundsManager] stopRingingSound];
                [[SessionManager sharedSessionManager] onCallOpened:call];
                [sessionViewController startTimer];
                break;
                
            case HOPCallStateActive:                //Currently not in use
                break;
                
            case HOPCallStateInactive:              //Currently not in use
                break;
                
            case HOPCallStateHold:                  //Receives both parties
                break;
                
            case HOPCallStateClosing:               //Receives both parties
                [[SessionManager sharedSessionManager] onCallClosing:call];
                [[SoundManager sharedSoundsManager] stopCallingSound];
                [[SoundManager sharedSoundsManager] stopRingingSound];
                [sessionViewController stopTimer];
                break;
                
            case HOPCallStateClosed:                //Receives both parties
                [[SessionManager sharedSessionManager] onCallEnded:call];
                break;
                
            case HOPCallStateNone:
            default:
                break;
        }
    });

}
@end
