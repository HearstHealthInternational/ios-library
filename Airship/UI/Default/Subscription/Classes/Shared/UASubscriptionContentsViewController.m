/*
 Copyright 2009-2011 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UASubscriptionContentsViewController.h"
#import "UAGlobal.h"
#import "UASubscriptionManager.h"
#import "UASubscriptionInventory.h"
#import "UASubscription.h"
#import "UASubscriptionContent+State.h"
#import "UASubscriptionContentDetailViewController.h"
#import "UAAsycImageView.h"
#import "UAViewUtils.h"
#import "UASubscriptionUI.h"
#import "ActiveContentPath.h"
#import "DSActivityView.h"


@implementation UASubscriptionContentsViewController
@synthesize contentsTable;
@synthesize subscriptionKey;
@synthesize contents;

#pragma mark lifecyle methods

- (void)dealloc {
    RELEASE_SAFELY(subscriptionKey);
    RELEASE_SAFELY(contentsTable);
    RELEASE_SAFELY(downloadedContents);
    RELEASE_SAFELY(undownloadedContents);
    RELEASE_SAFELY(detailViewController);
    [contents release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [[UASubscriptionManager shared] addObserver:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad]; 
    self.contentsTable.backgroundColor = [UIColor clearColor];
    self.navigationItem.title = @"Issues";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)setSubscriptionKey:(NSString *)value {
    if (subscriptionKey == value) {
        return;
    }
    [value retain];
    [subscriptionKey release];
    subscriptionKey = value;

    [self updateDataSource];
}

- (void)updateDataSource {
    UASubscription *subscription = [[UASubscriptionManager shared].inventory subscriptionForKey:subscriptionKey];
    downloadedContents = subscription.downloadedContents;
    undownloadedContents = subscription.undownloadedContents;
    
    NSMutableArray *newContent = [[NSMutableArray alloc] initWithArray:downloadedContents];
    [newContent addObjectsFromArray:undownloadedContents];
    self.contents = newContent;
    [newContent release];
    
    [self.contents sortUsingComparator: ^(id left, id right)
     {
         UASubscriptionContent *content1 = (UASubscriptionContent * )left;
         UASubscriptionContent *content2 = (UASubscriptionContent * )right;
         return [content2.publishDate compare:content1.publishDate];  
     }];

    [contentsTable reloadData];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [contents count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

static NSString *CELL_UNIQ_ID = @"UASubscriptionContentCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UASubscriptionContentCell *cell = (UASubscriptionContentCell *)[tableView
                                                                    dequeueReusableCellWithIdentifier:CELL_UNIQ_ID];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UASubscriptionContentCell"
                                                                 owner:nil
                                                               options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }

    [cell.deleteButton useRedDeleteStyle];

    UASubscriptionContent *content;

    cell.owningTable = tableView;
    content = [contents objectAtIndex:[indexPath row] ];
    cell.content = content;
    
    if ([ActiveContentPath isActiveInternationalContent:content])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    return nil;
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UASubscriptionContent * content = [contents objectAtIndex:indexPath.row];
    
    switch ([content state]) {
        case NOT_DOWNLOADED:
        case DOWNLOADED_BUT_DELETED:
            [cell setBackgroundColor:[UIColor colorWithRed:191.0/255 green:191.0/255 blue:191.0/255 alpha:0.7]];
            break;
        case ACTIVE:
            [cell setBackgroundColor:[UIColor colorWithRed:0.0 green:164.0/255 blue:167.0/255 alpha:0.7]];
            break;
        case DOWNLOADED:
            [cell setBackgroundColor:[UIColor colorWithRed:170.0/255 green:207.0/255 blue:208.0/255 alpha:0.7]];
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (detailViewController == nil) {
        detailViewController = [[UASubscriptionContentDetailViewController alloc]
                                initWithNibName:@"UASubscriptionContentDetailView"
                                bundle:nil];
    }
    
    UASubscriptionContent *content = [contents objectAtIndex:[indexPath row] ];
    
    if ([ActiveContentPath fileExistsForContent:content] && ![ActiveContentPath isActiveInternationalContent:content])
    {
        [DSBezelActivityView activityViewForView:tableView withLabel:@"Activating"];
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NSThread sleepForTimeInterval:1];
            NSString *contentPath = [[[ActiveContentPath downloadDirectory] stringByAppendingPathComponent:content.subscriptionKey] stringByAppendingPathComponent:content.contentName];
            [ActiveContentPath setActiveInternationalContent: contentPath];
            dispatch_async( dispatch_get_main_queue(), ^{
                [DSBezelActivityView removeViewAnimated:YES];
                [tableView reloadData];
            });
        });
    }
    
}

#pragma mark UASubscriptionManagerObserver method

- (void)userSubscriptionsUpdated:(NSArray *)userSubscritions {
    UALOG(@"Observer notified");
    [self updateDataSource];
}

- (void)downloadContentFinished:(UASubscriptionContent *)content {
    UALOG(@"Observer notified");
    // backend data is automatically updated
    [contentsTable reloadData];

    NSString* fullPathToDownload = [[[ActiveContentPath downloadDirectory] stringByAppendingPathComponent:content.subscriptionKey] stringByAppendingPathComponent:content.contentName];

    [ActiveContentPath setActiveInternationalContent:fullPathToDownload];
    [DSBezelActivityView removeViewAnimated:YES];
}

- (void)downloadContentFailed:(UASubscriptionContent *)content {
    UALOG(@"Observer notified");
    UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle: UA_SS_TR(@"UA_Error_Download")
                                                           message: UA_SS_TR(@"UA_Try_Again")
                                                          delegate: nil
                                                 cancelButtonTitle: UA_SS_TR(@"UA_OK")
                                                 otherButtonTitles: nil];
    [failureAlert show];
    [failureAlert release];
    [contentsTable reloadData];
}

@end


@implementation UASubscriptionContentCell

@synthesize title, contentDescription, icon, downloadButton, restoreButton, activateButton, deleteButton, content, owningTable;
@synthesize progressBar;

- (void)dealloc {
    RELEASE_SAFELY(content);
    RELEASE_SAFELY(title);
    RELEASE_SAFELY(contentDescription);
    RELEASE_SAFELY(icon);
    RELEASE_SAFELY(downloadButton);
    RELEASE_SAFELY(deleteButton);
    RELEASE_SAFELY(activateButton);
    RELEASE_SAFELY(restoreButton);
    RELEASE_SAFELY(progressBar);
    [super dealloc];
}

- (void)setContent:(UASubscriptionContent *)aContent {
    [content removeObservers];

    [aContent retain];
    [content release];
    content = aContent;

    [content addObserver:self];
    [self refreshCellByContent];
}

- (void)setProgress:(id)p {
    float progress = [p floatValue];
    progressBar.progress = progress;

    if (progress >= 1) {
        progressBar.hidden = YES;
        [content removeObservers];
        if (progressBar.hidden == YES)
        {
            [DSBezelActivityView activityViewForView:self.owningTable withLabel:@"Installing"];
        }
    }
    else {
        progressBar.hidden = NO;
    }
}

- (void)refreshCellByContent {
    self.title.text = content.contentName;
    self.contentDescription.text = content.description;
    [self.icon loadImageFromURL:content.iconURL];
    [UAViewUtils roundView:self.icon borderRadius:10.0 borderWidth:1.0 color:[UIColor darkGrayColor]];
    [downloadButton setTitle:UA_SS_TR(@"UA_Download") forState:UIControlStateNormal];
    [restoreButton setTitle:UA_SS_TR(@"UA_Restore") forState:UIControlStateNormal];
    [self setButtonState:content.downloaded];
    progressBar.hidden = !content.downloading;
}

- (void)setButtonState:(BOOL)contentIsDownloaded {
    deleteButton.hidden = YES;
    deleteButton.enabled = NO;
    restoreButton.hidden = YES;
    restoreButton.enabled = NO;
    downloadButton.hidden = YES;
    downloadButton.enabled = NO;
    
    switch ([content state]) {
        case NOT_DOWNLOADED:
            downloadButton.hidden = NO;
            downloadButton.enabled = YES;
            break;
        case DOWNLOADED:
            deleteButton.hidden = NO;
            deleteButton.enabled = YES;
            break;
        case DOWNLOADED_BUT_DELETED:
            restoreButton.hidden = NO;
            restoreButton.enabled = YES;
            break;
        case ACTIVE:
            break;
        default:
            break;
    }
}

- (void) download
{
    if (!content.downloading) {
        downloadButton.enabled = NO;
        [[UASubscriptionManager shared].inventory download:content];
    }
    //[DSBezelActivityView activityViewForView:self.owningTable withLabel:@"Installing"];
}

- (IBAction)actionButtonClicked:(id)sender {
    
    switch ([content state]) {
        case NOT_DOWNLOADED:
            [self download];
            break;
        case DOWNLOADED:
        {
            UIAlertView *alert = [[UIAlertView alloc] 
                                  initWithTitle: NSLocalizedString(@"Delete Content",nil)
                                  message: NSLocalizedString(@"Are you sure you want to delete the selected content",nil)
                                  delegate: self
                                  cancelButtonTitle: NSLocalizedString(@"Cancel",nil)
                                  otherButtonTitles: NSLocalizedString(@"Delete",nil), nil];
            [alert show];
            [alert release];
            
            break;
        }
        case DOWNLOADED_BUT_DELETED:
            [self download];
            break;
        case ACTIVE:
            break;
        default:
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0: 
        {       
            NSLog(@"Delete was cancelled by the user");
        }
            break;
            
        case 1: 
        {
            [DSBezelActivityView activityViewForView:self.owningTable withLabel:@"Deleting"];
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSFileManager *manager = [[NSFileManager alloc] init];
                NSString *pathToContent = [[[ActiveContentPath downloadDirectory] stringByAppendingPathComponent:content.subscriptionKey] stringByAppendingPathComponent:content.contentName];
                NSError *error = nil;
                BOOL success = [manager removeItemAtPath:pathToContent error:&error];
                if (!success)
                {
                    NSLog(@"Cannot delete the file: %@", pathToContent);
                }
                [manager release];
                dispatch_async( dispatch_get_main_queue(), ^{
                    [DSBezelActivityView removeViewAnimated:YES];
                    [self setButtonState:NO];
                });
            });
        }
            break;
    }
}

@end
