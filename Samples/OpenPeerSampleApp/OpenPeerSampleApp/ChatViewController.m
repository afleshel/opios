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
#import "Message.h"
#import "Session.h"
//#import "OpenPeerUser.h"
#import "ChatMessageCell.h"
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPMessageRecord.h>
#import <OpenPeerSDK/HOPSessionRecord.h>
#import <OpenPeerSDK/HOPConversationThread.h>
#import <OpenPeerSDK/HOPCallSystemMessage.h>
#import "SystemMessageCell.h"
#import "ChatCell.h"

@interface ChatViewController()

@property (weak, nonatomic) Session* session;
@property (nonatomic, copy) NSString* predicateString;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

//@property (weak, nonatomic) IBOutlet UIView *typingMessageView;

@property (weak, nonatomic) NSDictionary* userInfo;
@property (nonatomic) BOOL keyboardIsHidden;
@property (nonatomic) BOOL isRefreshed;
@property (nonatomic) BOOL isFirstRun;
@property (nonatomic) CGFloat keyboardLastChange;
@property (nonatomic,strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic,strong) UIView *footerView;
@property (nonatomic,strong) UILabel *labelTitle;

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
        // Custom initialization
    }
    return self;
}

- (id) initWithSession:(Session*) inSession
{
    self = [self initWithNibName:@"ChatViewController" bundle:nil];
    {
        self.session = inSession;
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
    
    self.keyboardIsHidden = NO;
    self.isFirstRun = YES;
    //[self.chatTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    //[self.typingMessageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    //[self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.chatTableView.backgroundColor = [UIColor clearColor];
    self.chatTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.messageTextbox setReturnKeyType:UIReturnKeySend];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    self.tapGesture.numberOfTapsRequired = 1;
    
    
    //[self registerForNotifications:YES];
    
    if (!self.keyboardIsHidden)
    {
        [self.messageTextbox becomeFirstResponder];
    }
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
		OPLog(HOPLoggerSeverityFatal, HOPLoggerLevelDebug, @"Fetching messages has failed with an error: %@, error description: %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    
    self.tapGesture.cancelsTouchesInView = NO;
    
    [self setFooterMessage:@""];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForNotifications:YES];
    self.chatTableView.tableFooterView.backgroundColor = [UIColor clearColor];
//    if (!self.keyboardIsHidden)
//    {
//        [self.messageTextbox becomeFirstResponder];
//    }
    
    [self.session.unreadMessageArray removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedComposingStatus:) name:notificationComposingStatusChanged object:nil];
//    if ([[[self fetchedResultsController] fetchedObjects] count] > 0)
//        [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[[self fetchedResultsController] fetchedObjects] count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    //[self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[[self fetchedResultsController] fetchedObjects] count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
//    if ([[[self fetchedResultsController] fetchedObjects] count] > 0)
//    {
//        [self.chatTableView reloadRowsAtIndexPaths:[self.chatTableView indexPathsForVisibleRows]
//                                  withRowAnimation:UITableViewRowAnimationNone];
//        [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[[self fetchedResultsController] fetchedObjects] count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//    }
    
    
}

- (void) updatedComposingStatus:(NSNotification *)notification
{
    NSDictionary* object = notification.object;
    
    HOPConversationThread* thread = [object objectForKey:@"thread"];
    HOPContact* contact = [object objectForKey:@"contact"];
    
    NSString* status = [thread getContactStatus:contact];
    
    if ([status length] > 0)
        [self setFooterMessage:status];
        //self.labelTitle.text = status;
}

- (void)viewDidAppear:(BOOL)animated
{
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.messageTextbox resignFirstResponder];
    [self registerForNotifications:NO];
    [self.chatTableView removeGestureRecognizer:self.tapGesture];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationComposingStatusChanged object:nil];
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
    self.keyboardIsHidden = NO;
    [self.delegate prepareForKeyboard:[notification userInfo] showKeyboard:YES];
    [self setFramesSizesForUserInfo:[notification userInfo]];
    
    if ([[[self fetchedResultsController] fetchedObjects] count] > 0)
        [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[[self fetchedResultsController] fetchedObjects] count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
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


- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        [self.messageTextbox resignFirstResponder];
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
    //if([text isEqualToString:@"\n"] && [textView.text length] > 0)
    if([text isEqualToString:@"\n"])
    {
        if ([textView.text length] > 0)
            [self sendIMmessage:textView.text];
        return NO;
    }
    [self.session.conversationThread setStatusInThread:HOPComposingStateComposing];
    return YES;
}


- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.session.conversationThread setStatusInThread:HOPComposingStateActive];
}

- (void) refreshViewWithData
{
    [self.session.unreadMessageArray removeAllObjects];
    
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
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(session.sessionID IN %@)",self.session.sessionIdsHistory]];
    //[fetchRequest setPredicate:predicate];
    
    //[NSFetchedResultsController deleteCacheWithName:[NSString stringWithFormat:@"messageCache_%@",[self.session.sessionIdsHistory obj]]];
    
    NSFetchRequest *fetchRequest = [[self fetchedResultsController] fetchRequest];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPMessageRecord" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSPredicate* predicate1 = [fetchRequest predicate];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(session.sessionID MATCHES '%@')",[self.session.conversationThread getThreadId]]];
                              
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
/*- (float) getHeaderHeight:(float)tableViewHeight
{
    float res = tableViewHeight;
    
    if(self.session.messageArray && [self.session.messageArray count] > 0)
    {
        for(int i=0; i<[self.session.messageArray count]; i++)
        {
            Message *message = [self.session.messageArray objectAtIndex:i];
            
            CGSize cs = [ChatMessageCell calcMessageHeight:message.text forScreenWidth:self.chatTableView.frame.size.width - 85];
            res -= (cs.height + 32);
            
            if(res < 0)
            {
                res = 1;
                break;
            }
        } // end of if
    }
    
    return res;
}*/

- (void) registerForNotifications:(BOOL)registerForNotifications
{
    if (registerForNotifications)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    else
    {
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
    ChatCell* msgCell = nil;
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
        msgCell = [tableView dequeueReusableCellWithIdentifier:@"MessageCellIdentifier"];
    }
    
    //ChatMessageCell* msgCell = [tableView dequeueReusableCellWithIdentifier:@"MessageCellIdentifier"];
    
    if (msgCell == nil)
    {
        if (isSystemMessage)
            msgCell = [[SystemMessageCell alloc] initWithFrame:CGRectZero];
        else
            msgCell = [[ChatMessageCell alloc] initWithFrame:CGRectZero];
        
        msgCell.messageLabel.delegate = self;
    }
    
    [msgCell setMessage:message];
    
    return msgCell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    float res = 0.0;
    //Message *message = [self.session.messageArray objectAtIndex:indexPath.row];
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

 - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 30.0;
}

//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
//{
//    return @"Veselo";
//}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return self.footerView;
}

- (void) sendIMmessage:(NSString *)message
{
    [self.session.conversationThread setStatusInThread:HOPComposingStateActive];
    if ([message length] > 0)
    {
        [[MessageManager sharedMessageManager] sendMessage:message forSession:self.session];
        self.messageTextbox.text = nil;
        [self refreshViewWithData];
    }
}

#pragma mark - NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    /*NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPMessageRecord" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    //self.predicateString = [NSString stringWithFormat:@"(session.sessionID MATCHES '%@')",[self.session.conversationThread getThreadId]];
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:self.predicateString];
    NSMutableArray* arrayOfPredicates = [[NSMutableArray alloc] init];
    //for (NSString* sessionID in [self.session.sessionIdsHistory allObjects])
    {
        NSPredicate* predicateSessionID = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(session.sessionID MATCHES '%@')",self.session.sessionRecord.sessionID]];
        [arrayOfPredicates addObject:predicateSessionID];
    }
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:arrayOfPredicates];
    
    [fetchRequest setPredicate:predicate];
    
	[fetchRequest setFetchBatchSize:20];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
    
	//_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:nil cacheName:[NSString stringWithFormat:@"messageCache_%@",[self.session.conversationThread getThreadId]]];
     */
    NSFetchRequest *fetchRequest = [[HOPModelManager sharedModelManager] getMessagesFetchRequestForSessionID:self.session.sessionRecord.sessionID sortAscending:YES];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
    
    _fetchedResultsController.delegate = self;
    
	return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    self.isRefreshed = YES;
    switch (type)
    {
		case NSFetchedResultsChangeInsert:
			[self.chatTableView  insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.chatTableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
			break;
		case NSFetchedResultsChangeUpdate:
			//[[self.contactsTableView cellForRowAtIndexPath:indexPath].textLabel setText:((HOPRolodexContact*)[[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]).name];
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

- (void) setFooterMessage:(NSString*) message
{
    if (!self.footerView)
    {
        self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30.0)];
        self.footerView.backgroundColor = [UIColor clearColor];
    }
    
    if (!self.labelTitle)
    {
        self.labelTitle = [[UILabel alloc] initWithFrame:self.footerView.bounds];
        [self.footerView addSubview:self.labelTitle];
    }
    
    self.labelTitle.text = message;
}
@end

