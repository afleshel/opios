/*
 
 Copyright (c) 2014, SMB Phone Inc.
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

#import "ActiveSessionsViewController.h"
#import <OpenPeerSDK/HOPSessionRecord+External.h>
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPPublicPeerFile.h>
#import "SessionManager.h"
#import "OpenPeer.h"
#import "MainViewController.h"
#import "ActiveSessionTableViewCell.h"

#define TABLE_CELL_HEIGHT 60.0

@interface ActiveSessionsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableViewSessions;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation ActiveSessionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableViewSessions.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, [UIFont fontWithName:@"Helvetica-Bold" size:22.0], NSFontAttributeName, nil];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
		OPLog(HOPLoggerSeverityFatal, HOPLoggerLevelDebug, @"Fetching sessions has failed with an error: %@, error description: %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableViewSessions reloadRowsAtIndexPaths:[self.tableViewSessions indexPathsForVisibleRows]
                                  withRowAnimation:UITableViewRowAnimationNone];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SessionCell";
    
    ActiveSessionTableViewCell *cell = (ActiveSessionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ActiveSessionTableViewCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
    
    cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tableViewCell.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tableViewCell_selected.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
    
    HOPSessionRecord* record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //[cell setContact:contact inTable:self.contactsTableView atIndexPath:indexPath];
    
    //cell.textLabel.text = record.name;
    
    if (record)
        [cell setSession:record];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TABLE_CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HOPSessionRecord* record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (record)
    {
        Session* session = [[SessionManager sharedSessionManager] getSessionForSessionRecord:record];
        if (!session)
        {
            NSMutableArray* listOfRolodexContacts = [[NSMutableArray alloc] init];
            for (HOPPublicPeerFile* publicPeerFile in record.participants)
            {
                NSArray* rolodexContactsArray = [[HOPModelManager sharedModelManager] getRolodexContactsByPeerURI:publicPeerFile.peerURI];
                HOPRolodexContact* rolodexContact = [rolodexContactsArray objectAtIndex:0];
                
                if (rolodexContact)
                    [listOfRolodexContacts addObject:rolodexContact];
            }
            
            if([listOfRolodexContacts count] > 0)
            {
                session = [[SessionManager sharedSessionManager] createSessionForContact:[listOfRolodexContacts objectAtIndex:0]];
            }
        }
        
        if (session)
            [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForSession:session forIncomingCall:NO forIncomingMessage:NO];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> theSection = [[self.fetchedResultsController sections] objectAtIndex:section];
    
    /*
     Section information derives from an event's sectionIdentifier, which is a string representing the number (year * 1000) + month.
     To display the section title, convert the year and month components to a string representation.
     */
    static NSDateFormatter *formatter = nil;
    
    if (!formatter)
    {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setCalendar:[NSCalendar currentCalendar]];
        
        NSString *formatTemplate = [NSDateFormatter dateFormatFromTemplate:@"MMMM YYYY" options:0 locale:[NSLocale currentLocale]];
        [formatter setDateFormat:formatTemplate];
    }
    
    NSInteger numericSection = [[theSection name] integerValue];
	NSInteger year = numericSection / 1000;
	NSInteger month = numericSection - (year * 1000);
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = year;
    dateComponents.month = month;
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    
	NSString *titleString = [formatter stringFromDate:date];
    
	return [theSection name];
}

#pragma mark - NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPSessionRecord" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPRolodexContact" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    
    [fetchRequest setEntity:entity];
    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(associatedIdentity.homeUser.stableId MATCHES '%@')",[[HOPModelManager sharedModelManager] getLastLoggedInHomeUser].stableId]];
//    [fetchRequest setPredicate:predicate];
    
//	[fetchRequest setFetchBatchSize:20];
//	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
    
	//_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:@"firstLetter" cacheName:@"RolodexContacts"];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:@"sectionIdentifier" cacheName:nil];
    _fetchedResultsController.delegate = self;
    
	return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
	switch (type)
    {
		case NSFetchedResultsChangeInsert:
			[self.tableViewSessions  insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			//[[self.contactsTableView cellForRowAtIndexPath:indexPath].textLabel setText:((HOPRolodexContact*)[[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]).name];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableViewSessions  deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeMove:
			[self.tableViewSessions  deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableViewSessions  insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}
@end
