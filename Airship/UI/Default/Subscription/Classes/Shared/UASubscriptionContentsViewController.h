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

#import <Foundation/Foundation.h>
#import "UASubscriptionManager.h"
#import "GradientButton.h"

@class UASubscriptionContentDetailViewController;
@interface UASubscriptionContentsViewController : UIViewController
<UITableViewDataSource, UITableViewDelegate, UASubscriptionManagerObserver> {
    UITableView *contentsTable;
    NSMutableArray *dataSource;
    NSMutableArray *downloadedContents;
    NSMutableArray *undownloadedContents;
    NSMutableArray *contents;
    UASubscriptionContentDetailViewController *detailViewController;
    NSString *subscriptionKey;
}
@property (retain) IBOutlet UITableView *contentsTable;
@property (nonatomic, retain) NSString *subscriptionKey;
@property (nonatomic, retain) NSMutableArray *contents;

- (void)updateDataSource;

@end


@class UAAsyncImageView;
@class UASubscriptionContent;
@interface UASubscriptionContentCell : UITableViewCell <UIAlertViewDelegate>{
    UILabel *title;
    UILabel *contentDescription;
    UAAsyncImageView *icon;
    UIButton *downloadButton, *restoreButton, *activateButton;
    GradientButton *deleteButton;
    UASubscriptionContent *content;
    UIProgressView *progressBar;
    UITableView* owningTable;
}
@property (nonatomic, retain) IBOutlet UILabel *title;
@property (nonatomic, retain) IBOutlet UILabel *contentDescription;
@property (nonatomic, retain) IBOutlet UAAsyncImageView *icon;
@property (nonatomic, retain) IBOutlet UIButton *downloadButton, *restoreButton, *activateButton;
@property (nonatomic, retain) IBOutlet GradientButton *deleteButton;
@property (nonatomic, retain) IBOutlet UIProgressView *progressBar;
@property (nonatomic) UITableView *owningTable;
// Has to retain content. Since content instance could be changed if new product purchased,
// result in invoking released object
@property (nonatomic, retain) UASubscriptionContent *content;

- (void)refreshCellByContent;
- (void)setButtonState:(BOOL)contentIsDownloaded;
- (IBAction)actionButtonClicked:(id)sender;

@end