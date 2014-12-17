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

#import "ContactsViewController.h"
#import "ContactTableViewCell.h"
#import "ActivityIndicatorViewController.h"
#import "MainViewController.h"
#import "OpenPeer.h"
#import "SessionManager.h"
#import "ContactsManager.h"

#import <OpenpeerSDK/HOPRolodexContact+External.h>
#import <OpenpeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPAccount.h>
//#import <OpenpeerSDK/HOPOpenPeerContact+External.h>

#define REMOTE_SESSION_ALERT_TAG 1
#define TABLE_CELL_HEIGHT 55.0

@interface ContactsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL isDragging;

@property (nonatomic, strong) UITapGestureRecognizer *oneTapGestureRecognizer;
@property (nonatomic,retain) NSMutableArray* listOfSelectedContacts;
@property (nonatomic,retain) NSArray* listOfFilterContacts;
@property (nonatomic) BOOL keyboardIsHidden;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

- (void)registerForNotifications:(BOOL)registerForNotifications;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void) setFramesSizesForUserInfo:(NSDictionary*) userInfo;
- (void) stopRefreshController;
@end

@implementation ContactsViewController

- (NSMutableArray*) listOfSelectedContacts
{
    if (!_listOfSelectedContacts)
        _listOfSelectedContacts = [[NSMutableArray alloc] init];
    return _listOfSelectedContacts;
}

- (id) initInFavoritesMode:(BOOL) favoritesMode allowMultipleSelection:(BOOL) inAllowMultipleSelection
{
    self = [self initWithNibName:@"ContactsViewController" bundle:nil];
    if (self)
    {
        self.isInFavoritesMode = favoritesMode;
        self.isMultipleSelectionAvailable = inAllowMultipleSelection;
    }
    return self;
}

- (id) initInMode:(ContactsTableModes) inMode allowMultipleSelection:(BOOL) inAllowMultipleSelection filterContacts:(NSArray*) inFilterContacts
{
    self = [self initWithNibName:@"ContactsViewController" bundle:nil];
    if (self)
    {
        self.mode = inMode;
        self.isInFavoritesMode = inMode == CONTACTS_TABLE_MODE_FAVORITES;   
        self.isMultipleSelectionAvailable = inAllowMultipleSelection;
        if (inFilterContacts.count > 0)
            self.listOfFilterContacts = [NSArray arrayWithArray:inFilterContacts];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.keyboardIsHidden = YES;
        self.isInFavoritesMode = NO;
        self.isMultipleSelectionAvailable = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    if ([self.contactsTableView respondsToSelector:@selector(sectionIndexBackgroundColor)])
        self.contactsTableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
		OPLog(HOPLoggerSeverityFatal, HOPLoggerLevelDebug, @"Fetching contacts has failed with an error: %@, error description: %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    
    self.oneTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.searchBar action:@selector(resignFirstResponder)];
    self.oneTapGestureRecognizer.delegate = self;
    self.oneTapGestureRecognizer.numberOfTapsRequired = 1;
    self.oneTapGestureRecognizer.numberOfTouchesRequired = 1;
 
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, [UIFont fontWithName:@"Helvetica-Bold" size:22.0], NSFontAttributeName, nil];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor grayColor];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh Contacts"];
    [self.refreshControl addTarget:self action:@selector(startContactsRefresh) forControlEvents:UIControlEventValueChanged];
    [self.contactsTableView addSubview:self.refreshControl];
    //Hack to position text properly
    [self.refreshControl beginRefreshing];
    [self.refreshControl endRefreshing];
    
    self.contactsTableView.allowsMultipleSelection = self.isMultipleSelectionAvailable;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = self.isInFavoritesMode ? @"Favorites" : @"Contacts";
    [self.contactsTableView reloadRowsAtIndexPaths:[self.contactsTableView indexPathsForVisibleRows]
                     withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self registerForNotifications:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self registerForNotifications:NO];
    if (self.oneTapGestureRecognizer)
        [self.view removeGestureRecognizer:self.oneTapGestureRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

- (void) prepareTableForRemoteSessionMode
{
    self.contactsTableView.allowsMultipleSelection = [[OpenPeer sharedOpenPeer] isRemoteSessionActivationModeOn];
    if (![[OpenPeer sharedOpenPeer] isRemoteSessionActivationModeOn])
    {
        [self.listOfSelectedContacts removeAllObjects];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
    
//    [self.refreshControl endRefreshing];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ContactCell";
    
    ContactTableViewCell *cell = (ContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ContactTableViewCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
    
    cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tableViewCell.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tableViewCell_selected.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
    
    HOPRolodexContact* contact = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [cell setContact:contact inTable:self.contactsTableView atIndexPath:indexPath];
    
    if (self.isMultipleSelectionAvailable)
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TABLE_CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HOPRolodexContact* contact = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (contact)
    {
        //Check if app is in remote session mode
        if (![[OpenPeer sharedOpenPeer] isRemoteSessionActivationModeOn])
        {
            //[tableView deselectRowAtIndexPath:indexPath animated:NO];
            
            if (!self.isMultipleSelectionAvailable)
            {
                //HOPOpenPeerContact* openPeerContact = [[HOPModelManager sharedModelManager] getOpenPeerContactForIdentityURI:contact.identityURI];
                //If not, create a session for selecte contact
                if ([contact isOpenPeer])
                {
                    Session* session = [[SessionManager sharedSessionManager] createSessionForContacts:@[contact]];
                
                    if (session)
                        [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:NO forIncomingMessage:NO];
                }
            }
            else
            {
                if ([self.listOfSelectedContacts containsObject:contact])
                {
                    [self.listOfSelectedContacts removeObject:contact];
                }
                else
                {
                    [self.listOfSelectedContacts addObject:contact];
                }
            }
        }
        else
        {
            self.contactsTableView.allowsMultipleSelection = YES;
            //If app is in remote session mode, add selected contact to the list of contacts which will take a part in a remote session
            //If contact is already in the list, remove it
            if ([self.listOfSelectedContacts containsObject:contact])
            {
                [self.listOfSelectedContacts removeObject:contact];
            }
            else
            {
                [self.listOfSelectedContacts addObject:contact];
            }
            
            //If two contacts are selected ask user to create remote session between selected contacts
            if ([self.listOfSelectedContacts count] == 2)
            {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Remote video session."
                                                                    message:@"Do you want to create a remote session?"
                                                                   delegate:self
                                                          cancelButtonTitle:@"No"
                                                          otherButtonTitles:@"Yes",nil];
                alertView.tag = REMOTE_SESSION_ALERT_TAG;
                [alertView show];
                
            }
            else if ([self.listOfSelectedContacts count] > 2)
            {
                [self.listOfSelectedContacts removeLastObject];
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Remote video session."
                                                                    message:@"You cannot select more than two contacts!"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Ok"
                                                          otherButtonTitles:nil];
                alertView.tag = 0;
                [alertView show];
                return;
            }
        }
    }
    
    if (!self.contactsTableView.allowsMultipleSelection)
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(3_0)
{
    HOPRolodexContact* contact = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (contact)
    {
        if ([self.listOfSelectedContacts containsObject:contact])
        {
            [self.listOfSelectedContacts removeObject:contact];
        }
    }
}
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (alertView.tag == REMOTE_SESSION_ALERT_TAG)
//    {
//        if (buttonIndex == 1)
//        {
//            //If user wants to create a remote session between selected contacts, create a session for fist selected and send him a system message to create a session with other selected contact
//            [[SessionManager sharedSessionManager] createRemoteSessionForContacts:self.listOfSelectedContacts];
//        }
//    }
//}

#pragma mark - NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    //NSString *cacheName = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPRolodexContact" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSMutableArray *predicatesArray = [[NSMutableArray alloc] init];
    NSPredicate *predicateForFiltering = nil;
    //NSPredicate *predicateWithoutContacts = nil;
    
//    if (self.isInFavoritesMode)
//    {
//        predicateOnlyOpenPeerContacts = [NSPredicate predicateWithFormat:@"identityContact != nil"];
//        [predicatesArray addObject:predicateOnlyOpenPeerContacts];
//        cacheName = @"FavoritesContacts";
//    }
//    else
//    {
//        cacheName = @"RolodexContacts";
//    }
    
    switch (self.mode)
    {
        case CONTACTS_TABLE_MODE_REGULAR:
            //cacheName = @"RolodexContacts";
            break;
            
        case CONTACTS_TABLE_MODE_FAVORITES:
            predicateForFiltering = [NSPredicate predicateWithFormat:@"identityContact != nil"];
            [predicatesArray addObject:predicateForFiltering];
            //cacheName = @"FavoritesContacts";
            break;
            
        case CONTACTS_TABLE_MODE_ADDING:
        {
            NSMutableArray* identityURIs = [NSMutableArray new];
            for (HOPRolodexContact* contact in self.listOfFilterContacts)
            {
                if (contact.identityURI.length > 0)
                    [identityURIs addObject:contact.identityURI];
            }
            predicateForFiltering = [NSPredicate predicateWithFormat:@"identityContact != nil AND NOT (identityURI IN %@)",identityURIs];
            [predicatesArray addObject:predicateForFiltering];
        }
            break;
            
        case CONTACTS_TABLE_MODE_REMOVING:
        {
            NSMutableArray* identityURIs = [NSMutableArray new];
            for (HOPRolodexContact* contact in self.listOfFilterContacts)
            {
                if (contact.identityURI.length > 0)
                    [identityURIs addObject:contact.identityURI];
            }
            predicateForFiltering = [NSPredicate predicateWithFormat:@"identityURI IN %@",identityURIs];
            [predicatesArray addObject:predicateForFiltering];
        }
            break;
            
        default:
            break;
    }
    
    NSPredicate *predicateAllContacts = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(associatedIdentity.account.stableId MATCHES '%@')",[[HOPAccount sharedAccount] getStableID]]];
    
    [predicatesArray addObject:predicateAllContacts];
    
    NSPredicate *mainPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicatesArray];
    [fetchRequest setPredicate:mainPredicate];
    
	[fetchRequest setFetchBatchSize:20];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
    
	//_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:@"firstLetter" cacheName:@"RolodexContacts"];
    
    if (!self.isInFavoritesMode)
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:nil cacheName:@"RolodexContacts"];
    else
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:nil cacheName:@"FavoritesContacts"];
    
    _fetchedResultsController.delegate = self;
    
	return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.contactsTableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.contactsTableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
	switch (type)
    {
		case NSFetchedResultsChangeInsert:
            [self.contactsTableView  insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			//[[self.contactsTableView cellForRowAtIndexPath:indexPath].textLabel setText:((HOPRolodexContact*)[[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]).name];
			break;
		case NSFetchedResultsChangeDelete:
			[self.contactsTableView  deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeMove:
			[self.contactsTableView  deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.contactsTableView  insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSString* predicateString = nil;
    
    NSMutableArray *predicatesArray = [[NSMutableArray alloc] init];
    NSPredicate *predicateOnlyOpenPeerContacts = nil;
    if (self.isInFavoritesMode)
    {
        predicateOnlyOpenPeerContacts = [NSPredicate predicateWithFormat:@"identityContact != nil"];
        [predicatesArray addObject:predicateOnlyOpenPeerContacts];
    }
    
    if ([searchText length] > 0)
        predicateString = [NSString stringWithFormat:@"(associatedIdentity.account.stableId MATCHES '%@' AND name CONTAINS[c] '%@') ",[[HOPAccount sharedAccount] getStableID],searchText];
    else
        predicateString = [NSString stringWithFormat:@"(associatedIdentity.account.stableId MATCHES '%@') ",[[HOPAccount sharedAccount] getStableID]];
    
    NSPredicate *predicateAllContacts = [NSPredicate predicateWithFormat:predicateString];
    [predicatesArray addObject:predicateAllContacts];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicatesArray];
    
    if (self.isInFavoritesMode)
        [NSFetchedResultsController deleteCacheWithName:@"FavoritesContacts"];
    else
        [NSFetchedResultsController deleteCacheWithName:@"RolodexContacts"];
    
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
    [self.fetchedResultsController.fetchRequest setPredicate:predicate];
    
    NSError *error;
	if (![self.fetchedResultsController performFetch:&error])
    {
		OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Fetching contacts for search, has failed with an error: %@, error description: %@", error, [error userInfo]);
		//exit(-1);  // Fail
	}
    
    [self.contactsTableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
}


- (void) onContactsLoaded
{
    [self stopRefreshController];
    OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelTrace, @"Handling loaded contacts.");
    NSError *error;
    self.fetchedResultsController = nil;
	if (![self.fetchedResultsController performFetch:&error])
    {
		OPLog(HOPLoggerSeverityError, HOPLoggerLevelDebug, @"Fetching contacts has failed with an error: %@, error description: %@", error, [error userInfo]);
		//exit(-1);  // Fail
	}
    
    [self.contactsTableView reloadData];
    [[ActivityIndicatorViewController sharedActivityIndicator] showActivityIndicator:NO withText:nil inView:nil];
}

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

- (void) keyboardWillShow:(NSNotification *)notification
{
    if (self.oneTapGestureRecognizer)
        [self.view addGestureRecognizer:self.oneTapGestureRecognizer];
    
    self.keyboardIsHidden = NO;
    [self setFramesSizesForUserInfo:[notification userInfo]];
}

- (void) keyboardWillHide:(NSNotification *)notification
{
    if (self.oneTapGestureRecognizer)
        [self.view removeGestureRecognizer:self.oneTapGestureRecognizer];
    
    self.keyboardIsHidden = YES;
    [self setFramesSizesForUserInfo:[notification userInfo]];
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
    CGRect contactsTableViewRect = self.contactsTableView.frame;
    
    if (!self.keyboardIsHidden)
        contactsTableViewRect.size.height = self.view.frame.size.height - self.searchBar.viewForBaselineLayout.frame.size.height - keyboardHeight + self.tabBarController.tabBar.frame.size.height;
    else
        contactsTableViewRect.size.height = self.view.frame.size.height - self.searchBar.viewForBaselineLayout.frame.size.height;    self.contactsTableView.frame = contactsTableViewRect;

    
    if (userInfo)
        [UIView commitAnimations];
}

- (void) startContactsRefresh
{
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(stopRefreshController)
                                   userInfo:nil
                                    repeats:NO];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing Contacts"];
    [[ContactsManager sharedContactsManager] refreshRolodexContacts];
}

- (void) resetRefreshTitle
{
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh Contacts"];
    //Hack to position text properly
    [self.refreshControl beginRefreshing];
    [self.refreshControl endRefreshing];
}
- (void) stopRefreshController
{
    if ([self.refreshControl isRefreshing])
    {
        [self.refreshControl endRefreshing];
        self.refreshControl.attributedTitle = nil;
        //self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh Contacts"];
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(resetRefreshTitle)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (NSArray*) getSelectedContacts
{
    return self.listOfSelectedContacts;
}
@end
