//
//  OWDashboardViewController.m
//  OpenWatch
//
//  Created by Christopher Ballinger on 5/2/13.
//  Copyright (c) 2013 OpenWatch FPC. All rights reserved.
//

#import "OWDashboardViewController.h"
#import "OWUtilities.h"
#import "OWCaptureViewController.h"
#import "OWAccountAPIClient.h"
#import "OWSettingsViewController.h"
#import "OWLocalMediaObjectListViewController.h"
#import "OWStrings.h"
#import "OWFeedViewController.h"
#import "OWFeedSelectionViewController.h"
#import "OWInvestigationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OWSettingsController.h"
#import "OWFeedViewController.h"
#import "OWDashboardItem.h"
#import "OWPhoto.h"
#import "OWLocationController.h"
#import "OWLocalMediaEditViewController.h"
#import "OWAppDelegate.h"
#import "OWShareController.h"

#define kActionBarHeight 70.0f


@interface OWDashboardViewController ()

@end

@implementation OWDashboardViewController
@synthesize onboardingView, dashboardView, imagePicker, audioRecorder, editController;

- (id)init
{
    self = [super init];
    if (self) {
        self.dashboardView = [[OWDashboardView alloc] initWithFrame:CGRectZero];
        OWDashboardItem *videoItem = [[OWDashboardItem alloc] initWithTitle:@"Broadcast Video" image:[UIImage imageNamed:@"285-facetime.png"] target:self selector:@selector(recordButtonPressed:)];
        OWDashboardItem *photoItem = [[OWDashboardItem alloc] initWithTitle:@"Take Photo" image:[UIImage imageNamed:@"86-camera.png"] target:self selector:@selector(photoButtonPressed:)];
        OWDashboardItem *audioItem = [[OWDashboardItem alloc] initWithTitle:@"Record Audio" image:[UIImage imageNamed:@"66-microphone.png"] target:self selector:@selector(audioButtonPressed:)];
        
        OWDashboardItem *topStories = [[OWDashboardItem alloc] initWithTitle:@"Top Stories" image:[UIImage imageNamed:@"28-star.png"] target:self selector:@selector(feedButtonPressed:)];
        OWDashboardItem *yourMedia = [[OWDashboardItem alloc] initWithTitle:@"Your Media" image:[UIImage imageNamed:@"160-voicemail-2.png"] target:self selector:@selector(yourMediaPressed:)];
        OWDashboardItem *settings = [[OWDashboardItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:@"19-gear.png"] target:self selector:@selector(settingsButtonPressed:)];
        
        NSArray *topItems = @[videoItem, photoItem, audioItem];
        NSArray *bottonItems = @[topStories, yourMedia, settings];
        NSArray *dashboardItems = @[topItems, bottonItems];
        dashboardView.dashboardItems = dashboardItems;        
    }
    return self;
}

- (void) audioButtonPressed:(id)sender {
    self.audioRecorder = [[OWAudioRecordingViewController alloc] init];
    audioRecorder.delegate = self;
    OWLocationController *locationController = [OWLocationController sharedInstance];
    [locationController startWithDelegate:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:audioRecorder];
    [self presentViewController:navController animated:YES completion:^{
        [self pushEditView];
    }];
}

- (void) recordButtonPressed:(id)sender {
    OWCaptureViewController *captureVC = [[OWCaptureViewController alloc] init];
    captureVC.delegate = self;
    [self presentViewController:captureVC animated:YES completion:^{
        [self pushEditView];
    }];
}

- (void) pushEditView {
    self.editController = [[OWLocalMediaEditViewController alloc] init];
    self.editController.showingAfterCapture = YES;
    [self.navigationController pushViewController:editController animated:YES];
}

- (void) photoButtonPressed:(id)sender {
    OWLocationController *locationController = [OWLocationController sharedInstance];
    [locationController startWithDelegate:nil];
    
    if (!self.imagePicker) {
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    BOOL canTakePhoto = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    if (canTakePhoto) {
        [self presentViewController:imagePicker animated:YES completion:^{
            [self pushEditView];
        }];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Available" message:@"Sorry, this device can't take photos." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}



- (void) feedButtonPressed:(id)sender {
    OWFeedViewController *feedVC = [[OWFeedViewController alloc] init];
    [feedVC didSelectFeedWithName:@"Top Stories" type:kOWFeedTypeFrontPage];
    [self.navigationController pushViewController:feedVC animated:YES];
}



- (void) yourMediaPressed:(id)sender {
    OWLocalMediaObjectListViewController *recordingListVC = [[OWLocalMediaObjectListViewController alloc] init];
    [self.navigationController pushViewController:recordingListVC animated:YES];
}

- (void) settingsButtonPressed:(id) sender {
    OWSettingsViewController *settingsVC = [[OWSettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsVC animated:YES];
}

- (void) comingSoon:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Coming soon!" message:@"Sorry I haven't written that part yet. Check back later!" delegate:nil cancelButtonTitle:@"Cool" otherButtonTitles:nil];
    [alert show];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:dashboardView];
    [self updateUserAccountInformation];
    
    self.view.backgroundColor = [OWUtilities stoneBackgroundPattern];
    
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"openwatch.png"]];
    imageView.frame = CGRectMake(0, 0, 140, 25);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.titleView = imageView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat navigationBarHeightHack = 0.0f;
    
    if (self.navigationController.navigationBarHidden) {
        navigationBarHeightHack = self.navigationController.navigationBar.frame.size.height;
    }
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    
    self.dashboardView.frame = self.view.bounds;
    
    OWAccount *account = [OWSettingsController sharedInstance].account;

    if (!account.hasCompletedOnboarding && !self.onboardingView) {
        CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - navigationBarHeightHack);
        self.onboardingView = [[OWOnboardingView alloc] initWithFrame:frame];
        self.onboardingView.delegate = self;
        //self.onboardingView.frame = frame;
        [self.view addSubview:onboardingView];
    }
}

- (void) updateUserAccountInformation {
    OWAccount *account = [OWSettingsController sharedInstance].account;
    [[OWAccountAPIClient sharedClient] updateUserSecretAgentStatus:account.secretAgentEnabled];
    if (!account.secretAgentEnabled) {
        return;
    }
    [[OWLocationController sharedInstance] startWithDelegate:self];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
}

- (void) locationUpdated:(CLLocation *)location {
    OWLocationController *locationController = [OWLocationController sharedInstance];
    [locationController stop];
    OWAccount *account = [OWSettingsController sharedInstance].account;
    if (account.secretAgentEnabled) {
        [[OWAccountAPIClient sharedClient] updateUserLocation:location];
    }
}

- (void) onboardingViewDidComplete:(OWOnboardingView *)ow {
    OWAccount *account = [OWSettingsController sharedInstance].account;
    account.hasCompletedOnboarding = YES;
    account.secretAgentEnabled = onboardingView.agentSwitch.on;
    [self updateUserAccountInformation];
    [UIView animateWithDuration:2.0 animations:^{
        self.onboardingView.layer.opacity = 0.0f;
    } completion:^(BOOL finished) {
        [self.onboardingView removeFromSuperview];
        self.onboardingView = nil;
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    OWPhoto *photo = [OWPhoto photoWithImage:image];
    photo.firstPostedDate = [NSDate date];
    OWLocationController *locationController = [OWLocationController sharedInstance];
    photo.endLocation = locationController.currentLocation;
    [locationController stop];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    
    self.editController.objectID = photo.objectID;
    
    [[OWAccountAPIClient sharedClient] postObjectWithUUID:photo.uuid objectClass:photo.class success:nil failure:nil];

    [self.imagePicker dismissViewControllerAnimated:YES completion:^{
        self.imagePicker = nil;
    }];
    
    NSLog(@"photo created: %@", photo.description);
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    OWLocationController *locationController = [OWLocationController sharedInstance];
    [locationController stop];
    [self.imagePicker dismissViewControllerAnimated:YES completion:^{
        self.imagePicker = nil;
    }];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void) recordingViewController:(OWAudioRecordingViewController *)recordingViewController didFinishRecording:(OWAudio *)audio {
    OWLocationController *locationController = [OWLocationController sharedInstance];
    [locationController stop];
    audio.firstPostedDate = [NSDate date];
    audio.endLocation = locationController.currentLocation;
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    
    self.editController.objectID = audio.objectID;

    
    [[OWAccountAPIClient sharedClient] postObjectWithUUID:audio.uuid objectClass:audio.class success:nil failure:nil];
    
    [self.audioRecorder dismissViewControllerAnimated:YES completion:^{
        self.audioRecorder = nil;
    }];
}

- (void) recordingViewControllerDidCancel:(OWAudioRecordingViewController *)recordingViewController {
    OWLocationController *locationController = [OWLocationController sharedInstance];
    [locationController stop];
    [self.audioRecorder dismissViewControllerAnimated:YES completion:^{
        self.audioRecorder = nil;
    }];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void) captureViewController:(OWCaptureViewController *)captureViewController didFinishRecording:(OWLocalRecording *)recording {
    self.editController.objectID = recording.objectID;
    [captureViewController dismissViewControllerAnimated:YES completion:^{
         
     }];
    
}

- (void) captureViewControllerDidCancel:(OWCaptureViewController *)captureViewController{
    [self.navigationController popToRootViewControllerAnimated:NO];
}


@end
