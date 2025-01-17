//
//  Copyright © 2018-2023 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//
#import "PspdfPlatformView.h"
#import "PspdfkitFlutterHelper.h"
#import "PspdfkitFlutterConverter.h"
#import "pspdfkit_flutter-Swift.h"

@import PSPDFKit;
@import PSPDFKitUI;

@interface PspdfPlatformView() <PSPDFViewControllerDelegate>
@property int64_t platformViewId;
@property (nonatomic) FlutterMethodChannel *channel;
@property (nonatomic, weak) UIViewController *flutterViewController;
@property (nonatomic) PSPDFViewController *pdfViewController;
@property (nonatomic) PSPDFNavigationController *navigationController;
@end

@implementation PspdfPlatformView

- (nonnull UIView *)view {
    return self.navigationController.view ?: [UIView new];
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args messenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    if ((self = [super init])) {
        NSString *name = [NSString stringWithFormat:@"com.pspdfkit.widget.%lld", viewId];
        _platformViewId = viewId;
        _channel = [FlutterMethodChannel methodChannelWithName:name binaryMessenger:messenger];

        _navigationController = [PSPDFNavigationController new];
        _navigationController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _navigationController.view.frame = frame;

        // View controller containment
        _flutterViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        if (_flutterViewController == nil) {
            NSLog(@"Warning: FlutterViewController is nil. This may lead to view container containment problems with PSPDFViewController since we no longer receive UIKit lifecycle events.");
        } else {
            [_flutterViewController addChildViewController:_navigationController];
            [_navigationController didMoveToParentViewController:_flutterViewController];
        }

        NSString *documentPath = args[@"document"];
        if ([documentPath isKindOfClass:[NSString class]] == NO || [documentPath length] == 0) {
            NSLog(@"Warning: 'document' argument is not a string. Showing an empty view in default configuration.");
            _pdfViewController = [[PSPDFViewController alloc] init];
        } else {
           
            NSDictionary *configurationDictionary = [PspdfkitFlutterConverter processConfigurationOptionsDictionaryForPrefix:args[@"configuration"]];
            PSPDFDocument *document = [PspdfkitFlutterHelper documentFromPath:documentPath];
          
            [PspdfkitFlutterHelper unlockWithPasswordIfNeeded:document dictionary:configurationDictionary];

            BOOL isImageDocument = [PspdfkitFlutterHelper isImageDocument:documentPath];
            PSPDFConfiguration *configuration = [PspdfkitFlutterConverter configuration:configurationDictionary isImageDocument:isImageDocument];
            _pdfViewController = [[PSPDFViewController alloc] initWithDocument:document configuration:configuration];
            _pdfViewController.appearanceModeManager.appearanceMode = [PspdfkitFlutterConverter appearanceMode:configurationDictionary];
            _pdfViewController.pageIndex = [PspdfkitFlutterConverter pageIndex:configurationDictionary];
            _pdfViewController.delegate = self;
            // _pdfViewController.annotationToolbar.toolbar.setDragEnabled = false;
            _pdfViewController.annotationToolbarController.toolbar.dragEnabled = false;
            _pdfViewController.annotationToolbarController.toolbar.toolbarPosition = PSPDFFlexibleToolbarPositionTop;

            if ((id)configurationDictionary != NSNull.null) {
                NSString *key = @"leftBarButtonItems";
                if (configurationDictionary[key]) {
                    [PspdfkitFlutterHelper setLeftBarButtonItems:configurationDictionary[key] forViewController:_pdfViewController];
                }
                key = @"rightBarButtonItems";
                if (configurationDictionary[key]) {
                    [PspdfkitFlutterHelper setRightBarButtonItems:configurationDictionary[key] forViewController:_pdfViewController];
                }
                key = @"invertColors";
                if (configurationDictionary[key]) {
                    _pdfViewController.appearanceModeManager.appearanceMode = [configurationDictionary[key] boolValue] ? PSPDFAppearanceModeNight : PSPDFAppearanceModeDefault;
                }
                key = @"toolbarTitle";
                if (configurationDictionary[key]) {
                    [PspdfkitFlutterHelper setToolbarTitle:configurationDictionary[key] forViewController:_pdfViewController];
                }
            }
        }

        if (_pdfViewController.configuration.userInterfaceViewMode == PSPDFUserInterfaceViewModeNever) {
            // In this mode PDFViewController doesn’t hide the navigation bar on its own to avoid getting stuck.
            _navigationController.navigationBarHidden = YES;
        }
        [_navigationController setViewControllers:@[_pdfViewController] animated:NO];

        __weak id weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf handleMethodCall:call result:result];
        }];
        PSPDFAnnotationToolbarConfiguration *configuration = [[PSPDFAnnotationToolbarConfiguration alloc] initWithAnnotationGroups:@[
             [PSPDFAnnotationGroup groupWithItems:@[
                 [PSPDFAnnotationGroupItem itemWithType:PSPDFAnnotationStringHighlight],
             ]],
             [PSPDFAnnotationGroup groupWithItems:@[
                 [PSPDFAnnotationGroupItem itemWithType:PSPDFAnnotationStringUnderline]
             ]]
         ]];

         _pdfViewController.annotationToolbarController.annotationToolbar.configurations = @[configuration];
    }

    return self;
}

- (void)dealloc {
    [self cleanup];
}

- (void)cleanup {
    self.pdfViewController.document = nil;
    [self.pdfViewController.view removeFromSuperview];
    [self.pdfViewController removeFromParentViewController];
    [self.navigationController.navigationBar removeFromSuperview];
    [self.navigationController.view removeFromSuperview];
    [self.navigationController removeFromParentViewController];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    [PspdfkitFlutterHelper processMethodCall:call result:result forViewController:self.pdfViewController];
}

# pragma mark - PSPDFViewControllerDelegate

- (void)pdfViewControllerDidDismiss:(PSPDFViewController *)pdfController {
    // Don't hold on to the view controller object after dismissal.
    [self cleanup];
}

@end
