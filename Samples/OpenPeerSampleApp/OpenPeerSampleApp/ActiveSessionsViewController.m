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

#import "ActiveSessionsViewController.h"
#import <OpenPeerSDK/HOPModelManager.h>
#import <OpenPeerSDK/HOPAccount.h>
#import <OpenPeerSDK/HOPConversationRecord+External.h>
#import <OpenPeerSDK/HOPConversation.h>
#import <OpenPeerSDK/HOPUtility.h>
#import "SessionManager.h"
#import "OpenPeer.h"
#import "MainViewController.h"
#import "ActiveSessionTableViewCell.h"

#define TABLE_CELL_HEIGHT 55.0

@interface ActiveSessionsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableViewSessions;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSDate *lastRefresh;
@property (nonatomic, strong) NSTimer *refreshTimer;

- (void) updateCellForConversation:(HOPConversation*) conversation;
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
    
    self.lastRefresh = [NSDate date];
    self.tableViewSessions.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_background.png"]];
    [tempImageView setFrame:self.tableViewSessions.frame];
    self.tableViewSessions.backgroundView = tempImageView;
    
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, [UIFont fontWithName:@"Helvetica-Bold" size:22.0], NSFontAttributeName, nil];
    
    [self fetchData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:notifictionAppReturnedFromBackground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCellForConversation:) name:notificationMessagesRead object:nil];
}

- (void)fetchData
{
    NSError *error;
    self.fetchedResultsController = nil;
    if (![self.fetchedResultsController performFetch:&error])
    {
        OPLog(HOPLoggerSeverityFatal, HOPLoggerLevelDebug, @"Fetching sessions has failed with an error: %@, error description: %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

- (void) reloadData
{
    [self fetchData];
    [self.tableViewSessions reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![[HOPUtility getTimeSectionForDate:self.lastRefresh] isEqualToString:@"Today"])
    {
        [self reloadData];
    }
    else
    {
        NSInteger currentSeconds = [[NSCalendar currentCalendar] ordinalityOfUnit:NSSecondCalendarUnit inUnit:NSDayCalendarUnit forDate:[NSDate date]];
        NSInteger secondsForTimer = 24 * 60 * 60 - currentSeconds;
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:secondsForTimer target:self selector:@selector(reloadData) userInfo:nil repeats:NO];
        //[self.tableViewSessions reloadRowsAtIndexPaths:[self.tableViewSessions indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
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
        
        cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tableViewCell.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tableViewCell_selected.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
        
        //[cell setBackground];
    }
    
    HOPConversationRecord* record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (record)
        [cell setRecord:record];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TABLE_CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *customTitleView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 320, 40)];
    UIImage* separator = [UIImage imageNamed:@"table_cell_separator.png"];
    UIImageView *upperSeparatorView = section == 0 ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_header.png"]] :[[UIImageView alloc] initWithImage:separator];
    CGRect rect = upperSeparatorView.frame;
    rect.origin = CGPointMake(0.0, 0.0);
    upperSeparatorView.frame = rect;
    UIImageView *lowerSeparatorView = [[UIImageView alloc] initWithImage:separator];
    rect = lowerSeparatorView.frame;
    rect.origin = CGPointMake(0.0, 38.0);
    lowerSeparatorView.frame = rect;
    
    UILabel *titleLabel = [ [UILabel alloc] initWithFrame:CGRectMake(10.0, 2, 300, 36)];
    
    id <NSFetchedResultsSectionInfo> theSection = [[self.fetchedResultsController sections] objectAtIndex:section];
    
    titleLabel.text = [theSection name];
    
    titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    titleLabel.textColor = [UIColor colorWithRed:24.0/255.0 green:85.0/255.0 blue:103.0/255.0 alpha:1];
    
    titleLabel.backgroundColor = [UIColor clearColor];
    
    [customTitleView addSubview:titleLabel];
    [customTitleView addSubview:upperSeparatorView];
    [customTitleView addSubview:lowerSeparatorView];
    
    return customTitleView;
}

//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_footer.png"]];
//    return imageView;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HOPConversationRecord* record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (record)
    {
        HOPConversation* conversation = [record getConversation];
        if (!conversation)
        {
            if(record.participants.count > 0)
            {
                conversation = [HOPConversation conversationForRecord:record];
            }
        }
        
        if (conversation)
        {
            ActiveSessionTableViewCell *cell = (ActiveSessionTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            if (cell)
            {
                conversation.numberOfUnreadMessages = 0;
                [cell updateBadge:conversation];
            }
            [[[OpenPeer sharedOpenPeer] mainViewController] showSessionViewControllerForConversation:conversation replaceConversation:nil incomingCall:NO incomingMessage:NO];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}
/*- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> theSection = [[self.fetchedResultsController sections] objectAtIndex:section];
    

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
}*/

#pragma mark - NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    [NSFetchedResultsController deleteCacheWithName:@"SessionRecord"];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HOPConversationRecord" inManagedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext]];
    
    [fetchRequest setEntity:entity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(homeUser.stableId MATCHES '%@' AND selfRemoved = NO)",[[HOPAccount sharedAccount] getStableID]]];
    [fetchRequest setPredicate:predicate];
    
    [fetchRequest setFetchBatchSize:20];
    //
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastActivity" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[[HOPModelManager sharedModelManager] managedObjectContext] sectionNameKeyPath:@"sectionIdentifier" cacheName:@"SessionRecord"];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}



- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableViewSessions beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableViewSessions endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{	
	switch (type)
    {
		case NSFetchedResultsChangeInsert:
			[self.tableViewSessions  insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableViewSessions reloadData];
			break;
		case NSFetchedResultsChangeUpdate:
            [((ActiveSessionTableViewCell*) [self.tableViewSessions cellForRowAtIndexPath:indexPath]) updateActivity];
//			[[self.tableViewSessions cellForRowAtIndexPath:indexPath].textLabel setText:((HOPIdentity*)[[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]).name];
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

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableViewSessions insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableViewSessions deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
            default:
            break;
    }
}

- (void) updateCellForConversation:(NSNotification *)notification
{
    HOPConversation* conversation = notification.object;
    if (conversation)
    {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:conversation];
        if (indexPath)
        {
            ActiveSessionTableViewCell *cell = (ActiveSessionTableViewCell *)[self.tableViewSessions cellForRowAtIndexPath:indexPath];
            if (cell)
                [cell updateBadge:conversation];
        }
    }
}
@end
