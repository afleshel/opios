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

#import "AddParticipantsViewController.h"
#import "ContactsViewController.h"
#import "SessionManager.h"
#import "OpenPeer.h"
#import "MainViewController.h"
#import "MessageManager.h"

//#import "Session.h"
//#import <OpenPeerSDK/HOPConversationEvent+External.h>
#import <OpenPeerSDK/HOPConversation.h>

@interface AddParticipantsViewController ()

@property (nonatomic, strong) ContactsViewController *contactsViewController;
@property (nonatomic, strong) UIBarButtonItem* menuRightbarButton;
@property (nonatomic, weak) HOPConversation* conversation;
@property (nonatomic) BOOL isAdding;
- (void) actionDoneWithSelection;
@end

@implementation AddParticipantsViewController

- (id) initWithConversation:(HOPConversation*) inConversation addingContacts:(BOOL) addingContacts
{
    self = [self init];
    if (self)
    {
        self.conversation = inConversation;
        self.isAdding = addingContacts;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"iPhone_back_button.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: backButton];
    
    self.menuRightbarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionDoneWithSelection)];
    self.navigationItem.rightBarButtonItem = self.menuRightbarButton;
    
    self.navigationItem.title = self.isAdding ? @"Add participants" : @"Remove participants";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    ContactsTableModes mode = self.isAdding ? CONTACTS_TABLE_MODE_ADDING : CONTACTS_TABLE_MODE_REMOVING;
    self.contactsViewController = [[ContactsViewController alloc] initInMode:mode allowMultipleSelection:YES filterContacts:self.conversation.participants];
    self.contactsViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.contactsViewController.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) actionDoneWithSelection
{
    HOPConversation* newConversation = nil;
    if (self.contactsViewController.getSelectedContacts.count > 0)
    {
        if (self.isAdding)
            newConversation = [HOPConversation conversationOnParticipantsAdded:[self.contactsViewController.getSelectedContacts valueForKey:@"contact"] conversation:self.conversation];
        else
            newConversation = [HOPConversation conversationOnParticipantsRemoved:[self.contactsViewController.getSelectedContacts valueForKey:@"contact"] conversation:self.conversation];
    }
    
    if (newConversation != self.conversation)
    {
        [[MessageManager sharedMessageManager] sendSystemForSwitchFromConversation:self.conversation toConversation:newConversation];
        [[[OpenPeer sharedOpenPeer] mainViewController] popLastConversationViewController];
        [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:newConversation replaceConversation:nil incomingCall:NO incomingMessage:NO];
    }
    else
    {
        [self.delegate updateOnParticipantChange];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
