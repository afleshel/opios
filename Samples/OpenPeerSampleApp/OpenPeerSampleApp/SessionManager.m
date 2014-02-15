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

#import "Utility.h"
#import "Session.h"
#import "OpenPeer.h"
#import "AppConsts.h"

#import <OpenpeerSDK/HOPConversationThread.h>
#import <OpenpeerSDK/HOPContact.h>
#import <OpenpeerSDK/HOPRolodexContact+External.h>
#import <OpenpeerSDK/HOPIdentityContact.h>
#import <OpenpeerSDK/HOPPublicPeerFile.h>
#import <OpenpeerSDK/HOPMessage.h>
#import <OpenpeerSDK/HOPCall.h>
#import <OpenpeerSDK/HOPMediaEngine.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenpeerSDK/HOPContact.h>
#import <OpenpeerSDK/HOPHomeUser+External.h>

@interface SessionManager()

@property (nonatomic, assign) Session* sessionWithActiveCall;

- (id) initSingleton;
- (BOOL) setActiveCallSession:(Session*) inSession callActive:(BOOL) callActive;

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
    }
    return self;
}


/**
 Creates a session for the selected contacts
 @param contact HOPContact Contact for which session will be created.
*/
- (Session*)createSessionForContact:(HOPRolodexContact *)contact
{
    Session* ret = nil;
    
    if (!contact)
        return ret;
    
    ret = [self getSessionForContact:contact];
    
    if (!ret)
    {
        NSString* profileBundle = [[ContactsManager sharedContactsManager] createProfileBundleForCommunicationWithContact:contact];
        //Create a conversation thread
        HOPConversationThread* conversationThread = [HOPConversationThread conversationThreadWithProfileBundle:profileBundle];
        
        //Create a session with new conversation thread
        ret = [[Session alloc] initWithContact:contact conversationThread:conversationThread];
        
        //Add list of all participants. Currently only one participant is added
        if (ret)
        {
            NSArray* participants = [NSArray arrayWithObject:[contact getCoreContact]];
            [conversationThread addContacts:participants];
#ifdef APNS_ENABLED
            for (HOPContact* coreContact in participants)
            {
                NSArray* apnsData = [[HOPModelManager sharedModelManager]getAPNSDataForPeerURI:[coreContact getPeerURI]];
                if ([apnsData count] == 0)
                {
                    if ([[[OpenPeer sharedOpenPeer]deviceToken] length] > 0)
                    {
                        HOPMessage* apnsMessage = [[MessageManager sharedMessageManager] createSystemMessageWithType:SystemMessage_APNS_Request andText:[[OpenPeer sharedOpenPeer]deviceToken] andRecipient:contact];
                        [conversationThread sendMessage:apnsMessage];
                    }
                }
            }
#endif
            [[HOPModelManager sharedModelManager] addSession:[conversationThread getThreadId] type:nil date:nil name:nil participants:[NSArray arrayWithObject:contact]];
        }
        
        if (ret)
        {
            //Store session object in dictionary
            [self.sessionsDictionary setObject:ret forKey:[conversationThread getThreadId]];
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
    Session* ret = nil;
    HOPRolodexContact* rolodexContact = nil;
    NSArray* contacts = [inConversationThread getContacts];
    
    NSArray* contactAaray = [[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:[[contacts objectAtIndex:0] getPeerURI]];
    NSMutableArray* rolodexContacts  = contactAaray == nil ? [[NSMutableArray alloc] init] : [NSMutableArray  arrayWithArray: contactAaray];
    
    if ([rolodexContacts count] == 0)
    {
        HOPContact* coreContact = [contacts objectAtIndex:0];
        NSString* profileBundle = [inConversationThread getProfileBundle:coreContact];
        rolodexContact = [[ContactsManager sharedContactsManager] getRolodexContactByProfileBundle:profileBundle coreContact:coreContact];
        [rolodexContacts addObject:rolodexContact];
    }
    else
    {
        rolodexContact = [rolodexContacts objectAtIndex:0];
    }
    
    if (rolodexContact)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, @"%@ initiating a session with %@", [[rolodexContacts objectAtIndex:0] name], [[[HOPModelManager sharedModelManager] getLastLoggedInHomeUser] getFullName]);
        
        ret = [[Session alloc] initWithContacts:rolodexContacts conversationThread:inConversationThread];
        
        if (ret)
        {
            [self.sessionsDictionary setObject:ret forKey:[inConversationThread getThreadId]];
            [[HOPModelManager sharedModelManager] addSession:[inConversationThread getThreadId] type:nil date:nil name:nil participants:contactAaray];
        }
    }
    return ret;
}

/**
 Creates a new session initiate from other session (Remote session initialization).
 @param inSession Session session that initiates creation
 @param userIds NSString list of userIds separated by comma which will take a part in new session. Currently group sessions are not supported, so userIds contains just one user id.
 */
- (Session*) createSessionInitiatedFromSession:(Session*) inSession forContactPeerURIs:(NSString*) peerURIs
{
    Session* session = nil;
    NSArray *strings = [peerURIs componentsSeparatedByString:@","];
    if ([strings count] > 0)
    {
        //If userId is valid string, find a contact with that user id
        NSString* peerURI = [strings objectAtIndex:0];
        if ([peerURI length] > 0)
        {
            HOPRolodexContact* contact = [[[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:peerURI] objectAtIndex:0];
            if (contact)
            {
                //Create a session for contact
                session = [self createSessionForContact:contact];
                if (session)
                {
                    //If session is created sucessfully, start a video call
                    [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:NO  forIncomingMessage:NO];
                    
                    [self makeCallForSession:session includeVideo:YES isRedial:NO];
                }
            }
        }
    }
    
    return session;
}

/**
 Creates a session that will initiate creation of other session between contacts passed in the list .
 @param participants NSArray* List of remote session participants.
 @return session with participant
 */
- (Session*) createRemoteSessionForContacts:(NSArray*) participants
{
    Session* sessionThatWillInitiateRemoteSession = nil;
    //Check if list has at least 2 contacts
    if ([participants count] > 1)
    {
        //First contact is master and he will be remote session host
        HOPRolodexContact* masterContact = [participants objectAtIndex:0];
        HOPRolodexContact* slaveContact = [participants objectAtIndex:1];
        
        //Create a session with the master contact, that will be used to send system message for creating a remote session
        sessionThatWillInitiateRemoteSession = [self createSessionForContact:masterContact];
        if (sessionThatWillInitiateRemoteSession)
        {
            //Send system message, where is passed the slave contacts. Session will be established between slave contacts and master contact.
            [[MessageManager sharedMessageManager] sendSystemMessageToInitSessionBetweenPeers:[NSArray arrayWithObject:slaveContact] forSession:sessionThatWillInitiateRemoteSession];
        }
    }
    return sessionThatWillInitiateRemoteSession;
}

/**
 If exists it retrieves an old session for a contact for which new conversation thread is created. If the old session is found, old conversation thread object is replaced with a new one, session key in sessions dictionary is updated with a new conversation thread id.
 @param contact HOPRolodexContact participant of new conversation thread
 @param inConversationThread HOPConversationThread new conversation thread
 */
- (Session*) proceedWithExistingSessionForContact:(HOPContact*) contact newConversationThread:(HOPConversationThread*) inConversationThread
{
    Session* ret = nil;
    NSArray* rolodexContacts = [[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:[contact getPeerURI]];
    
    if ([rolodexContacts count] > 0)
        ret = [self getSessionForContact:[rolodexContacts objectAtIndex:0]];
    
    if (ret)
    {
        NSString* oldSessionId = [ret.conversationThread getThreadId];
        NSString* newSessionId = [inConversationThread getThreadId];
        
        ret.conversationThread = inConversationThread;
        [ret.sessionIdsHistory addObject:[inConversationThread getThreadId]];
        
        NSArray* contacts = [inConversationThread getContacts];
        NSArray* contactAaray = [[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:[[contacts objectAtIndex:0] getPeerURI]];
        [[HOPModelManager sharedModelManager] addSession:[inConversationThread getThreadId] type:nil date:nil name:nil participants:contactAaray];
        
        [self.sessionsDictionary removeObjectForKey:oldSessionId];
        [self.sessionsDictionary setObject:ret forKey:newSessionId];
        
        [[[OpenPeer sharedOpenPeer] mainViewController] updateSessionViewControllerId:oldSessionId newSesionId:newSessionId];
    }
    return ret;
}
/**
 Get active session for contact.
 @param contacts HOPRolodexContact One of the participants.
 @return session with participant
*/
- (Session*) getSessionForContact:(HOPRolodexContact*) contact
{
    for (Session* session in [self.sessionsDictionary allValues])
    {
        if ([session.participantsArray containsObject:contact])
            return session;
    }
    return nil;
}

- (Session*) getSessionForSessionId:(NSString*) sessionId
{
    return [self.sessionsDictionary objectForKey:sessionId];
}


/**
 Make call for session.
 @param inSession Session session.
 @param includeVideo BOOL If YES make video call
 @param isRedial BOOL If trying to reestablish call that was ended because of network problems 
 */
- (void) makeCallForSession:(Session*) inSession includeVideo:(BOOL) includeVideo isRedial:(BOOL) isRedial
{
    if (!inSession.currentCall)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Making a call for the session <%p>", inSession);
        
        [[MessageManager sharedMessageManager]sendSystemMessageToCheckAvailability:inSession];
        //Currently we are not supporting group conferences, so only one participant is possible
        HOPContact* contact = [[[inSession participantsArray] objectAtIndex:0] getCoreContact];
        
        //Place a audio or video call for chosen contact
        inSession.isRedial = isRedial;
        inSession.currentCall = [HOPCall placeCall:inSession.conversationThread toContact:contact includeAudio:YES includeVideo:includeVideo];
        [self setActiveCallSession:inSession callActive:YES];
    }
    else
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Call is already in a progress");
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
    
    if (session)
    {
        SessionViewController_iPhone* sessionViewController = [[[[OpenPeer sharedOpenPeer] mainViewController] sessionViewControllersDictionary] objectForKey:sessionId];
        
        //If it is an incomming call, get show session view controller
        if (![[call getCaller] isSelf])
        {
            [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:YES forIncomingMessage:NO];
        }
        else
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
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelInsane, @"Incoming a call for the session <%p>", session);
    
    //Set current call
    BOOL callFlagIsSet = [self setActiveCallSession:session callActive:YES];
    
    //If callFlagIsSet is YES, show incoming call view, and move call to ringing state
    if (callFlagIsSet)
    {
        session.currentCall = call;
        
        if (!session.isRedial)
        {
            [[[OpenPeer sharedOpenPeer] mainViewController] showIncominCallForSession:session];
            
            [call ring];
        }
        else
            [call answer];
    }
    else //If callFlagIsSet is NO, hangup incoming call. 
    {
        [call hangup:HOPCallClosedReasonBusy];
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
    //If it is callee side, check the reasons why call is ended, and if it is not ended properly, try to redial
    if (![[call getCaller] isSelf] && ((OpenPeer*)[OpenPeer sharedOpenPeer]).isRedialModeOn)
    {
        if ([call getClosedReason] == HOPCallClosedReasonNone || [call getClosedReason] == HOPCallClosedReasonRequestTerminated || [call getClosedReason] == HOPCallClosedReasonTemporarilyUnavailable)
        {
            [[MessageManager sharedMessageManager] sendSystemMessageToCallAgainForSession:session];
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
    return self.sessionWithActiveCall != nil;
}


- (void) recreateExistingSessions
{
    //for (Session* session in [self.sessionsDictionary allValues])
    for ( NSString* key in [self.sessionsDictionary allKeys])
    {
        Session* session = [self.sessionsDictionary objectForKey:key];
        if ([session.participantsArray count] > 0)
        {
            HOPRolodexContact* sessionParticipant = [session.participantsArray objectAtIndex:0];
            NSString* profileBundle = [[ContactsManager sharedContactsManager] createProfileBundleForCommunicationWithContact:sessionParticipant];
            //Create a conversation thread
            HOPConversationThread* conversationThread = [HOPConversationThread conversationThreadWithProfileBundle:profileBundle];
            
            session.conversationThread = nil;
            
            
            //Add list of all participants. Currently only one participant is added
            if (conversationThread)
            {
                //Update the session with a new conversation thread
                session.conversationThread = conversationThread;
                
                NSMutableArray* participants = [[NSMutableArray alloc] init];
                for (HOPRolodexContact* rolodexContact in session.participantsArray)
                {
                    [participants addObject:[rolodexContact getCoreContact]];
                }
                [conversationThread addContacts:participants];
            }
        }
        else
        {
            [self.sessionsDictionary removeObjectForKey:key];
        }
    }
}
@end
