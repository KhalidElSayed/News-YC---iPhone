//
//  SubmitHNViewController.m
//  HackerNews
//
//  Created by Ben Gordon on 10/22/13.
//  Copyright (c) 2013 Benjamin Gordon. All rights reserved.
//

#import "Helpers.h"
#import "SubmitHNViewController.h"
#import "libHN.h"
#import "HNTheme.h"
#import "FailedLoadingView.h"
#import "KGStatusBar.h"

@interface SubmitHNViewController ()

@property (nonatomic, assign) id HNObject;
@property (nonatomic, assign) SubmitHNType SubmitType;
@property (nonatomic, assign) NSNumber *CommentIndex;

// Submission
@property (strong, nonatomic) IBOutlet UIView *SubmitView;
@property (weak, nonatomic) IBOutlet UITextField *SubmitTitleTextField;
@property (weak, nonatomic) IBOutlet UITextField *SubmitLinkTextField;
@property (weak, nonatomic) IBOutlet UITextView *SubmitSelfTextView;
@property (weak, nonatomic) IBOutlet UILabel *SubmitHeaderLabel;
@property (weak, nonatomic) IBOutlet UIButton *SubmitDoneEditingButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomSubmitTextInset;

// Comment
@property (weak, nonatomic) IBOutlet UITextView *CommentTextView;
@property (strong, nonatomic) IBOutlet UIView *CommentView;
@property (weak, nonatomic) IBOutlet UIButton *CommentDoneEditing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomCommentInset;



@end

@implementation SubmitHNViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil type:(SubmitHNType)type hnObject:(id)hnObject commentIndex:(NSNumber *)index
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.SubmitType = type;
        self.HNObject = hnObject;
        self.CommentIndex = index;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register for Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard) name:@"HideKeyboard" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTheme) name:@"DidChangeTheme" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Build Nav
    [self buildNavBarForSubmit:YES];
    
    // Color UI
    [self colorUI];
    
    // Place Correct View in
    if (self.SubmitType == SubmitHNTypePost) {
        [self.view addSubview:self.SubmitView];
    }
    else {
        [self.view addSubview:self.CommentView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self setSizes];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[HNManager sharedManager] cancelAllRequests];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Autoresizing
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self buildNavBarForSubmit:YES];
}


#pragma mark - UI
-(void)setSizes {
    float newPostHeight = self.view.frame.size.height - self.SubmitSelfTextView.frame.origin.y - 20;
    self.SubmitSelfTextView.frame = CGRectMake(self.SubmitSelfTextView.frame.origin.x, self.SubmitSelfTextView.frame.origin.y, self.SubmitSelfTextView.frame.size.width,newPostHeight);
    self.CommentTextView.frame = CGRectMake(self.CommentTextView.frame.origin.x, self.CommentTextView.frame.origin.y, self.CommentTextView.frame.size.width, self.view.frame.size.height - self.CommentTextView.frame.origin.y - 20);
    
}

- (void)colorUI {
    self.view.backgroundColor = [HNTheme colorForElement:@"CellBG"];
    self.SubmitView.backgroundColor = [HNTheme colorForElement:@"CellBG"];
    self.SubmitLinkTextField.backgroundColor = [HNTheme colorForElement:@"BottomBar"];
    self.SubmitTitleTextField.backgroundColor = [HNTheme colorForElement:@"BottomBar"];
    self.SubmitSelfTextView.backgroundColor = [HNTheme colorForElement:@"BottomBar"];
    self.SubmitTitleTextField.textColor = [HNTheme colorForElement:@"MainFont"];
    self.SubmitLinkTextField.textColor = [HNTheme colorForElement:@"MainFont"];
    self.SubmitSelfTextView.textColor = [HNTheme colorForElement:@"MainFont"];
    self.CommentTextView.textColor = [HNTheme colorForElement:@"MainFont"];
    self.CommentView.backgroundColor = [HNTheme colorForElement:@"CellBG"];
    self.CommentTextView.backgroundColor = [HNTheme colorForElement:@"BottomBar"];
}

- (void)changeTheme {
    self.SubmitView.alpha = 0;
    self.CommentView.alpha = 0;
    [self colorUI];
    [UIView animateWithDuration:0.2 animations:^{
        self.SubmitView.alpha = 1;
        self.CommentView.alpha = 1;
    }];
}

#pragma mark - Build Nav Bar for Submit
- (void)buildNavBarForSubmit:(BOOL)submit {
    // Build Nav
    [Helpers buildNavigationController:self leftImage:NO rightImages:(submit ? @[@"Submit"] : nil) rightActions:(submit ? @[@"didPressSubmit"] : nil)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - TextView Delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (textView == self.SubmitSelfTextView) {
        [self animateSubmitViewUp:YES];
    }
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (textView == self.SubmitSelfTextView) {
        [self animateSubmitViewUp:NO];
    }
    
    return YES;
}

- (void)animateSubmitViewUp:(BOOL)up {
    if (up) {
        [UIView animateWithDuration:0.25 animations:^{
            self.SubmitView.frame = CGRectMake(0, -1*(self.SubmitDoneEditingButton.frame.origin.y), self.SubmitView.frame.size.width, self.SubmitView.frame.size.height);
            self.SubmitDoneEditingButton.alpha = 1;
        }];
    }
    else {
        [UIView animateWithDuration:0.25 animations:^{
            self.SubmitView.frame = CGRectMake(0, 0, self.SubmitView.frame.size.width, self.SubmitView.frame.size.height);
            self.SubmitDoneEditingButton.alpha = 0;
        }];
    }
}


#pragma mark - Keyboard
- (IBAction)didSelectDoneEditing:(id)sender {
    [self hideKeyboard];
}

- (void)hideKeyboard {
    [self.SubmitView endEditing:YES];
    [self.view endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat keyboardHeight = UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]) ? keyboardSize.width : keyboardSize.height;
    [self.bottomCommentInset setConstant:keyboardHeight+20];
    [self.bottomSubmitTextInset setConstant:keyboardHeight+20];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self.bottomCommentInset setConstant:20];
    [self.bottomSubmitTextInset setConstant:20];
}

#pragma mark - Submit
- (void)didPressSubmit {
    [self hideKeyboard];
    if (self.HNObject) {
        [self submitComment];
    }
    else {
        [self submitPost];
    }
}

#pragma mark - Submit Post
- (void)submitPost {
    // Build New Nav Bar
    [self buildNavBarForSubmit:NO];
    
    // Activity Indicator
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    [Helpers navigationController:self addActivityIndicator:&indicator];
    
    // Submit
    NSString *title = self.SubmitTitleTextField.text;
    NSString *link = self.SubmitLinkTextField.text.length > 0 ? self.SubmitLinkTextField.text : nil;
    NSString *text = self.SubmitSelfTextView.text.length > 0 ? self.SubmitSelfTextView.text : nil;
    [[HNManager sharedManager] submitPostWithTitle:title link:link text:text completion:^(BOOL success) {
        if (success) {
            [self dismissSelf];
            [KGStatusBar showWithStatus:@"Submission Success"];
        }
        else {
            [self buildNavBarForSubmit:YES];
            [KGStatusBar showWithStatus:@"Submission Failed"];
        }
        [indicator removeFromSuperview];
    }];
}


#pragma mark - Submit Comment
- (void)submitComment {
    // Build new Nav Bar
    [self buildNavBarForSubmit:NO];
    
    // Activity Indicator
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    [Helpers navigationController:self addActivityIndicator:&indicator];
    
    // Submit
    [[HNManager sharedManager] replyToPostOrComment:self.HNObject withText:self.CommentTextView.text completion:^(BOOL success) {
        if (success) {
            // Create Notification
            NSMutableDictionary *userInfo = [@{@"Comment":[self newComment]} mutableCopy];
            if (self.CommentIndex) {
                [userInfo setObject:self.CommentIndex forKey:@"Index"];
            }
            NSNotification *notification = [[NSNotification alloc] initWithName:@"DidSubmitNewComment" object:nil userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            
            // Dismiss
            [self dismissSelf];
            [KGStatusBar showWithStatus:@"Comment Submitted"];
        }
        else {
            [self buildNavBarForSubmit:YES];
            [KGStatusBar showWithStatus:@"Comment Failed"];
        }
        
        [indicator removeFromSuperview];
    }];
}

- (HNComment *)newComment {
    HNComment *newComment = [[HNComment alloc] init];
    newComment.Text = self.CommentTextView.text;
    newComment.Username = [HNManager sharedManager].SessionUser.Username;
    newComment.TimeCreatedString = @"0 minutes ago";
    newComment.Type = HNCommentTypeDefault;
    
    // Set Level
    if ([self.HNObject isKindOfClass:[HNComment class]]) {
        if ([(HNComment *)self.HNObject Type] == HNCommentTypeAskHN) {
            newComment.Level = 0;
        }
        else {
            newComment.Level = [(HNComment *)self.HNObject Level] + 1;
        }
    }
    
    // Return Comment
    return newComment;
}


#pragma mark - Dismiss VC
- (void)dismissSelf {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
