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

#import "SessionManager.h"
#import "ContactsManager.h"
#import "MainViewController.h"
#import "MessageManager.h"
#import "SessionViewController_iPhone.h"
#import "SoundsManager.h"
#import "Utility.h"
#import "Session.h"
#import "OpenPeer.h"
#import "AppConsts.h"

#import <OpenpeerSDK/Openpeer.h>
#import "UIDevice+Networking.h"

@interface SessionManager()

@property (nonatomic, assign) Session* sessionWithActiveCall;

- (id) initSingleton;
- (BOOL) setActiveCallSession:(Session*) inSession callActive:(BOOL) callActive;
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
        self.sessionsDictionaryWithCBCID = [[NSMutableDictionary alloc] init];
    }
    return self;
}


/**
 Creates a session for the selected contacts
 @param contact HOPContact Contact for which session will be created.
*/
- (Session*)createSessionForContacts:(NSArray*) contacts
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Creating session for contacts: %@", contacts);
    Session* ret = nil;
    
    if ([contacts count] == 0)
        return ret;
    
    ret = [self getSessionForContacts:contacts];
    
    if (!ret)
    {
        NSString* cbcID = [HOPModelManager getCBCIDForContacts:contacts];
        
        if (![UIDevice isNetworkReachable])
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:[NSString stringWithFormat:@"Unable to make a session because of network issue. Please, check your internet connection."] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            return ret;
        }

        HOPConversationThread* conversationThread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities]];
        
        NSString* title = nil;
        if (conversationThread)
        {
            NSMutableArray* participants = nil;
            //Create a session with new conversation thread
            ret = [[Session alloc] initWithContacts:contacts conversationThread:conversationThread];
            
            //Add list of all participants. Currently only one participant is added
            if (ret)
            {
                if (contacts.count > 0)
                {
                    participants = [[NSMutableArray alloc] init];
                    for (HOPRolodexContact* contact in contacts)
                    {
                        if ([contact isOpenPeer])
                            [participants addObject:contact];
                    }
                    [conversationThread addContacts:participants];
                }

                title = [self getTitleForConversationThread:conversationThread];
                
                OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Creating session record from conversation thread id: %@", [conversationThread getThreadId]);
                
                ret.sessionRecord = [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:conversationThread type:nil date:[NSDate date] name:title participants:contacts];
                
                ret.title = title;
                
                //Store session object in dictionary
                [self.sessionsDictionary setObject:ret forKey:[conversationThread getThreadId]];
                [self.sessionsDictionaryWithCBCID setObject:ret forKey:cbcID];
                
                ret.lastConversationEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:ret.sessionRecord partcipants:participants title:title];
            }
        }
        else
        {
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelTrace, @"Conversation thread is not created");
        }
    }
    
    return ret;
}

/**
 Creates an incoming session.
 @param contacts NSArray List of participants.
 @param inConversationThread HOPConversationThread Incoming conversation thread
*/
- (Session*) createSessionForConversationThread:(HOPConversationThread*) inConversationThread
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Creating session for conversation thread id: %@", [inConversationThread getThreadId]);
    Session* ret = nil;
    
    NSArray* contactAaray = [inConversationThread getContacts];
    
    if (contactAaray.count > 0)
    {
        NSString* cbcID = [HOPModelManager getCBCIDForContacts:contactAaray];
        
        ret = [[Session alloc] initWithContacts:contactAaray conversationThread:inConversationThread];
        
        if (ret)
        {
            NSString* title = [self getTitleForConversationThread:inConversationThread];
            [self.sessionsDictionary setObject:ret forKey:[inConversationThread getThreadId]];
            [self.sessionsDictionaryWithCBCID setObject:ret forKey:cbcID];
            
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Creating session record from conversation thread id: %@", [inConversationThread getThreadId]);
            ret.sessionRecord = [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:inConversationThread type:nil date:[NSDate date] name:title participants:contactAaray];
            
            ret.title = title;
            ret.lastConversationEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"create" conversationRecord:ret.sessionRecord partcipants:contactAaray title:title];
        }
    }
    return ret;
}


- (void)setValidSession:(Session *)inSession newSessionId:(NSString *)newSessionId oldSessionId:(NSString *)oldSessionId
{
    [self.sessionsDictionary setObject:inSession forKey:newSessionId];
    
    [[[OpenPeer sharedOpenPeer] mainViewController] updateSessionViewControllerId:oldSessionId newSesionId:newSessionId];
}

/**
 If exists it retrieves an old session for a contact for which new conversation thread is created. If the old session is found, old conversation thread object is replaced with a new one, session key in sessions dictionary is updated with a new conversation thread id.
 @param contact HOPRolodexContact participant of new conversation thread
 @param inConversationThread HOPConversationThread new conversation thread
 */
- (Session*) proceedWithExistingSessionForContacts:(NSArray*) contacts newConversationThread:(HOPConversationThread*) inConversationThread
{
    //OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Get existing session for contact peer URI: %@", [contact getPeerURI]);
    
    Session* ret = nil;
    if (contacts)
        ret = [self getSessionForContacts:contacts];
    
    if (ret)
    {
        NSString* oldSessionId = [ret.conversationThread getThreadId];
        NSString* newSessionId = [inConversationThread getThreadId];
        
        ret.conversationThread = inConversationThread;
        [ret.sessionIdsHistory addObject:[inConversationThread getThreadId]];
        
        NSArray* contacts = [inConversationThread getContacts];
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Creating session record from conversation thread id: %@", [inConversationThread getThreadId]);
        
        [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:inConversationThread type:nil date:nil name:nil participants:contacts];

        [[HOPModelManager sharedModelManager] saveContext];
        [self setValidSession:ret newSessionId:newSessionId oldSessionId:oldSessionId];
    }
    return ret;
}
/**
 Get active session for contact.
 @param contacts HOPRolodexContact One of the participants.
 @return session with participant
*/
- (Session*) getSessionForContacts:(NSArray*) contacts
{
    NSString* cbcID = [HOPModelManager getCBCIDForContacts:contacts];
    if (cbcID.length > 0)
        return [self.sessionsDictionaryWithCBCID objectForKey:cbcID];
    
//    for (Session* session in [self.sessionsDictionary allValues])
//    {
//        NSSet *set1 = [NSSet setWithArray:session.participantsArray];
//        NSSet *set2 = [NSSet setWithArray:contacts];
//        
//        if ([set1 isEqualToSet:set2])
//            return session;
//    }
    return nil;
}

- (Session*) getSessionForSessionId:(NSString*) sessionId
{
    return [self.sessionsDictionary objectForKey:sessionId];
}

- (Session*) getSessionForConversationEvent:(HOPConversationEvent*) event
{
    for (Session* session in [self.sessionsDictionary allValues])
    {
        if (session.lastConversationEvent == event)
            return session;
    }
    return nil;
}


/**
 Make call for session.
 @param inSession Session session.
 @param includeVideo BOOL If YES make video call
 @param isRedial BOOL If trying to reestablish call that was ended because of network problems 
 */
- (void) makeCallForSession:(Session*) inSession includeVideo:(BOOL) includeVideo isRedial:(BOOL) isRedial
{
    if ([UIDevice isNetworkReachable])
    {
        if (!inSession.currentCall)
        {
            OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Making a call for the session <%p>", inSession);
            
            [[MessageManager sharedMessageManager] sendCallSystemMessage:HOPCallSystemMessageTypeCallPlaced reasonCode:0 session:inSession];
            
            //Place a audio or video call for chosen contact
            inSession.isRedial = isRedial;
            inSession.currentCall = [HOPCall placeCall:inSession.conversationThread includeAudio:YES includeVideo:includeVideo];
            [self setActiveCallSession:inSession callActive:YES];
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
- (void) answerCallForSession:(Session*) inSession
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Answer a call for the session <%p>", inSession);
    //Answer an incoming call
    [[inSession currentCall] answer];
}

/**
 Ends current call for sesion.
 @param inSession Session session.
 */
- (void) endCallForSession:(Session*) inSession
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"End the call for the session <%p>", inSession);
    //Hangup current active call
    [[inSession currentCall] hangup:HOPCallClosedReasonUser];
    //Set flag that there is no active call
    [self setActiveCallSession:inSession callActive:NO];
}

/**
 Handles preparing call state. At this state while clients negotiations are not completed, call  should not be yet presented to the user. In this sample, because of demonstration and easier state changes trcking, it is shown session ciew controller.  
 @param call HOPCall Incomin call
 */
- (void) onCallPreparing:(HOPCall*) call
{
    NSString* sessionId = [[call getConversationThread] getThreadId];
    Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
    
    if (!session)
    {
        HOPOpenPeerContact* contact = [[HOPModelManager sharedModelManager] getOpenPeerContactForPeerURI:[[call getCaller] getPeerURI]];
        session = [[SessionManager sharedSessionManager] getSessionForContacts:@[contact]];
        if (session)
        {
            //[[SessionManager sharedSessionManager] setValidSession:session newSessionId:[session.conversationThread getThreadId]oldSessionId:sessionId];
            OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"%Session for id %@ not found, but it is found other with id %@",sessionId,[session.conversationThread getThreadId]);
        }
    }
    
    if (session)
    {
        SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:[session.conversationThread getThreadId]];
        
        if ([[call getCaller] isSelf])
        {
            if ([call hasVideo])
                [sessionViewController showWaitingView:YES];
            else
                [sessionViewController showCallViewControllerWithVideo:NO];
        }
    }
    else
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelBasic, @"Incomming call for unknown session id %@", sessionId);
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
    NSString* sessionId = [[call getConversationThread] getThreadId];
    Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Incoming a call for the session <%p>", session);
    
    //Set current call
    //BOOL callFlagIsSet = [self setActiveCallSession:session callActive:YES];
    
    //If callFlagIsSet is YES, show incoming call view, and move call to ringing state
    if (![self isCallInProgress])
    {
        session.currentCall = call;
        
        if (!session.isRedial)
        {
            //[[[OpenPeer sharedOpenPeer] mainViewController] showIncominCallForSession:session];
            //If it is an incomming call, get show session view controller
            if (![[call getCaller] isSelf])
            {
                [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:YES forIncomingMessage:NO];
            }
            [call ring];
        }
        else
            [call answer];
        
        BOOL callFlagIsSet = [self setActiveCallSession:session callActive:YES];
    }
    else //If callFlagIsSet is NO, hangup incoming call. 
    {
        [call hangup:HOPCallClosedReasonBusy];
        [[[OpenPeer sharedOpenPeer] mainViewController] showNotification:[NSString stringWithFormat:@"%@ is busy.",[[[session participantsArray] objectAtIndex:0] name]]];
    }
}

- (void) onCallRinging:(HOPCall*) call
{
    NSString* sessionId = [[call getConversationThread] getThreadId];
    if ([sessionId length] > 0)
    {
        Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
        if (session)
        {
            [[[OpenPeer sharedOpenPeer] mainViewController] showIncominCallForSession:session];
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
     SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:[[call getConversationThread] getThreadId]];
    
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
    NSString* sessionId = [[call getConversationThread] getThreadId];
    Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
    [[HOPMediaEngine sharedInstance] stopVideoCapture];
    [[session currentCall] hangup:HOPCallClosedReasonNone];
    //Set flag that there is no active call
    [self setActiveCallSession:session callActive:NO];
}

/**
 Sets active call session if there is no active call at the momment and returns YES, otherwise just returns NO.  Also if active call is being ended sets active call sesion to nil and returns YES, otherwise doesn't do anythning and returns NO.
 @param activeCall BOOL Flag if call is being active or it is ended
 @param inSession Session session with call.
 @return YES if session with active call is set for active call, or when session is nilled for ending call. In all other cases it returns NO
 */
- (BOOL) setActiveCallSession:(Session*) inSession callActive:(BOOL) callActive
{
    BOOL ret = NO;
    @synchronized(self)
    {
        if (callActive && self.sessionWithActiveCall == nil)
        {
            //If there is no session with active call, set it
            self.sessionWithActiveCall = inSession;
            ret = YES;
        }
        else if (!callActive && self.sessionWithActiveCall == inSession)
        {
            //If there is session with active call, set it to nil, because call is ended
            self.sessionWithActiveCall = nil;
            ret = YES;
        }
    }
    return ret;
}


/**
 Redials for session.
 @param inSession Session session with failed call which needs to be redialed.
 */
- (void) redialCallForSession:(Session*) inSession
{
    if (inSession == self.lastEndedCallSession )
    {
        //Check interval since last attempt, and if last call is ended 10 seconds ago, or earlier try to redial.
        NSTimeInterval timeInterval = [[inSession.currentCall getClosedTime] timeIntervalSinceDate:[NSDate date]];
        if (timeInterval < 10)
            [self makeCallForSession:inSession includeVideo:NO isRedial:YES];
    }
}

/**
 Handles ended call.
 @param inSession Session with call that is ended.
 */
- (void) onCallEnded:(HOPCall*) call
{
    //Get call session
    NSString* sessionId = [[call getConversationThread] getThreadId];
    Session* session = [[[SessionManager sharedSessionManager] sessionsDictionary] objectForKey:sessionId];
    
    [[HOPMediaEngine sharedInstance] stopVideoCapture];
    //Get view controller for call session
    SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:[[session conversationThread] getThreadId]];
    
    if (sessionViewController)
    {
        //[sessionViewController removeCallViews];
        [sessionViewController onCallEnded];
        //Update view for case when call is not active
        //[sessionViewController prepareForCall:NO withVideo:NO];
        
        //Enable video recording if face detection is on
        //[sessionViewController stopVideoRecording:YES hideRecordButton:![[OpenPeer sharedOpenPeer] isFaceDetectionModeOn]];
    }
    
    [self setLastEndedCallSession: session];
    //TODO: reimplement redial when call is ended because of weak network
    //If it is callee side, check the reasons why call is ended, and if it is not ended properly, try to redial
    if (![[call getCaller] isSelf] && ((OpenPeer*)[OpenPeer sharedOpenPeer]).isRedialModeOn)
    {
        if ([call getClosedReason] == HOPCallClosedReasonNone || [call getClosedReason] == HOPCallClosedReasonRequestTerminated || [call getClosedReason] == HOPCallClosedReasonTemporarilyUnavailable)
        {
            //[[MessageManager sharedMessageManager] sendSystemMessageToCallAgainForSession:session];
            session.isRedial = YES;
        }
        else
        {
            session.isRedial = NO;
        }
    }
    else
    {
        session.isRedial = NO;
        //If call is droped because user is a busy at the moment, show notification to caller.
        if ([session.currentCall getClosedReason] == HOPCallClosedReasonBusy)
        {
            HOPRolodexContact* contact = [session.participantsArray objectAtIndex:0];
            NSString* contactName = contact.name;
            [[[OpenPeer sharedOpenPeer] mainViewController] showNotification:[NSString stringWithFormat:@"%@ is busy.",contactName]];
         }
    }
    
    session.currentCall = nil;
    [[SessionManager sharedSessionManager] setLastEndedCallSession: session];
}

/**
 Handle face detected event
 */
- (void) onFaceDetected
{
    
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
        ret = self.sessionWithActiveCall != nil;
    }
    return ret;
}


- (void) recreateExistingSessions
{
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelTrace, @"Recreate existing sessions");
    //for (Session* session in [self.sessionsDictionary allValues])
    for ( NSString* key in [self.sessionsDictionary allKeys])
    {
        Session* session = [self.sessionsDictionary objectForKey:key];
        if ([session.participantsArray count] > 0)
        {
            NSString* oldSessionId = [session.conversationThread getThreadId];
            
            HOPConversationThread* conversationThread = [HOPConversationThread conversationThreadWithIdentities:[[HOPAccount sharedAccount] getAssociatedIdentities]];
            
            session.conversationThread = nil;
            
            
            //Add list of all participants. Currently only one participant is added
            if (conversationThread)
            {
                //NSString* oldSessionId = [session.conversationThread getThreadId];
                NSString* newSessionId = [conversationThread getThreadId];
                
                //Update the session with a new conversation thread
                session.conversationThread = conversationThread;
                [session.sessionIdsHistory addObject:[conversationThread getThreadId]];
                
                NSMutableArray* participants = [[NSMutableArray alloc] init];
                for (HOPRolodexContact* rolodexContact in session.participantsArray)
                {
                    [participants addObject:rolodexContact];
                }
                [conversationThread addContacts:participants];
                NSArray* contactsArray = [[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:[[participants objectAtIndex:0] getPeerURI]];
                if (contactsArray)
                {
                    [[HOPModelManager sharedModelManager] createConversationRecordForConversationThread:conversationThread type:nil date:nil name:nil participants:contactsArray];
                
                    [self setValidSession:session newSessionId:newSessionId oldSessionId:oldSessionId];
                }
            }
        }
        else
        {
            [self.sessionsDictionary removeObjectForKey:key];
        }
    }
}


- (void) stopAnyActiveCall
{
    if (self.sessionWithActiveCall)
        [self.sessionWithActiveCall.currentCall hangup:HOPCallClosedReasonNone];
}

- (void) clearAllSessions
{
    [self stopAnyActiveCall];
    for (Session* session in [self.sessionsDictionary allValues])
    {
        [session.conversationThread destroyCoreObject];
    }
    [self.sessionsDictionary removeAllObjects];
}

- (void) setLatestValidConversationThread:(HOPConversationThread*) inConversationThread
{
    Session* session = [self.sessionsDictionary objectForKey:[inConversationThread getThreadId]];
    session.conversationThread = inConversationThread;
}

- (int) totalNumberOfUnreadMessages
{
    int ret = 0;
    for (Session* session in [self.sessionsDictionary allValues])
    {
        ret += [session.unreadMessageArray count];
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
    NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    NSArray* sorted = [record.messages.allObjects sortedArrayUsingDescriptors:@[sort]];
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

- (void) addParticipants:(NSArray*) participants toSession:(Session*) inSession
{
    if (participants.count > 0)
    {
        NSArray* array = [inSession.participantsArray arrayByAddingObjectsFromArray:participants];
        
        Session* session = [self createSessionForContacts:array];
        
        if (session)
        {
            [[[OpenPeer sharedOpenPeer] mainViewController] popLastSessionViewController];
            [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:NO forIncomingMessage:NO];
        }
    }
    
//    if (session && participants.count > 0)
//    {
//        [session.conversationThread addContacts:participants];
//    }
}

- (void) removeParticipants:(NSArray*) participants toSession:(Session*) inSession
{
    if (participants.count > 0)
    {
        NSMutableArray* array = [NSMutableArray arrayWithArray:inSession.participantsArray];
        [array removeObjectsInArray:participants];
        
        Session* session = [self createSessionForContacts:array];
        
        if (session)
        {
            [[[OpenPeer sharedOpenPeer] mainViewController] popLastSessionViewController];
            [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:NO forIncomingMessage:NO];
        }
    }
    
//    if (session && participants.count > 0)
//    {
//        //NSMutableArray* contacts = [NSMutableArray new];
//        
//        /*for (HOPRolodexContact* contact in participants)
//        {
//            HOPContact* hopContact = [contact getCoreContact];
//            if (hopContact)
//                [contacts addObject:hopContact];
//        }*/
//        
//        //if (contacts.count > 0)
//        [session.conversationThread removeContacts:participants];
//    }
}

- (NSString*) getTitleForConversationThread:(HOPConversationThread*) conversationThread
{
    NSString* ret = @"";
    
    NSArray* participants = [conversationThread getContacts];
    for (HOPRolodexContact* rolodexContact in participants)
    {
        //HOPRolodexContact* rolodexContact = [contact getDefaultRolodexContact];
        
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

- (void) updateParticipantsInConversationThread:(HOPConversationThread*) conversationThread
{
    NSArray* openPeerContacts = [conversationThread getContacts];
    
    if (openPeerContacts.count == 0)
        return;
    
    NSString* sessionId = [conversationThread getThreadId];
    
    BOOL hasChanged = NO;
    
    Session* session = nil;
    if (sessionId.length > 0)
    {
        session = [self getSessionForSessionId:sessionId];
        if (session)
        {
            NSMutableArray *intermediate = [NSMutableArray arrayWithArray:openPeerContacts];
            [intermediate removeObjectsInArray:session.lastConversationEvent.participants.participants.allObjects];
            NSUInteger difference = [intermediate count];
            
            NSString* title = [self getTitleForConversationThread:conversationThread];
            
            if (difference > 0)
            {
                session.lastConversationEvent = [[HOPModelManager sharedModelManager] addConversationEvent:@"addedNewParticipant" conversationRecord:session.sessionRecord partcipants:openPeerContacts title:title];
                
                hasChanged = YES;
            }
            else
            {
                if (openPeerContacts.count != session.lastConversationEvent.participants.participants.allObjects.count)
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
        
        
    }
    
    
}

@end
