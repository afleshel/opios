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

#import "MainViewController.h"
#import "OpenPeer.h"
#import "AppConsts.h"
#import "Utility.h"
#import "Logger.h"
//SDK
#import <OpenpeerSDK/HOPConversationThread.h>
#import <OpenpeerSDK/HOPConversation.h>
//Managers
#import "SessionManager.h"
#import "LoginManager.h"
#import "ContactsManager.h"
#import "MessageManager.h"
//Model
//#import "Session.h"
//View controllers
#import "WebLoginViewController.h"
#import "ContactsViewController.h"
#import "SessionViewController_iPhone.h"
#import "ActiveSessionsViewController.h"

#import "MainViewController.h"
#import "ChatViewController.h"
#import "SettingsViewController.h"
#import "SplashViewController.h"
#import "ActivityIndicatorViewController.h"

#import "QRScannerViewController.h"

//Private methods
@interface MainViewController ()

@property (nonatomic) BOOL isLogerActivated;
@property (nonatomic) BOOL showSplash;
@property (strong, nonatomic) SplashViewController* splashViewController;
@property (strong, nonatomic) NSTimer* waitingGestureTimer;
@property (strong, nonatomic) QRScannerViewController* qrScannerViewController;
@property (weak, nonatomic) SessionViewController_iPhone* currentlyVisibleViewController;

- (void) removeAllSubViews;
- (SessionTransitionStates) determineViewControllerTransitionStateForConversationID:(NSString*) conversationID replaceConversationID:(NSString*) replaceConversationID incomingCall:(BOOL) incomingCall incomingMessage:(BOOL) incomingMessage;

- (void)threeTapGasture;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.sessionViewControllersDictionary = [[NSMutableDictionary alloc] init];
        self.threeTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(threeTapGasture)];
        self.threeTapGestureRecognizer.delegate = self;
        self.threeTapGestureRecognizer.numberOfTapsRequired = 3;
        self.threeTapGestureRecognizer.numberOfTouchesRequired = 2;
        
        self.isLogerActivated = NO;
        self.showSplash = YES;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.threeTapGestureRecognizer)
        [self.view addGestureRecognizer:self.threeTapGestureRecognizer];
    
    //[self showSplashScreen];
  
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    if (self.threeTapGestureRecognizer)
    {
        [self.view removeGestureRecognizer:self.threeTapGestureRecognizer];
        self.threeTapGestureRecognizer = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self showSplashScreen];
    //self.splashViewController.view.frame = self.view.bounds;
    //[self.view addSubview:self.splashViewController.view];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) removeAllSubViews
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [[[self view] subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
}


- (void) showTabBarController
{
    //[self removeAllSubViews];
    [UITabBarItem.appearance setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor] } forState:UIControlStateNormal];
    [UITabBarItem.appearance setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor] }     forState:UIControlStateSelected];

    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"iPhone_top_bar_background.png"] forBarMetrics:UIBarMetricsDefault];
    
    if (!self.tabBarController)
    {
        self.contactsTableViewController = nil;
        
        //Contacts tab
        /*self.contactsTableViewController = [[ContactsViewController alloc] initWithNibName:@"ContactsViewController" bundle:nil];
        self.contactsTableViewController.title = @"Contacts";
        self.tabBarItem.title = @"CONTACTS";
        
        //[self.contactsTableViewController.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"iPhone_tabBar_contacts_active.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"iPhone_tabBar_contacts_inactive.png"]];
        
        
        [self.contactsTableViewController.tabBarItem setImage:[[UIImage imageNamed:@"iPhone_tabBar_contacts_inactive.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [self.contactsTableViewController.tabBarItem setSelectedImage:[[UIImage imageNamed:@"iPhone_tabBar_contacts_active.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];

         
        UINavigationController *contactsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.contactsTableViewController];
        contactsNavigationController.navigationBar.translucent = NO;
        contactsNavigationController.delegate = self;*/
        
        //Favorites tab
//        self.favoritesTableViewController = [[ContactsViewController alloc] initInFavoritesMode:YES allowMultipleSelection:NO];
        self.favoritesTableViewController = [[ContactsViewController alloc] initInMode:CONTACTS_TABLE_MODE_FAVORITES allowMultipleSelection:NO filterContacts:nil];
        self.favoritesTableViewController.title = @"Friends";
        self.tabBarItem.title = @"FRIENDS";
        
//        [self.favoritesTableViewController.tabBarItem setImage:[[UIImage imageNamed:@"iPhone_tabBar_favorites_inactive.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
//        [self.favoritesTableViewController.tabBarItem setSelectedImage:[[UIImage imageNamed:@"iPhone_tabBar_favorites_active.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        
        [self.favoritesTableViewController.tabBarItem setImage:[[UIImage imageNamed:@"iPhone_tabBar_contacts_inactive.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [self.favoritesTableViewController.tabBarItem setSelectedImage:[[UIImage imageNamed:@"iPhone_tabBar_contacts_active.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        
        UINavigationController *favoritesNavigationController = [[UINavigationController alloc] initWithRootViewController:self.favoritesTableViewController];
        favoritesNavigationController.navigationBar.translucent = NO;
        favoritesNavigationController.delegate = self;
        
        //Active sessions tab
        self.activeSessionsViewController = [[ActiveSessionsViewController alloc] initWithNibName:@"ActiveSessionsViewController" bundle:nil];
        self.activeSessionsViewController.title = @"Chats";
        self.tabBarItem.title = @"CHATS";
        
        //[self.contactsTableViewController.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"iPhone_tabBar_contacts_active.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"iPhone_tabBar_contacts_inactive.png"]];
        
        
        [self.activeSessionsViewController.tabBarItem setImage:[[UIImage imageNamed:@"iPhone_tabBar_sessions_inactive.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [self.activeSessionsViewController.tabBarItem setSelectedImage:[[UIImage imageNamed:@"iPhone_tabBar_sessions_active.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        
        
        UINavigationController *activeSessionsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.activeSessionsViewController];
        activeSessionsNavigationController.navigationBar.translucent = NO;
        activeSessionsNavigationController.delegate = self;
        
        //Settings tab
        SettingsViewController* settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        settingsViewController.title = @"Settings";
        self.tabBarItem.title = @"SETTINGS";
            
        //[settingsViewController.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"iPhone_tabBar_settings_active_Icon.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"iPhone_tabBar_settings_inactive_Icon.png"]];
        
        [settingsViewController.tabBarItem setImage:[[UIImage imageNamed:@"iPhone_tabBar_settings_inactive_Icon.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [settingsViewController.tabBarItem setSelectedImage:[[UIImage imageNamed:@"iPhone_tabBar_settings_active_Icon.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        
        UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
        //settingsNavigationController.delegate = self;
        
        //Tab
        self.tabBarController = [[UITabBarController alloc] init];
        self.tabBarController.delegate = self;
        self.tabBarController.viewControllers = [NSArray arrayWithObjects:/*contactsNavigationController,*/ favoritesNavigationController, activeSessionsNavigationController,settingsNavigationController, nil];
        
        self.tabBarController.view.frame = self.view.bounds;

        [self.tabBarController.tabBar setBackgroundImage:[UIImage imageNamed:@"iPhone_tabBar_3_bkgd.png"]];
    }
    
    self.tabBarController.view.alpha = 0.0;
    [self.view addSubview:self.tabBarController.view];
    
    
    [UIView animateWithDuration:1 animations:^
     {
         [self.tabBarController.view setAlpha:1.0];
     }
     completion:nil];
}

- (void) popLastConversationViewController
{
    int tabIndex = [self.tabBarController selectedIndex] < 3 ? [self.tabBarController selectedIndex] : 2;
    
    UINavigationController* navigationController = (UINavigationController*)[[self.tabBarController viewControllers] objectAtIndex:tabIndex];
    
    [navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Login views
/**
 Show web view with opened login page.
 @param url NSString Login page url.
*/
- (void) showWebLoginView:(WebLoginViewController*) webLoginViewController
{
    if (webLoginViewController)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Show WebLoginViewController <%p>",webLoginViewController);
        webLoginViewController.view.frame = self.view.bounds;
        webLoginViewController.view.hidden = NO;
        [webLoginViewController.view setAlpha:0];
        
        [UIView animateWithDuration:1 animations:^
        {
            [webLoginViewController.view setAlpha:1];
            [self.view addSubview:webLoginViewController.view];
        }
        completion:nil];
    }
}

- (void) closeWebLoginView:(WebLoginViewController*) webLoginViewController
{
    if (webLoginViewController)
    {
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Close WebLoginViewController <%p>",webLoginViewController);
        
        [UIView animateWithDuration:1 animations:^
         {
             [webLoginViewController.view setAlpha:0];
         }
        completion:^(BOOL finished)
        {
            [webLoginViewController.view removeFromSuperview];
        }];
    }
}

- (void) pushSessionViewController:(SessionViewController_iPhone*) sessionViewController navigationController:(UINavigationController*) navigationController
{
    self.currentlyVisibleViewController = sessionViewController;
//    [[NSNotificationCenter defaultCenter] addObserver:self.currentlyVisibleViewController selector:@selector(onConversationViewShown) name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self.currentlyVisibleViewController selector:@selector(onConversationViewHidden) name:UIApplicationWillResignActiveNotification object:nil];
    [navigationController pushViewController:sessionViewController animated:YES];
}

- (void) popSessionViewControllerForNavigationController:(UINavigationController*) navigationController
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self.currentlyVisibleViewController name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self.currentlyVisibleViewController name:UIApplicationWillResignActiveNotification object:nil];
    self.currentlyVisibleViewController = nil;
    [navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Session view
/**
 Show session view.
 @param session Session which needs to be displyed
 @param incomingCall BOOL - Yes if it is session with incoming call, otherwise NO
 @param incomingMessage BOOL - Yes if it is session with incoming message, otherwise NO
 */
- (BOOL) showSessionViewControllerForConversation:(HOPConversation*) conversation replaceConversation:(HOPConversation*) replaceConversation incomingCall:(BOOL) incomingCall incomingMessage:(BOOL) incomingMessage
{
    BOOL ret = NO;
    if (!conversation)
        return ret;
    
    SessionViewController_iPhone* sessionViewContorller = nil;
    NSString* conversationID = conversation.conversationID.length > 0 ? conversation.conversationID : @"";
    NSString* replaceConversationID = replaceConversation.conversationID.length > 0 ? replaceConversation.conversationID : @"";
    
    SessionTransitionStates transition = [self determineViewControllerTransitionStateForConversationID:conversationID replaceConversationID:replaceConversationID incomingCall:incomingCall incomingMessage:incomingMessage];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Transition %d for session with id:%@ and for participant:%@",transition,conversationID,[[SessionManager sharedSessionManager] getNavigationTitleForConversation:conversation]);
    UINavigationController* navigationController = nil;
    
    int tabIndex = [self.tabBarController selectedIndex] < 3 ? [self.tabBarController selectedIndex] : 2;
    
    [self.tabBarController setSelectedIndex:tabIndex];
    
    navigationController = (UINavigationController*)[[self.tabBarController viewControllers] objectAtIndex:tabIndex];
    
    switch (transition)
    {
        case NEW_SESSION:
        case NEW_SESSION_SWITCH:
        {
            [self popSessionViewControllerForNavigationController:navigationController];
        }
        case NEW_SESSION_WITH_CHAT:
        {
            sessionViewContorller = [[SessionViewController_iPhone alloc] initWithConversation:conversation];
            sessionViewContorller.hidesBottomBarWhenPushed = YES;
            [self.sessionViewControllersDictionary setObject:sessionViewContorller forKey:conversationID];
            [self pushSessionViewController:sessionViewContorller navigationController:navigationController];
            sessionViewContorller.chatViewController.title = [[SessionManager sharedSessionManager] getNavigationTitleForConversation:conversation];
            ret = YES;
        }
            break;
            
        case NEW_SESSION_WITH_CALL:
            sessionViewContorller = [[SessionViewController_iPhone alloc] initWithConversation:conversation];
            sessionViewContorller.hidesBottomBarWhenPushed = YES;
            [self.sessionViewControllersDictionary setObject:sessionViewContorller forKey:conversationID];
            [self pushSessionViewController:sessionViewContorller navigationController:navigationController];
            sessionViewContorller.chatViewController.title = [[SessionManager sharedSessionManager] getNavigationTitleForConversation:conversation];
            ret = YES;
            break;
            
        case NEW_SESSION_REFRESH_CHAT:
        {
            sessionViewContorller = [[SessionViewController_iPhone alloc] initWithConversation:conversation];
            [self.sessionViewControllersDictionary setObject:sessionViewContorller forKey:conversationID];
            
            [self showNotification:[NSString stringWithFormat:@"New message from %@",[[SessionManager sharedSessionManager] getNavigationTitleForConversation:conversation]]];
        }
            break;
            
        case EXISITNG_SESSION_SWITCH:
            sessionViewContorller = [self.sessionViewControllersDictionary objectForKey:conversationID];
            sessionViewContorller.hidesBottomBarWhenPushed = YES;
            [self popSessionViewControllerForNavigationController:navigationController];
            [self pushSessionViewController:sessionViewContorller navigationController:navigationController];
            sessionViewContorller.chatViewController.title = [[SessionManager sharedSessionManager] getNavigationTitleForConversation:conversation];
            ret = YES;
            break;
            
        case EXISTING_SESSION_REFRESH_NOT_VISIBLE_CHAT:
            [self showNotification:[NSString stringWithFormat:@"New message from %@",[[SessionManager sharedSessionManager] getNavigationTitleForConversation:conversation]]];
            break;
            
        case EXISTING_SESSION_REFRESH_CHAT:
            ret = YES;
            break;
            
        case EXISTIG_SESSION_SHOW_CHAT:
            sessionViewContorller = [self.sessionViewControllersDictionary objectForKey:conversationID];
            if (self.currentlyVisibleViewController != sessionViewContorller)
            {
                [self popSessionViewControllerForNavigationController:navigationController];
            }
            [self pushSessionViewController:sessionViewContorller navigationController:navigationController];
            ret = YES;
            break;
            
        case INCOMING_CALL_WHILE_OTHER_INPROGRESS:
            [self showNotification:[NSString stringWithFormat:@"%@ is trying to reach you.",[[SessionManager sharedSessionManager] getNavigationTitleForConversation:conversation]]];
            break;
            
        case REPLACE_EXISTING_SESSION:
            sessionViewContorller = [self.sessionViewControllersDictionary objectForKey:conversationID];
            if (!sessionViewContorller)
            {
                sessionViewContorller = [[SessionViewController_iPhone alloc] initWithConversation:conversation];
                [self.sessionViewControllersDictionary setObject:sessionViewContorller forKey:conversationID];
            }
            sessionViewContorller.hidesBottomBarWhenPushed = YES;
            [self popSessionViewControllerForNavigationController:navigationController];
            [self pushSessionViewController:sessionViewContorller navigationController:navigationController];
            sessionViewContorller.chatViewController.title = [[SessionManager sharedSessionManager] getNavigationTitleForConversation:conversation];
            ret = YES;
            break;
            
        case EXISTING_SESSION:
        default:
            break;
    }
    
    return ret;
}

- (SessionTransitionStates) determineViewControllerTransitionStateForConversationID:(NSString*) conversationID replaceConversationID:(NSString*) replaceConversationID incomingCall:(BOOL) incomingCall incomingMessage:(BOOL) incomingMessage
{
    //If session view controller is laredy created for this session get it from dictionary
    SessionViewController_iPhone* sessionViewContorller = [self.sessionViewControllersDictionary objectForKey:conversationID];
    SessionViewController_iPhone* sessionViewContorllerToReplace = replaceConversationID.length > 0 ? [self.sessionViewControllersDictionary objectForKey:replaceConversationID] : nil;
    UINavigationController* navigationController = nil;

    int tabIndex = [self.tabBarController selectedIndex] < 3 ? [self.tabBarController selectedIndex] : 2;
    
    navigationController = (UINavigationController*)[[self.tabBarController viewControllers] objectAtIndex:tabIndex];
    
    if (!sessionViewContorller)
    {
        if (incomingCall)
        {
            if ([[SessionManager sharedSessionManager] isCallInProgress])
                return INCOMING_CALL_WHILE_OTHER_INPROGRESS; //Cannot have two active calls at once
            else
            {
                if (self.currentlyVisibleViewController)
                    return NEW_SESSION_SWITCH; //Incoming call has priority over chat session, so switch from currently active session to new with incoming call
                else
                    return NEW_SESSION_WITH_CALL; //Create and show a new session with incomming call
            }
            
        }
        else if (incomingMessage)
        {
            if (self.currentlyVisibleViewController)
                return NEW_SESSION_REFRESH_CHAT; //Create a new session and update chat, but don't switch from existing session
            else
                return NEW_SESSION_WITH_CHAT; //Create and show a new session with incomming message
        }
        else
        {
            if (sessionViewContorllerToReplace && sessionViewContorllerToReplace == self.currentlyVisibleViewController)                return REPLACE_EXISTING_SESSION;
            else if (sessionViewContorllerToReplace && sessionViewContorllerToReplace != self.currentlyVisibleViewController)
                return EXISTING_SESSION; //Incoming call for currenlty displayed session so don't change anything
            else
                return NEW_SESSION; //Create and show a new session
        }
        
    }
    else
    {
        if (incomingCall)
        {
            if ([[SessionManager sharedSessionManager] isCallInProgress])
                return ERROR_CALL_ALREADY_IN_PROGRESS; //Cannot have two active calls at once
            else
            {
                if (self.currentlyVisibleViewController == sessionViewContorller)
                    return EXISTING_SESSION; //Incoming call for currenlty displayed session so don't change anything
                else
                    return EXISITNG_SESSION_SWITCH; //Incoming call for session that is not displayed at the moment so swith to that session
            }
        }
        else if (incomingMessage)
        {
            if (self.currentlyVisibleViewController == sessionViewContorller)
            {
                if ([[SessionManager sharedSessionManager] isCallInProgress])
                    return EXISTING_SESSION_REFRESH_CHAT; //Incoming message for session with active call. Just refresh list of messages but don't display chat view
                else
                    return EXISTING_SESSION_REFRESH_CHAT;

            }

            else if (!self.currentlyVisibleViewController)
            {
                return EXISITNG_SESSION_SWITCH; //Move from the contacts list to the chat view for session
            }
            else
            {
                return EXISTING_SESSION_REFRESH_NOT_VISIBLE_CHAT; //Move from the contacts list to the chat view for session
            }
        }
        else
        {
            return EXISITNG_SESSION_SWITCH; //Switch to exisitng session
        }
    }
}


/**
 Remove specific session view controller from the dictionary.
 @param sessionId NSString session id
 */
- (void) removeSessionViewControllerForSession:(NSString*) sessionId
{
    [self.sessionViewControllersDictionary removeObjectForKey:sessionId];
}

- (void) removeAllSessionViewControllers
{
    for (SessionViewController_iPhone* controller in self.sessionViewControllersDictionary.allValues)
    {
        [controller.chatViewController killTimers];
    }
    
    [self.sessionViewControllersDictionary removeAllObjects];
}

- (void) updateSessionViewControllerId:(NSString*) oldSessionId newSesionId:(NSString*) newSesionId
{
    SessionViewController_iPhone* svc = [self.sessionViewControllersDictionary objectForKey:oldSessionId];
    if (svc)
    {
        [self.sessionViewControllersDictionary setObject:svc forKey:newSesionId];
        //[self removeSessionViewControllerForSession:oldSessionId];
        [svc.chatViewController updateFetchControllerForSession:newSesionId];
    }
}
/**
 Prepare specific session vire controller for incoming call
 @param session Session with incomming call
 */
- (void) showIncominCallForConversation:(HOPConversation*) conversation
{
    SessionViewController_iPhone* sessionViewContorller = [self.sessionViewControllersDictionary objectForKey:[conversation getConversationID]];
    [sessionViewContorller showIncomingCall:YES];
    //[sessionViewContorller prepareForIncomingCall];
}



- (void) showNotification:(NSString*) message
{
    UINavigationController* navigationController = (UINavigationController*)[[self.tabBarController viewControllers] objectAtIndex:[self.tabBarController selectedIndex]];
    
    UILabel* labelNotification = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 20.0, self.view.frame.size.width - 10.0, 40.0)];
    labelNotification.text = message;//[NSString stringWithFormat:@"New message from %@",contactName];
    labelNotification.textAlignment = NSTextAlignmentCenter;
    labelNotification.textColor = [UIColor whiteColor];
    labelNotification.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7];
    [navigationController.visibleViewController.view addSubview:labelNotification];
    
    [UIView animateWithDuration:0.5 delay:2.0 options:0 animations:^{
        // Animate the alpha value of your imageView from 1.0 to 0.0 here
        labelNotification.alpha = 0.0f;
    } completion:^(BOOL finished) {
        // Once the animation is completed and the alpha has gone to 0.0, hide the view for good
        [labelNotification removeFromSuperview];
    }];
}


- (void)threeTapGasture
{
    @synchronized(self)
    {
        if (self.waitingGestureTimer)
        {
            [self.waitingGestureTimer invalidate];
            self.waitingGestureTimer = nil;
            [self showQRScanner];
            [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
        }
        else
        {
            [Logger startTelnetLoggerOnStartUp];
        }
    }
}

- (void) removeSplashScreen
{
    [UIView animateWithDuration:1 animations:^
     {
         [self.splashViewController.view setAlpha:0.0];
     }
     completion:^(BOOL finished)
     {
         [self.splashViewController.view removeFromSuperview];
         self.splashViewController = nil;
     }];
    
}

- (void) onLogout
{
    //[self removeAllSubViews];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace,@"Remove all session view controllers");
    [self removeAllSessionViewControllers];
    
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace,@"Show splash view");
    [self showSplashScreen];
    self.contactsTableViewController = nil;
    self.tabBarController = nil;
}

- (void) onContactsLoadingStarted
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Getting contacts ..." inView:self.view];
}


#pragma mark LoginEventsDelegate
- (void)onStartLoginWithidentityURI
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Getting identity login url ..." inView:self.splashViewController.infoView];
}

- (void) onOpeningLoginPage
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Opening login page ..." inView:self.splashViewController.infoView];
}

- (void) onLoginWebViewVisible:(WebLoginViewController*) webLoginViewController
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
    
    //[self removeSplashScreen];
    
    //Add identity login web view like main view subview
    if (!webLoginViewController.view.superview)
        [self showWebLoginView:webLoginViewController];
}

- (void)onRelogin
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Relogin ..." inView:self.splashViewController.infoView];
}

- (void) onLoginFinished
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Updating main view controller on successfull login.");
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
    [self removeSplashScreen];
    [self showTabBarController];
}

- (void) onIdentityLoginWebViewClose:(WebLoginViewController*) webLoginViewController forIdentityURI:(NSString*) identityURI
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:[NSString stringWithFormat:@"Login identity: %@",identityURI] inView:self.view];
    [self closeWebLoginView:webLoginViewController];
}

- (void) onIdentityLoginFinished
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
}

- (void) onIdentityLoginError:(NSString*) error
{
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Identity login error: %@",error);
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Identity login error: %@",error] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    
}

- (void) onIdentityLoginShutdown
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
}

- (void) onAccountLoginError:(NSString *)error
{
    OPLog(HOPLoggerSeverityError, HOPLoggerLevelTrace, @"Account login error: %@",error);
    
    if ([self.splashViewController.infoView superview])
        [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Error. Please restart the application" inView:self.splashViewController.infoView];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@. Please check your internet connection and restart the application.",error] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    
}

- (void) onNetworkProblem
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Please, check your internet connection." inView:self.splashViewController.infoView];
}

- (void) onNetworkProblemResolved
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Recoverying from network lost ..." inView:self.view];
}

- (void) onAccountLoginWebViewClose:(WebLoginViewController*) webLoginViewController
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:nil withText:nil inView:nil];
    [self closeWebLoginView:webLoginViewController];
}

- (void) showQRScanner
{
    self.qrScannerViewController = [[QRScannerViewController alloc] initWithNibName:@"QRScannerViewController" bundle:nil];
    self.qrScannerViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.qrScannerViewController.view];
}

- (void) showSplashScreen
{
    if (!self.splashViewController)
    {
        self.splashViewController = [[SplashViewController alloc] initWithNibName:@"SplashViewController" bundle:nil];
        self.splashViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    
    self.splashViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.splashViewController.view];
}

- (void) waitingGestureTimerHasExpired
{
    @synchronized(self)
    {
        if (self.waitingGestureTimer)
        {
            self.waitingGestureTimer = nil;
            [[OpenPeer sharedOpenPeer] setup];
            //[[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
        }
    }
}

- (void) waitForUserGesture
{
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:YES withText:@"Loading settings ..." inView:self.splashViewController.infoView];
    
    self.waitingGestureTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                     target:self
                                   selector:@selector(waitingGestureTimerHasExpired)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if ([viewController isKindOfClass:[ContactsViewController class]] || [viewController isKindOfClass:[ActiveSessionsViewController class]] || [viewController isKindOfClass:[SettingsViewController class]])
        self.currentlyVisibleViewController = nil;
    else if ([viewController isKindOfClass:[SessionViewController_iPhone class]])
        self.currentlyVisibleViewController = (SessionViewController_iPhone*)viewController;
}

- (void) changeKeyForViewController:(NSString*) oldKey newKey:(NSString*) newKey
{
    if (oldKey.length > 0 && newKey.length > 0)
    {
        SessionViewController_iPhone* controller = [self.sessionViewControllersDictionary objectForKey:oldKey];
        if (controller)
        {
            [self.sessionViewControllersDictionary setObject:controller forKey:newKey];
            [controller.chatViewController refreshMessages];
        }
    }
}
@end
