/*
 
 Copyright (c) 2013, SMB Phone Inc.
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

#import "ChatViewController.h"
#import <UIKit/UIKit.h>

#import "MessageManager.h"
#import "ChatMessageCell.h"
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPMessageRecord+External.h>
#import <OpenPeerSDK/HOPConversation.h>
#import <OpenPeerSDK/HOPCallSystemMessage.h>
#import <OpenPeerSDK/HOPIdentity+External.h>
#import <OpenPeerSDK/HOPContact+External.h>
#import "SystemMessageCell.h"
#import "ChatCell.h"

@interface ChatViewController()

@property (weak, nonatomic) HOPConversation* conversation;
@property (nonatomic, copy) NSString* predicateString;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (weak, nonatomic) NSDictionary* userInfo;
@property (nonatomic) BOOL keyboardIsHidden;
@property (nonatomic) BOOL isRefreshed;
@property (nonatomic) BOOL isFirstRun;
@property (nonatomic) BOOL isComposing;
@property (nonatomic) CGFloat keyboardLastChange;
@property (nonatomic,strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic,strong) UISwipeGestureRecognizer *swipeGestureLeft;
@property (nonatomic,strong) UISwipeGestureRecognizer *swipeGestureRight;

@property (nonatomic,strong) NSMutableDictionary* dictionaryComposingStatuses;

@property (nonatomic,strong) NSTimer *pauseTimer;
@property (nonatomic,strong) NSDate *latestUserActivity;

@property (nonatomic,weak) IBOutlet UILabel *labelComposingStatus;

@property (nonatomic, weak) HOPMessageRecord* messageToEdit;

- (void) registerForNotifications:(BOOL)registerForNotifications;

- (void) sendIMmessage:(NSString *)message;

- (IBAction) sendButtonPressed:(id) sender;

@end

@implementation ChatViewController


#pragma mark init/dealloc
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.dictionaryComposingStatuses = [ [NSMutableDictionary alloc] init];
    }
    return self;
}

- (id) initWithConversation:(HOPConversation*)inConversation
{
    self = [self initWithNibName:@"ChatViewController" bundle:nil];
    {
        self.conversation = inConversation;
        self.isComposing = NO;
    }
    
    return self;
}


#pragma mark - Memory
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.keyboardIsHidden = YES;
    self.isFirstRun = YES;
    //[self.chatTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    //[self.typingMessageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    //[self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.chatTableView.backgroundColor = [UIColor clearColor];
    self.chatTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.messageTextbox setReturnKeyType:UIReturnKeySend];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    self.tapGesture.numberOfTapsRequired = 1;
    
    [self.messageTextbox becomeFirstResponder];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
		OPLog(HOPLoggerSeverityFatal, HOPLoggerLevelDebug, @"Fetching messages has failed with an error: %@, error description: %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    
    self.tapGesture.cancelsTouchesInView = NO;
    
    self.swipeGestureLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftSwipe:)];
    self.swipeGestureLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.chatTableView addGestureRecognizer:self.swipeGestureLeft];
    
    self.swipeGestureRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)];
    self.swipeGestureRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.chatTableView addGestureRecognizer:self.swipeGestureRight];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForNotifications:YES];
    self.chatTableView.tableFooterView.backgroundColor = [UIColor clearColor];

    [self.conversation markAllMessagesRead];
    self.conversation.numberOfUnreadMessages = 0;
    //[self.session.unreadMessageArray removeAllObjects];
}


- (void) updateComposingStatuses
{
    NSString* statusString = @"";
    NSMutableDictionary* tempDict = [NSMutableDictionary new];
    
    for (NSNumber* value in [self.dictionaryComposingStatuses allValues])
    {
        NSMutableArray* array = [NSMutableArray new];
        [tempDict setObject:array forKey:value];
    }
    
    for (NSString* key in [self.dictionaryComposingStatuses allKeys])
    {
        NSNumber* value = [self.dictionaryComposingStatuses objectForKey:key];
        [[tempDict objectForKey:value] addObject:key];
    }
    
    for (NSNumber* key in [tempDict allKeys])
    {
        NSArray* participants = [tempDict objectForKey:key];
        
        for (NSString* peerURI in participants)
        {
            HOPIdentity* identity = [[[HOPModelManager sharedModelManager] getIdentitiesByPeerURI:peerURI] objectAtIndex:0];
            if (statusString.length == 0)
                statusString = identity.name;
            else
                statusString = [statusString stringByAppendingFormat:@", %@",identity.name];
        }
        
        switch (key.intValue)
        {
            case HOPComposingStateComposing:
            {
                if (participants.count == 1)
                    statusString = [statusString stringByAppendingString:@" is typing..."];
                else
                    statusString = [statusString stringByAppendingString:@" are typing..."];
                    
            }
                break;
              
            case HOPComposingStatePaused:
            {
                if (participants.count == 1)
                    statusString = [statusString stringByAppendingString:@" is thinking..."];
                else
                    statusString = [statusString stringByAppendingString:@" are thinking..."];
                
            }
                break;
            default:
                statusString = @"";
                break;
        }
    }
    
    self.labelComposingStatus.text = statusString;
}

- (void) updatedComposingStatus:(NSNotification *)notification
{
    NSDictionary* object = notification.object;
    
    HOPConversation* hopConversation = [object objectForKey:@"thread"];
    if (self.conversation == hopConversation)
    {
        HOPContact* contact = [object objectForKey:@"contact"];
        NSNumber* status = [object objectForKey:@"status"];

        [self.dictionaryComposingStatuses setObject:status forKey:[contact getPeerURI]];
     
        [self updateComposingStatuses];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.messageTextbox resignFirstResponder];
    [self registerForNotifications:NO];
    [self.chatTableView removeGestureRecognizer:self.tapGesture];
}


- (void) hideKeyboard
{
    [self.messageTextbox resignFirstResponder];
}

- (void) setFramesSizesForUserInfo:(NSDictionary*) userInfo
{
    CGFloat keyboardHeight = 0;
    
    if (userInfo != nil)
    {
        CGRect keyboardFrame;
        NSValue *ks = [userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey];
        keyboardFrame = [ks CGRectValue];
        keyboardHeight = self.keyboardIsHidden ? 0 : keyboardFrame.size.height;
        
        NSTimeInterval animD;
        UIViewAnimationCurve animC;
        
        [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animC];
        [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animD];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration: animD];
        [UIView setAnimationCurve:animC];
    }
    
    // set initial size, chat view
    CGRect contactsTableViewRect = self.chatTableView.frame;
    
    if (!self.keyboardIsHidden)
        contactsTableViewRect.size.height = self.view.frame.size.height - self.typingMessageView.viewForBaselineLayout.frame.size.height - keyboardHeight - 20.0;
    else
        contactsTableViewRect.size.height = self.view.frame.size.height - self.typingMessageView.viewForBaselineLayout.frame.size.height - 20.0;
    
    if (self.isFirstRun)
    {
        contactsTableViewRect.size.height+=160.0; //Temporary hack
        self.isFirstRun = NO;
    }
    self.chatTableView.frame = contactsTableViewRect;
    
    
    if (userInfo)
        [UIView commitAnimations];
}

#pragma mark - Keyboard handling
-(void)resetKeyboard:(NSNotification *)notification
{
    self.keyboardIsHidden = NO;
}

-(void)keyboardWillShow:(NSNotification *)notification
{
    [self.chatTableView addGestureRecognizer:self.tapGesture];
    if (self.keyboardIsHidden)
    {
        self.keyboardIsHidden = NO;
        [self.delegate prepareForKeyboard:[notification userInfo] showKeyboard:YES];
        [self setFramesSizesForUserInfo:[notification userInfo]];
        
        if ([[[self fetchedResultsController] fetchedObjects] count] > 0)
            [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[[self fetchedResultsController] fetchedObjects] count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [self.chatTableView addGestureRecognizer:self.tapGesture];
    self.keyboardIsHidden = YES;
    [self.delegate prepareForKeyboard:[notification userInfo] showKeyboard:NO];
    [self setFramesSizesForUserInfo:[notification userInfo]];
}


#pragma mark - Actions
- (IBAction) sendButtonPressed : (id) sender
{
    if ([self.messageTextbox.text length] > 0)
        [self sendIMmessage:self.messageTextbox.text];
}


- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint location = [sender locationInView:self.chatTableView];
        NSIndexPath *swipedIndexPath = [self.chatTableView indexPathForRowAtPoint:location];
        ChatMessageCell *swipedCell  = (ChatMessageCell*)[self.chatTableView cellForRowAtIndexPath:swipedIndexPath];
        
        if (![swipedCell.message.type isEqualToString:[HOPSystemMessage getMessageType]] && !swipedCell.message.sender && !swipedCell.message.removed.boolValue && swipedCell.message.outgoingMessageStatus == HOPConversationThreadMessageDeliveryStateUserNotAvailable)
        {
            [[MessageManager sharedMessageManager] resendMessage:swipedCell.message conversation:self.conversation];
            
        }
        else
        {
            [self.messageTextbox resignFirstResponder];
        }
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITextViewDelegate
- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        if ([textView.text length] > 0)
            [self sendIMmessage:textView.text];
        return NO;
    }
    
    if (!self.isComposing && [text length] > 0)
    {
        [self setStatusToComposing];
    }
    else if ([text length] == 0 && [textView.text length] <= 1)
    {
        [self setStatusToActive];
    }
    
    self.latestUserActivity = [NSDate date];
    return YES;
}

- (void) setStatusToComposing
{
    self.isComposing = YES;
    [self.conversation setComposingState:HOPComposingStateComposing];
    [self.pauseTimer invalidate];
    self.pauseTimer = nil;
    self.pauseTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(setStatusToPause) userInfo:nil repeats:NO];
}

- (void) setStatusToActive
{
    [self.conversation setComposingState:HOPComposingStateActive];
    [self.pauseTimer invalidate];
    self.pauseTimer = nil;
    self.isComposing = NO;
    self.pauseTimer = [NSTimer scheduledTimerWithTimeInterval:240 target:self selector:@selector(setStatusToInactive) userInfo:nil repeats:NO];
}

- (void) setStatusToPause
{
    [self.conversation setComposingState:HOPComposingStatePaused];
    [self.pauseTimer invalidate];
    self.pauseTimer = nil;
    self.isComposing = NO;
    self.pauseTimer = [NSTimer scheduledTimerWithTimeInterval:210 target:self selector:@selector(setStatusToInactive) userInfo:nil repeats:NO];
}

- (void) setStatusToInactive
{
    [self.conversation setComposingState:HOPComposingStateInactive];
    [self.pauseTimer invalidate];
    self.pauseTimer = nil;
    self.pauseTimer = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(setStatusToGone) userInfo:nil repeats:NO];
}

- (void) setStatusToGone
{
    [self.conversation setComposingState:HOPComposingStateInactive];
    [self.pauseTimer invalidate];
    self.pauseTimer = nil;
    //self.pauseTimer = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(setStatusToGone) userInfo:nil repeats:NO];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self setStatusToActive];
}

- (void) refreshViewWithData
{
    self.conversation.numberOfUnreadMessages = 0;
    
    if (!self.isRefreshed)
    {
        [self.chatTableView reloadData];
        
        if ([[[self fetchedResultsController] fetchedObjects] count] > 0)
            [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[[self fetchedResultsController] fetchedObjects] count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    self.isRefreshed = NO;
}

- (void) updateFetchControllerForSession:(NSString*) sessionID
{
    NSFetchRequest *fetchRequest = [[self fetchedResultsController] fetchRequest];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPMessageRecord" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSPredicate* predicate1 = [fetchRequest predicate];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(session.sessionID MATCHES '%@')",[self.conversation getConversationID]]];
                              
    [fetchRequest setPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate1,predicate2, nil]]];
    
	[fetchRequest setFetchBatchSize:20];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
		OPLog(HOPLoggerSeverityFatal, HOPLoggerLevelDebug, @"Fetching messages has failed with an error: %@, error description: %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    
    [self.chatTableView reloadData];
}

- (void) registerForNotifications:(BOOL)registerForNotifications
{
    if (registerForNotifications)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedComposingStatus:) name:notificationComposingStatusChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationComposingStatusChanged object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}


#pragma mark - Table Data Source Methods
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.fetchedResultsController fetchedObjects] count];
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //ChatCell* msgCell = nil;
    UITableViewCell* msgCell = nil;
    HOPMessageRecord* message = nil;
    
    message = [self.fetchedResultsController objectAtIndexPath:indexPath];

    if (!message)
        return nil;
    
    BOOL isSystemMessage = [message.type isEqualToString:[HOPSystemMessage getMessageType]];
    if (isSystemMessage)
    {
        msgCell = [tableView dequeueReusableCellWithIdentifier:@"MessageSystemCellIdentifier"];
    }
    else
    {
//        if (message.deleted.boolValue)
//            msgCell = [tableView dequeueReusableCellWithIdentifier:@"DeletedMessageCellIdentifier"];
//        else
            msgCell = [tableView dequeueReusableCellWithIdentifier:@"MessageCellIdentifier"];
    }
    
    //ChatMessageCell* msgCell = [tableView dequeueReusableCellWithIdentifier:@"MessageCellIdentifier"];
    
    if (msgCell == nil)
    {
//        if (!message.deleted.boolValue)
        {
            if (isSystemMessage)
                msgCell = [[SystemMessageCell alloc] initWithFrame:CGRectZero];
            else
                msgCell = [[ChatMessageCell alloc] initWithFrame:CGRectZero];
            
            ((ChatCell*)msgCell).messageLabel.delegate = self;
        }
//        else
//        {
//            msgCell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
//            msgCell.backgroundColor = [UIColor clearColor];
//            msgCell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13.0];
//            msgCell.textLabel.textColor = [UIColor grayColor];
//        }
    }
    
    
    if ([[msgCell class] isSubclassOfClass:[ChatCell class]])
        [((ChatCell*)msgCell) setMessage:message];
//    else
//        msgCell.textLabel.text = @"This message has been removed.";
    
    return msgCell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    float res = 0.0;

    HOPMessageRecord* message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    CGSize textSize;
    if ([message.type isEqualToString:[HOPSystemMessage getMessageType]])
        textSize= [ChatCell calcMessageHeight:@"system message" forScreenWidth:self.chatTableView.frame.size.width - 85];
    else
        textSize= [ChatCell calcMessageHeight:message.text forScreenWidth:self.chatTableView.frame.size.width - 85];

    textSize.height += 52;
    
    res = (textSize.height < 52) ? 52 : textSize.height;
    
    return res;
}


- (void) sendIMmessage:(NSString *)message
{
    [self setStatusToActive];
    if ([message length] > 0 && ![message isEqualToString:self.messageToEdit.text])
    {
        NSString* messageIDToReplace = self.messageToEdit && self.messageToEdit.text.length > 0 ? self.messageToEdit.messageID : @"";
        [[MessageManager sharedMessageManager] sendMessage:message replacesMessageID:messageIDToReplace forConversation:self.conversation];
        //just to skip sending composing
        self.isComposing = YES;
        self.messageTextbox.text = nil;
        self.isComposing = NO;
        self.messageToEdit = nil;
    }
}

#pragma mark - NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[HOPModelManager sharedModelManager] getMessagesFetchRequestForConversation:self.conversation sortAscending:YES];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
    
    _fetchedResultsController.delegate = self;
    
	return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.chatTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:NO];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.chatTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:NO];
            break;
            
            default:
            break;
    }
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    self.isRefreshed = YES;
    switch (type)
    {
		case NSFetchedResultsChangeInsert:
			[self.chatTableView  insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.chatTableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            //View is visible, so mark message as read
            if (self.isViewLoaded && self.view.window)
            {
                [self.conversation markAllMessagesRead];
            }
			break;
		case NSFetchedResultsChangeUpdate:
        {
            ChatMessageCell *cellForUpdate  = (ChatMessageCell*)[self.chatTableView cellForRowAtIndexPath:indexPath];
            HOPMessageRecord* message = [self.fetchedResultsController objectAtIndexPath:indexPath];
            [cellForUpdate setMessage:message];
        }
			break;
		case NSFetchedResultsChangeDelete:
			[self.chatTableView  deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeMove:
			[self.chatTableView  deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.chatTableView  insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
    
    
}

#pragma mark - TTTAttributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if (url)
        [[UIApplication sharedApplication] openURL:url];
}

-(void)handleLeftSwipe:(UISwipeGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.chatTableView];
    NSIndexPath *swipedIndexPath = [self.chatTableView indexPathForRowAtPoint:location];
    ChatMessageCell *swipedCell  = (ChatMessageCell*)[self.chatTableView cellForRowAtIndexPath:swipedIndexPath];
    
    if (![swipedCell.message.type isEqualToString:[HOPSystemMessage getMessageType]] && [swipedCell.message.sender isSelf] && !swipedCell.message.removed.boolValue)
    {
        self.messageTextbox.text = swipedCell.message.text;
        self.messageToEdit = swipedCell.message;
    }
}

-(void)handleRightSwipe:(UISwipeGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.chatTableView];
    NSIndexPath *swipedIndexPath = [self.chatTableView indexPathForRowAtPoint:location];
    ChatMessageCell *swipedCell  = (ChatMessageCell*)[self.chatTableView cellForRowAtIndexPath:swipedIndexPath];
    
    if (![swipedCell.message.type isEqualToString:[HOPSystemMessage getMessageType]] && [swipedCell.message.sender isSelf] && !swipedCell.message.removed.boolValue)
    {
        
        self.messageToEdit = swipedCell.message;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message deletion" message:@"Are you sure you want to delete the message?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        NSString* messageIDToReplace = self.messageToEdit && self.messageToEdit.text.length > 0 ? self.messageToEdit.messageID : @"";
        [[MessageManager sharedMessageManager] sendMessage:@"" replacesMessageID:messageIDToReplace forConversation:self.conversation];
        //just to skip sending composing
        self.messageToEdit = nil;
        //[self refreshViewWithData];
    }
}

- (void) refreshMessages
{
    self.fetchedResultsController = nil;
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
        OPLog(HOPLoggerSeverityFatal, HOPLoggerLevelDebug, @"Fetching messages has failed with an error: %@, error description: %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    [self.view bringSubviewToFront:self.chatTableView];
    [self.chatTableView reloadData];
}

- (float) getTextFieldHeight
{
    return self.typingMessageView.frame.size.height - self.labelComposingStatus.frame.size.height;
}
@end

