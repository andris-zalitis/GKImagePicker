//
//  GKImagePicker.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImagePicker.h"

#import "GKImageCropViewController.h"


// iOS version helper
#define SYSTEM_VERSION_LESS_THAN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


@interface GKImagePicker ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, GKImageCropControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIView *popoverView;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
- (void)_hideController;
@end

@implementation GKImagePicker
{
    BOOL _usePopover;
}

#pragma mark -
#pragma mark Getter/Setter

@synthesize cropSize, delegate, resizeableCropArea;

#pragma mark -
#pragma mark Init Methods

- (id)init{
    if (self = [super init]) {
        
        self.cropSize = CGSizeMake(320, 320);
        self.resizeableCropArea = NO;
        // use popovers on iPad by default as currently
        self.preferFullScreen = YES;
    }
    return self;
}

# pragma mark -
# pragma mark Private Methods

- (void)_hideController{
    if (_usePopover) {
        [self.popoverController dismissPopoverAnimated:YES];
    } else {
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }

}

#pragma mark -
#pragma mark UIImagePickerDelegate Methods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    if ([self.delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
      
        [self.delegate imagePickerDidCancel:self];
        
    } else {
        
        [self _hideController];
    
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{

    GKImageCropViewController *cropController = [[GKImageCropViewController alloc] init];
    
    // iOS7+
    if ([cropController respondsToSelector:@selector(setPreferredContentSize:)]) {
        cropController.preferredContentSize = picker.preferredContentSize;
    } else {
        cropController.contentSizeForViewInPopover = picker.contentSizeForViewInPopover;
    }
    cropController.sourceImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    cropController.resizeableCropArea = self.resizeableCropArea;
    cropController.cropSize = self.cropSize;
    cropController.delegate = self;
    [picker pushViewController:cropController animated:YES];
    
}

#pragma mark -
#pragma GKImagePickerDelegate

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage{
    
    if ([self.delegate respondsToSelector:@selector(imagePicker:pickedImage:)]) {
        [self _hideController];
        [self.delegate imagePicker:self pickedImage:croppedImage];
    }
}


#pragma mark -
#pragma mark - Action Sheet and Image Pickers

- (void)showActionSheetOnViewController:(UIViewController *)viewController onPopoverFromView:(UIView *)popoverView
{
    self.presentingViewController = viewController;
    self.popoverView = popoverView;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:(id)self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Image from Camera", @"Image from Camera"), NSLocalizedString(@"Image from Library", @"Image from Library"), nil];
    actionSheet.delegate = self;
    
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        [actionSheet showFromRect:[self calcPopoverSourceRect] inView:self.presentingViewController.view animated:YES];
    } else {
        if (self.presentingViewController.navigationController.toolbar) {
            [actionSheet showFromToolbar:self.presentingViewController.navigationController.toolbar];
        } else {
            [actionSheet showInView:self.presentingViewController.view];
        }
    }
}

- (CGRect)calcPopoverSourceRect
{
    return [self.popoverView convertRect:self.popoverView.frame toView:self.presentingViewController.view];
}

- (void)presentImagePickerController
{
    // we use popover only if a) we are on iPad and b) we don't prefer full screen or c) system version is less than 7
    _usePopover = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && (!self.preferFullScreen || SYSTEM_VERSION_LESS_THAN(@"7.0"));
    
    if (_usePopover) {
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
        [self.popoverController presentPopoverFromRect:[self calcPopoverSourceRect]
                                                inView:self.presentingViewController.view
                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                              animated:YES];
        
    } else {
        
        [self.presentingViewController presentViewController:self.imagePickerController animated:YES completion:nil];
        
    }
}

- (void)showImagePickerOnViewController:(UIViewController *)viewController onPopoverFromView:(UIView *)popoverView withGallerySource:(BOOL)sourceIsGallery
{
    self.presentingViewController = viewController;
    self.popoverView = popoverView;
    
    if (sourceIsGallery) {
        [self showGalleryImagePicker];
    } else {
        [self showCameraImagePicker];
    }
}

- (void)showCameraImagePicker {

#if TARGET_IPHONE_SIMULATOR

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Simulator" message:@"Camera not available." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
#elif TARGET_OS_IPHONE
    
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = NO;

    [self presentImagePickerController];
#endif

}

- (void)showGalleryImagePicker {
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = NO;

    [self presentImagePickerController];
}

#pragma mark -
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self showCameraImagePicker];
            break;
        case 1:
            [self showGalleryImagePicker];
            break;
    }
}

@end
