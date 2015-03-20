/*
 
 Copyright (c) 2012-2015, Hookflash Inc.
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

#import <UIKit/UIKit.h>
#import "Delegates.h"
@class HOPConversation;

@class LoginViewController;
@class WebLoginViewController;
@class ContactsViewController;
@class ActiveSessionsViewController;

typedef enum
{
    DEMO_REMOTE_SESSION_INIT,
    DEMO_FACE_DETECTION_MODE,
    DEMO_CALL_REDIAL,
    DEMO_LOGGED_USER_INFO
} DemoOptions;

typedef  enum
{
    NEW_SESSION,
    NEW_SESSION_WITH_CALL,
    NEW_SESSION_WITH_CHAT,
    NEW_SESSION_REFRESH_CHAT,
    NEW_SESSION_SWITCH,
    EXISTING_SESSION,
    EXISITNG_SESSION_SWITCH,
    EXISTING_SESSION_REFRESH_CHAT,
    EXISTING_SESSION_REFRESH_NOT_VISIBLE_CHAT,
    EXISTIG_SESSION_SHOW_CHAT,
    INCOMING_CALL_WHILE_OTHER_INPROGRESS,
    REPLACE_EXISTING_SESSION,
    
    ERROR_CALL_ALREADY_IN_PROGRESS = 100
}SessionTransitionStates;

@interface MainViewController : UIViewController<UIActionSheetDelegate,UITabBarControllerDelegate,UIGestureRecognizerDelegate,LoginEventsDelegate,UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *activityLabel;
@property (nonatomic, weak) IBOutlet UIView *activityView;

@property (nonatomic, strong) LoginViewController *loginViewController;
@property (nonatomic, strong) ContactsViewController *contactsTableViewController;
@property (nonatomic, strong) ContactsViewController *favoritesTableViewController;
@property (nonatomic, strong) ActiveSessionsViewController *activeSessionsViewController;
@property (nonatomic, strong) UITabBarController *tabBarController;

@property (nonatomic, strong) NSMutableDictionary *sessionViewControllersDictionary;

@property (nonatomic, strong) UITapGestureRecognizer *threeTapGestureRecognizer;

- (void) popLastConversationViewController;

- (void) showTabBarController;
- (void) showWebLoginView:(WebLoginViewController*) webLoginViewController;
- (void) closeWebLoginView:(WebLoginViewController*) webLoginViewController;

- (BOOL) showSessionViewControllerForConversation:(HOPConversation*) conversation replaceConversation:(HOPConversation*) replaceConversation incomingCall:(BOOL) incomingCall incomingMessage:(BOOL) incomingMessage;
- (void) removeSessionViewControllerForSession:(NSString*) sessionId;
- (void) removeAllSessionViewControllers;
- (void) updateSessionViewControllerId:(NSString*) oldSessionId newSesionId:(NSString*) newSesionId;

- (void) showIncominCallForConversation:(HOPConversation*) conversation;
- (void) showNotification:(NSString*) message;

- (void) removeSplashScreen;
- (void) onLogout;
- (void) onContactsLoadingStarted;
- (void) onNetworkProblemResolved;

- (void) showQRScanner;
- (void) showSplashScreen;
- (void) waitForUserGesture;
- (void) changeKeyForViewController:(NSString*) oldKey newKey:(NSString*) newKey;

- (void) showImage:(UITapGestureRecognizer*) gesture;
@end
