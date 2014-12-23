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

#import "SessionManager.h"
#import "ContactsManager.h"
#import "MainViewController.h"
#import "MessageManager.h"
#import "SessionViewController_iPhone.h"
#import "SoundsManager.h"
#import "Utility.h"
//#import "Session.h"
#import "OpenPeer.h"
#import "AppConsts.h"

#import <OpenpeerSDK/Openpeer.h>
//#import <OpenpeerSDK/HOPConversationEvent+External.h>
#import <OpenpeerSDK/HOPConversationRecord+External.h>
#import <OpenpeerSDK/HOPConversation.h>
#import "UIDevice+Networking.h"

@interface SessionManager()

@property (nonatomic, assign) HOPConversation* conversationWithActiveCall;

- (id) initSingleton;
- (BOOL) setActiveCallConversation:(HOPConversation*) inConversation callActive:(BOOL) callActive;
- (NSString*) getTitleForConversationThread:(HOPConversationThread*) conversationThread;
@end

@implementation SessionManager

/**
 Retrieves singleton object of the Login Manager.
 @return Singleton object of the Login Manager.
 */
+ (id) sharedSessionManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

/**
 Initialize singleton object of the Login Manager.
 @return Singleton object of the Login Manager.
 */
- (id) initSingleton
{
    self = [super init];
    if (self)
    {
        self.sessionsDictionary = [[NSMutableDictionary alloc] init];
        self.conversationsDictionaryForContacts = [[NSMutableDictionary alloc] init];
    }
    return self;
}



/**
 Get active session for contact.
 @param contacts HOPRolodexContact One of the participants.
 @return session with participant
*/
- (HOPConversation*) getConversationForContacts:(NSArray*) contacts
{
    for (HOPConversation* conversation in [self.sessionsDictionary allValues])
    {
        NSSet *set1 = [NSSet setWithArray:conversation.participants];
        NSSet *set2 = [NSSet setWithArray:contacts];
        
        if ([set1 isEqualToSet:set2])
            return conversation;
    }
    return nil;
}

- (HOPConversation*) getSessionForSessionId:(NSString*) sessionId
{
    return [self.sessionsDictionary objectForKey:sessionId];
}

- (HOPConversation*) getSessionForConversationEvent:(HOPConversationEvent*) event
{
    for (HOPConversation* conversation in [self.sessionsDictionary allValues])
    {
        if (conversation.lastEvent == event)
            return conversation;
    }
    return nil;
}


/**
 Make call for session.
 @param inSession Session session.
 @param includeVideo BOOL If YES make video call
 @param isRedial BOOL If trying to reestablish call that was ended because of network problems 
 */
- (void) makeCallForConversation:(HOPConversation*) inConversation includeVideo:(BOOL) includeVideo isRedial:(BOOL) isRedial;
{
    if ([UIDevice isNetworkReachable])
    {
        if (!inConversation.activeCall)
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Making a call for the session <%p>", inConversation);
            
            [[MessageManager sharedMessageManager] sendCallSystemMessage:HOPCallSystemMessageTypeCallPlaced reasonCode:0 forConversation:inConversation];
            
            //Place a audio or video call for chosen contact
            //inSession.isRedial = isRedial;
            inConversation.activeCall = [HOPCall placeCallForConversation:inConversation includeAudio:YES includeVideo:includeVideo];
            [self setActiveCallConversation:inConversation callActive:YES];
        }
        else
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Call is already in a progress");
        }
    }
    else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:[NSString stringWithFormat:@"Unable to establich call because of network issue. Please, check your internet connection."] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
}

/**
 Answer an incoming call
 @param inSession Session session.
 */
- (void) answerCallForConversation:(HOPConversation*) inConversation;
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Answer a call for the session <%p>", inConversation);
    //Answer an incoming call
    [inConversation.activeCall answer];
}

/**
 Ends current call for sesion.
 @param inSession Session session.
 */
- (void) endCallForConversation:(HOPConversation*) inConversation
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"End the call for the session <%p>", inConversation);
    //Hangup current active call
    [inConversation.activeCall hangup:HOPCallClosedReasonUser];
    //Set flag that there is no active call
    [self setActiveCallConversation:inConversation callActive:NO];
}

/**
 Handles preparing call state. At this state while clients negotiations are not completed, call  should not be yet presented to the user. In this sample, because of demonstration and easier state changes trcking, it is shown session ciew controller.  
 @param call HOPCall Incomin call
 */
- (void) onCallPreparing:(HOPCall*) call
{
    // NSString* sessionId = [[call getConversationThread] getThreadId];
    HOPConversation* conversation = [call getConversation];

    SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:[conversation getID]];
    
    if ([[call getCaller] isSelf])
    {
        if ([call hasVideo])
            [sessionViewController showWaitingView:YES];
        else
            [sessionViewController showCallViewControllerWithVideo:NO];
    }

    //Stop recording if it is placed and remove recording button
    //[sessionViewController stopVideoRecording:YES hideRecordButton:YES];
}

/**
 Handle incoming call.
 @param call HOPCall Incomin call
 @param inSession Session session.
 */
- (void) onCallIncoming:(HOPCall*) call
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Handle incoming call <%p>", call);
    HOPConversation* conversation = [call getConversation];
//    NSString* sessionId = [[call getConversationThread] getThreadId];
//    Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
//    
//    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Incoming a call for the session <%p>", session);
    
    //Set current call
    //BOOL callFlagIsSet = [self setActiveCallSession:session callActive:YES];
    
    //If callFlagIsSet is YES, show incoming call view, and move call to ringing state
    if (![self isCallInProgress])
    {
        conversation.activeCall = call;
        
        if (!conversation.redialCall)
        {
            //[[[OpenPeer sharedOpenPeer] mainViewController] showIncominCallForSession:session];
            //If it is an incomming call, get show session view controller
            if (![[call getCaller] isSelf])
            {
                [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:conversation forIncomingCall:YES forIncomingMessage:NO];
            }
            [call ring];
        }
        else
            [call answer];
        
        [self setActiveCallConversation:conversation callActive:YES];
    }
    else //If callFlagIsSet is NO, hangup incoming call. 
    {
        [call hangup:HOPCallClosedReasonBusy];
        [[[OpenPeer sharedOpenPeer] mainViewController] showNotification:[NSString stringWithFormat:@"%@ is busy.",[[conversation.participants objectAtIndex:0] name]]];
    }
}

- (void) onCallRinging:(HOPCall*) call
{
//    NSString* sessionId = [[call getConversationThread] getThreadId];
//    if ([sessionId length] > 0)
    {
        //Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
        HOPConversation* conversation = [call getConversation];
        if (conversation)
        {
            [[[OpenPeer sharedOpenPeer] mainViewController] showIncominCallForConversation:conversation];
            [[SoundManager sharedSoundsManager] playRingingSound];
        }
    }
}

/**
 Handle case when call is esablished and active.
 @param call HOPCall Incomin call
 @param inSession Session session.
 */
- (void) onCallOpened:(HOPCall*) call
{
     SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:[[call getConversation] getID]];
    
    [sessionViewController showIncomingCall:NO];
    [sessionViewController showCallViewControllerWithVideo:[call hasVideo]];
    //[sessionViewController prepareForCall:YES withVideo:[call hasVideo]];
    
    //At this moment it is possible to do recording, so show the recording button
    //[sessionViewController stopVideoRecording:YES hideRecordButton:![call hasVideo]];
}

/**
 Handle case when call is in closing state.
 @param call HOPCall Ending call
 */
- (void) onCallClosing:(HOPCall*) call
{
//    NSString* sessionId = [[call getConversationThread] getThreadId];
//    Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
//    [[HOPMediaEngine sharedInstance] stopVideoCapture];
    [call hangup:HOPCallClosedReasonNone];
    //Set flag that there is no active call
    [self setActiveCallConversation:[call getConversation] callActive:NO];
}

/**
 Sets active call session if there is no active call at the momment and returns YES, otherwise just returns NO.  Also if active call is being ended sets active call sesion to nil and returns YES, otherwise doesn't do anythning and returns NO.
 @param activeCall BOOL Flag if call is being active or it is ended
 @param inSession Session session with call.
 @return YES if session with active call is set for active call, or when session is nilled for ending call. In all other cases it returns NO
 */
- (BOOL) setActiveCallConversation:(HOPConversation*) inConversation callActive:(BOOL) callActive
{
    BOOL ret = NO;
    @synchronized(self)
    {
        if (callActive && self.conversationWithActiveCall == nil)
        {
            //If there is no session with active call, set it
            self.conversationWithActiveCall = inConversation;
            ret = YES;
        }
        else if (!callActive && self.conversationWithActiveCall == inConversation)
        {
            //If there is session with active call, set it to nil, because call is ended
            self.conversationWithActiveCall = nil;
            ret = YES;
        }
    }
    return ret;
}


/**
 Redials for session.
 @param inSession Session session with failed call which needs to be redialed.
 */
- (void) redialCallForConversation:(HOPConversation *)inConversation
{
    if (inConversation == self.lastEndedCallConversation)
    {
        //Check interval since last attempt, and if last call is ended 10 seconds ago, or earlier try to redial.
        NSTimeInterval timeInterval = [[inConversation.activeCall getClosedTime] timeIntervalSinceDate:[NSDate date]];
        if (timeInterval < 10)
            [self makeCallForConversation:inConversation includeVideo:NO isRedial:YES];
    }
}

/**
 Handles ended call.
 @param inSession Session with call that is ended.
 */
- (void) onCallEnded:(HOPCall*) call
{
    //Get call session
//    NSString* sessionId = [[call getConversationThread] getThreadId];
//    Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
    
    HOPConversation* conversation = [call getConversation];
    
    [[HOPMediaEngine sharedInstance] stopVideoCapture];
    //Get view controller for call session
    SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:[conversation getID]];
    
    if (sessionViewController)
    {
        //[sessionViewController removeCallViews];
        [sessionViewController onCallEnded];
        //Update view for case when call is not active
        //[sessionViewController prepareForCall:NO withVideo:NO];
        
        //Enable video recording if face detection is on
        //[sessionViewController stopVideoRecording:YES hideRecordButton:![[OpenPeer sharedOpenPeer] isFaceDetectionModeOn]];
    }
    
    //[self setLastEndedCallConversation:<#(HOPConversation *)#>: session];
    //TODO: reimplement redial when call is ended because of weak network
    //If it is callee side, check the reasons why call is ended, and if it is not ended properly, try to redial
    if (![[call getCaller] isSelf] && ((OpenPeer*)[OpenPeer sharedOpenPeer]).isRedialModeOn)
    {
        if ([call getClosedReason] == HOPCallClosedReasonNone || [call getClosedReason] == HOPCallClosedReasonRequestTerminated || [call getClosedReason] == HOPCallClosedReasonTemporarilyUnavailable)
        {
            //[[MessageManager sharedMessageManager] sendSystemMessageToCallAgainForSession:session];
            conversation.redialCall = YES;
        }
        else
        {
            conversation.redialCall = NO;
        }
    }
    else
    {
        conversation.redialCall = NO;
        //If call is droped because user is a busy at the moment, show notification to caller.
        if ([conversation.activeCall getClosedReason] == HOPCallClosedReasonBusy)
        {
            HOPRolodexContact* contact = [conversation.participants objectAtIndex:0];
            NSString* contactName = contact.name;
            [[[OpenPeer sharedOpenPeer] mainViewController] showNotification:[NSString stringWithFormat:@"%@ is busy.",contactName]];
         }
    }
    
    conversation.activeCall = nil;
    [[SessionManager sharedSessionManager] setLastEndedCallConversation: conversation];
}


/**
 Starts video recording.
 */
- (void) startVideoRecording
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Video recording is started");
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy-HH-mm"];
    
    NSString* filename = [NSString stringWithFormat:@"OpenPeer_%@.mp4",[formatter stringFromDate:[NSDate date]]];
    [[HOPMediaEngine sharedInstance] setRecordVideoOrientation:HOPMediaEngineVideoOrientationPortrait];
    //For saving video file in application boundle, provide file path an set saveToLibrary to NO. In case just file name is provided and saveToLibrary is set to YES, video file will be saved in ios media library
    [[HOPMediaEngine sharedInstance] startRecordVideoCapture:filename saveToLibrary:YES];
}

/**
 Stops video recording.
 */
- (void) stopVideoRecording
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Video recording is stopped");
    //Stop video recording
    [[HOPMediaEngine sharedInstance] stopRecordVideoCapture];
}

/**
  Returns info if there is active call.
 @returns YES if call is in progress
 */
- (BOOL) isCallInProgress
{
    BOOL ret = NO;
    @synchronized(self)
    {
        ret = self.conversationWithActiveCall != nil;
    }
    return ret;
}


- (void) recreateExistingSessions
{
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelTrace, @"Recreate existing sessions");
    
    for (HOPConversation* conversation in self.sessionsDictionary.allValues)
    {
        [conversation refresh];
    }
}


- (void) stopAnyActiveCall
{
    if (self.conversationWithActiveCall)
        [self.conversationWithActiveCall.activeCall hangup:HOPCallClosedReasonNone];
}

- (void) clearAllSessions
{
    [self stopAnyActiveCall];
    for (HOPConversation* conversation in [self.sessionsDictionary allValues])
    {
        [conversation clear];
    }
    [self.sessionsDictionary removeAllObjects];
}

- (int) totalNumberOfUnreadMessages
{
    int ret = 0;
    for (HOPConversation* conversation in [self.sessionsDictionary allValues])
    {
        ret += conversation.numberOfUnreadMessages;
    }
    return ret;
}

- (NSString* )getSystemMessage:(HOPMessageRecord *)messageRecord
{
    NSString* ret = nil;
    HOPCallSystemMessage* callSystemMessage = [HOPCallSystemMessage callSystemMessageFromJSON:messageRecord.text];
    
    switch (callSystemMessage.messageType) {
        case HOPCallSystemMessageTypeCallPlaced:
            ret = [NSString stringWithFormat:@"Call started: %@", [Utility getLocalDateFromUTCdate:messageRecord.date]];
            break;
        case HOPCallSystemMessageTypeCallHungup:
            ret = [NSString stringWithFormat:@"%@: %@", [Utility stringForEndingCallReason:callSystemMessage.errorCode],[Utility getLocalDateFromUTCdate:messageRecord.date]];
            break;
        default:
            break;
    }
    
    return ret;
}

- (NSString*) getLastTextMessageForConversationRecord:(HOPConversationRecord*) record
{
    NSString* ret = nil;
    HOPMessageRecord* messageRecord = [record getLastMessage];
    if (messageRecord)
    {
        if (![messageRecord.type isEqualToString:[HOPSystemMessage getMessageType]])
            ret = messageRecord.text;
        else
            ret = [[SessionManager sharedSessionManager] getSystemMessage:messageRecord];
    }

    return ret;
}

- (NSString*) getLastTextMessageForConversationEvent:(HOPConversationEvent*) event
{
    NSString* ret = nil;
    NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    NSArray* sorted = [event.messages.allObjects sortedArrayUsingDescriptors:@[sort]];
    HOPMessageRecord* messageRecord = sorted.count > 0 ? sorted[0] : nil;//[[HOPModelManager sharedModelManager] getLastMessageRecordForConversationEvent:event];
    if (messageRecord)
    {
        if (![messageRecord.type isEqualToString:[HOPSystemMessage getMessageType]])
            ret = messageRecord.text;
        else
        {
            ret = [self getSystemMessage:messageRecord];
        }
    }
    return ret;
}

/*- (void) addParticipants:(NSArray*) participants toSession:(Session*) session
{
    if (session && participants.count > 0)
    {
        [session.conversationThread addContacts:participants];
    }
}

- (void) removeParticipants:(NSArray*) participants toSession:(Session*) session
{
    if (session && participants.count > 0)
    {
        [session.conversationThread removeContacts:participants];
    }
}*/

- (NSString*) getTitleForConversationThread:(HOPConversationThread*) conversationThread
{
    NSString* ret = @"";
    
    NSArray* participants = [conversationThread getContacts];
    for (HOPRolodexContact* rolodexContact in participants)
    {
        if (rolodexContact)
        {
            if (ret.length == 0)
                ret = rolodexContact.name;
            else
            {
                ret = [ret stringByAppendingString:@", "];
                ret = [ret stringByAppendingString:rolodexContact.name];
            }
        }
    }
    return ret;
}

- (void) onParticipantsInConversationUpdate:(HOPConversation*) conversation
{
    /*if (conversation.participants.count == 0)
        return;
    
    NSString* sessionId = [conversation getID];
    
    BOOL hasChanged = NO;
    
    //Session* session = nil;
    //if (sessionId.length > 0)
    {
        //session = [self getSessionForSessionId:sessionId];
        //if (session)
        {
            NSMutableArray *intermediate = [NSMutableArray arrayWithArray:openPeerContacts];
            [intermediate removeObjectsInArray:[session.lastConversationEvent getContacts]];
            NSUInteger difference = [intermediate count];
            
            NSString* title = [self getTitleForConversationThread:conversationThread];
            
            if (difference > 0)
            {
                session.lastConversationEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"addedNewParticipant" conversationRecord:session.sessionRecord partcipants:openPeerContacts title:title];
                
                hasChanged = YES;
            }
            else
            {
                if (openPeerContacts.count != [session.lastConversationEvent getContacts].count)
                {
                    session.lastConversationEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"removedParticipant" conversationRecord:session.sessionRecord partcipants:openPeerContacts title:title];
                    hasChanged = YES;
                }
            }
            
            if (hasChanged)
            {
                session.title = title;
                [session.participantsArray removeAllObjects];
                [session.participantsArray addObjectsFromArray:openPeerContacts];
        
                [session.sessionRecord setParticipantsWithArray:openPeerContacts];
                
                SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:sessionId];
                
                [sessionViewController updateOnParticipantChange];
            }
        }
    }*/
}

@end
