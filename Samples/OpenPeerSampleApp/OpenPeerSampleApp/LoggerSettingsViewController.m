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

#import "LoggerSettingsViewController.h"
#import "OpenPeer.h"
#import "Settings.h"
#import "Logger.h"
#import "AppConsts.h"
#import "MainViewController.h"
#import "Utility.h"
#import <OpenPeerSDK/HOPTypes.h>

typedef enum
{
    SECTION_LOGGER_TURN_ALL_OFF = LOGGER_ENABLED,
    SECTION_LOGGER_STD_OUT = LOGGER_STD_OUT,
    SECTION_LOGGER_TELNET = LOGGER_TELNET,
    SECTION_LOGGER_OUTGOING_TELNET = LOGGER_OUTGOING_TELNET,
    SECTION_LOGGER_MODULES,
    
    LOGGER_SETTINGS_TOTAL_SECTIONS
}LoggerSettingsSections;


@interface LoggerSettingsViewController ()

@property (strong, nonatomic) UIPickerView *pickerView;

- (void) switchChanged:(UISwitch*) sender;
- (void) switchColorChanged:(UISwitch*) sender;

@end

@implementation LoggerSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    
    self.navigationItem.leftBarButtonItem = [Utility createNavigationBackButtonForTarget:self.navigationController];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setSwitchCellData:(UITableViewCell*) tableCell
{
    UISwitch* switcher = (UISwitch*) tableCell.accessoryView;
    
    BOOL enabled =[[Settings sharedSettings] isLoggerEnabled:tableCell.tag];
    [switcher setOn:enabled];
    
    switch (tableCell.tag)
    {
        case SECTION_LOGGER_TURN_ALL_OFF:
            tableCell.textLabel.text = @"Enable logging";
            break;
            
        case SECTION_LOGGER_STD_OUT:
            tableCell.textLabel.text = @"Enable std::out logger";
            break;
            
        case SECTION_LOGGER_TELNET:
            tableCell.textLabel.text = @"Enable telnet logger";
            break;
            
        case SECTION_LOGGER_OUTGOING_TELNET:
            tableCell.textLabel.text = @"Enable outgoing telnet logger";
            break;
            
        default:
            break;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return LOGGER_SETTINGS_TOTAL_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger ret = 1;
    
    switch (section)
    {
        case SECTION_LOGGER_TURN_ALL_OFF:
            ret = 1;
            break;
            
        case SECTION_LOGGER_STD_OUT:
            ret = 1;
            break;
            
        case SECTION_LOGGER_OUTGOING_TELNET:
        case SECTION_LOGGER_TELNET:
            ret = TOTAL_TELNET_OPTIONS;
            break;
           
        case SECTION_LOGGER_MODULES:
            ret = TOTAL_MODULES;
            break;
            
        default:
            break;
    }
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"regularCell";
    static NSString *switchCellIdentifier = @"switchCell";
    static NSString *textCellIdentifier = @"textCell";
    UITableViewCell *cell = nil;
    
    switch (indexPath.section)
    {
        case SECTION_LOGGER_TURN_ALL_OFF:
        case SECTION_LOGGER_STD_OUT:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:switchCellIdentifier];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellIdentifier];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                cell.accessoryView = switchView;
                [switchView setOn:NO animated:NO];
                [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            }
            
            cell.tag = indexPath.section;
            ((UISwitch*)cell.accessoryView).tag = indexPath.section;
            [self setSwitchCellData:cell];
            if (indexPath.section != SECTION_LOGGER_TURN_ALL_OFF)
            {
                if (![[Settings sharedSettings] isLoggerEnabled:SECTION_LOGGER_TURN_ALL_OFF])
                    [((UISwitch*)cell.accessoryView) setOn:NO];
                ((UISwitch*)cell.accessoryView).enabled = [[Settings sharedSettings] isLoggerEnabled:SECTION_LOGGER_TURN_ALL_OFF];
            }
            
        }
            break;
        case SECTION_LOGGER_TELNET:
        case SECTION_LOGGER_OUTGOING_TELNET:
        {
            switch (indexPath.row)
            {
                case TELNET_ENABLE:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:switchCellIdentifier];
                    if (!cell)
                    {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellIdentifier];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                        cell.accessoryView = switchView;
                        [switchView setOn:NO animated:NO];
                        [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                    }
                    cell.tag = indexPath.section;
                    ((UISwitch*)cell.accessoryView).tag = indexPath.section;
                    [self setSwitchCellData:cell];
                    
                    if (![[Settings sharedSettings] isLoggerEnabled:SECTION_LOGGER_TURN_ALL_OFF])
                    {
                        [((UISwitch*)cell.accessoryView) setOn:NO];
//                        ((UISwitch*)cell.accessoryView).enabled = NO;
                    }
                    ((UISwitch*)cell.accessoryView).enabled = [[Settings sharedSettings] isLoggerEnabled:SECTION_LOGGER_TURN_ALL_OFF];

                        
                }
                    break;
                    
                case TELNET_SERVER_OR_PORT:
                {
                    UITextField* textField = nil;
                    cell = [tableView dequeueReusableCellWithIdentifier:textCellIdentifier];
                    if (!cell)
                    {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:textCellIdentifier];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        textField = [[UITextField alloc] initWithFrame:CGRectMake(150, 10, 150, 30)];
                        textField.delegate = self;
                        textField.adjustsFontSizeToFitWidth = YES;
                        
                        textField.borderStyle = UITextBorderStyleRoundedRect;
                        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
                        [cell.contentView addSubview: textField];
                    }
                    
                    if (!textField)
                    {
                        for (id object in cell.subviews)
                        {
                            if ([object isKindOfClass:[UITextField class]])
                                textField = (UITextField*) object;
                        }
                    }
                    textField.tag = indexPath.section;
                    cell.textLabel.text = indexPath.section == SECTION_LOGGER_TELNET ? @"Listen on port:" : @"Server:";
                    [cell.contentView sendSubviewToBack:cell.textLabel];
                    
                    UIFont* font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
                    CGSize size = [cell.textLabel.text sizeWithAttributes:@{NSFontAttributeName:font}];//[cell.textLabel.text sizeWithFont:font];
                    CGRect rect = textField.frame;
                    
                    rect.origin.y = fabsf((cell.frame.size.height - textField.frame.size.height)/2.0);
                    rect.origin.x = size.width + 12.0;
                    rect.size.width = cell.contentView.frame.size.width - rect.origin.x - 30.0;
                    textField.frame = rect;
                    
                    NSString* server = [[Settings sharedSettings] getServerPortForLogger:indexPath.section];
                    if ([server length] > 0)
                        textField.text = server;
                    else
                        textField.text = indexPath.section == SECTION_LOGGER_TELNET ? defaultTelnetPort : [[Settings sharedSettings] getDefaultOutgoingTelnetServer];
                }
                    break;
                    
                case TELNET_COLOR:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:switchCellIdentifier];
                    if (!cell)
                    {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellIdentifier];
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                        
                        cell.accessoryView = switchView;
                        [switchView setOn:NO animated:NO];
                        [switchView addTarget:self action:@selector(switchColorChanged:) forControlEvents:UIControlEventValueChanged];
                    }
                    
                    
                    ((UISwitch*)cell.accessoryView).tag = indexPath.section;
                    [((UISwitch*)cell.accessoryView) setOn:[[Settings sharedSettings] isColorizedOutputForLogger:indexPath.section]];
                    cell.textLabel.text = @"Colorize output";
                }
                    break;
            }

        }
            break;
            
            
        case SECTION_LOGGER_MODULES:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            
            HOPLoggerLevel level = [[Settings sharedSettings] getLoggerLevelForAppModule:indexPath.row];
            NSString* titleStr = [[Settings sharedSettings] getStringForModule:indexPath.row];
            
            if (![[Settings sharedSettings] isLoggerEnabled:SECTION_LOGGER_TURN_ALL_OFF])
            {
                cell.textLabel.text = [titleStr stringByAppendingString:[NSString stringWithFormat:@": NONE"]];
                cell.userInteractionEnabled = NO;
            }
            else
            {
                cell.textLabel.text = [titleStr stringByAppendingString:[NSString stringWithFormat:@": %@",[[Settings sharedSettings] getStringForLogLevel:level]]];
                cell.userInteractionEnabled = YES;
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
            break;
    }
    
    return cell;
}

- (void) showPicker:(NSIndexPath *)indexPath
{
    UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:@"Log Levels"
                                                      delegate:nil
                                             cancelButtonTitle:@"Done"
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:nil];
    // Add the picker
    UIPickerView* pickerView = [[UIPickerView alloc] init];
    pickerView.tag = indexPath.row;
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.showsSelectionIndicator = YES;
    [menu addSubview:pickerView];
    [menu showFromTabBar:[[OpenPeer sharedOpenPeer] mainViewController].tabBarController.tabBar];
    [menu setBounds:CGRectMake(0, 0, 320, 485)];
    
    CGRect rect = pickerView.frame;
    rect.origin.y = 100.0;//menu.bounds.size.height - rect.size.height;
    pickerView.frame = rect;
    
    NSInteger row = [[Settings sharedSettings] getLoggerLevelForAppModule:indexPath.row];
    [pickerView selectRow:row inComponent:0 animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_LOGGER_MODULES)
    {
        [self showPicker:indexPath];
    }
}

- (void) switchChanged:(UISwitch*) sender
{
    [[Settings sharedSettings] enable:[sender isOn] logger:sender.tag];
    [Logger start:[sender isOn] logger:sender.tag];
    
    if (sender.tag == SECTION_LOGGER_TURN_ALL_OFF)
        [self.tableView reloadData];
}

- (void) switchColorChanged:(UISwitch*) sender
{
    [[Settings sharedSettings] setColorizedOutput:[sender isOn] logger:sender.tag];
     [Logger start:[[Settings sharedSettings] isLoggerEnabled:LOGGER_OUTGOING_TELNET] logger:sender.tag];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component
{
    return HOPLoggerTotalNumberOfLevels;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[Settings sharedSettings] getStringForLogLevel:row];
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [[Settings sharedSettings] setLoggerLevel:row forAppModule:thePickerView.tag];
    NSIndexPath* path = [NSIndexPath indexPathForRow:thePickerView.tag inSection:SECTION_LOGGER_MODULES];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    [Logger setLogLevels];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField.text length] > 0)
        [[Settings sharedSettings] setServerOrPort:textField.text logger:textField.tag];
}

- (void) switchResetQRSettings:(UISwitch*) sender
{
    [[Settings sharedSettings] enable:[sender isOn] logger:sender.tag];
}
@end
