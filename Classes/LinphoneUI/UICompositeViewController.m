/* UICompositeViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UICompositeViewController.h"

#import "LinphoneAppDelegate.h"
#import "UIMainBar.h"

@implementation UICompositeViewDescription

@synthesize name;
@synthesize content;
@synthesize stateBar;
@synthesize stateBarEnabled;
@synthesize tabBar;
@synthesize tabBarEnabled;
@synthesize fullscreen;
@synthesize landscapeMode;
@synthesize portraitMode;

- (id)copy {
	UICompositeViewDescription *copy = [UICompositeViewDescription alloc];
	copy.content = self.content;
	copy.stateBar = self.stateBar;
	copy.stateBarEnabled = self.stateBarEnabled;
	copy.tabBar = self.tabBar;
	copy.tabBarEnabled = self.tabBarEnabled;
	copy.fullscreen = self.fullscreen;
	copy.landscapeMode = self.landscapeMode;
	copy.portraitMode = self.portraitMode;
	copy.darkBackground = self.darkBackground;
	return copy;
}

- (BOOL)equal:(UICompositeViewDescription *)description {
	return [self.name compare:description.name] == NSOrderedSame;
}

- (id)init:(NSString *)aname
			content:(NSString *)acontent
		   stateBar:(NSString *)astateBar
	stateBarEnabled:(BOOL)astateBarEnabled
			 tabBar:(NSString *)atabBar
	  tabBarEnabled:(BOOL)atabBarEnabled
		 fullscreen:(BOOL)afullscreen
	  landscapeMode:(BOOL)alandscapeMode
	   portraitMode:(BOOL)aportraitMode {
	self.name = aname;
	self.content = acontent;
	self.stateBar = astateBar;
	self.stateBarEnabled = astateBarEnabled;
	self.tabBar = atabBar;
	self.tabBarEnabled = atabBarEnabled;
	self.fullscreen = afullscreen;
	self.landscapeMode = alandscapeMode;
	self.portraitMode = aportraitMode;
	self.darkBackground = false;

	return self;
}

@end
@interface UICompositeViewController ()

@property(nonatomic, strong) UIViewController *stateBarViewController;
@property(nonatomic, strong) UIViewController *tabBarViewController;
@property(nonatomic, strong) UIViewController *contentViewController;

@end

@implementation UICompositeViewController

@synthesize stateBarView;
@synthesize contentView;
@synthesize tabBarView;
@synthesize tabBarViewController = _tabBarViewController;
@synthesize stateBarViewController = _stateBarViewController;
@synthesize contentViewController = _contentViewController;

@synthesize viewTransition;

#pragma mark - Lifecycle Functions

- (void)initUICompositeViewController {
	viewControllerCache = [[NSMutableDictionary alloc] init];
	currentOrientation = (UIInterfaceOrientation)UIDeviceOrientationUnknown;
}

- (id)init {
	self = [super init];
	if (self) {
		[self initUICompositeViewController];
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self initUICompositeViewController];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initUICompositeViewController];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Property Functions

- (UIViewController *)stateBarViewController {
	return _stateBarViewController;
}

- (UIViewController *)contentViewController {
	return _contentViewController;
}

- (UIViewController *)tabBarViewController {
	return _tabBarViewController;
}

#pragma mark - ViewController Functions

- (void)updateViewsFramesAccordingToLaunchOrientation {
	CGRect frame =
		[self.view frame]; // this view has the correct size at launch (1024/768 for iPad, 320*{568,480} for iPhone)
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	BOOL portrait = UIInterfaceOrientationIsPortrait(orientation);
	CGRect oppositeFrame = frame;
	oppositeFrame.size.height = frame.size.width;
	oppositeFrame.size.width = frame.size.height;

	// if we start in portrait, the landscape view must get the opposite height and width
	if (portrait || [[UIDevice currentDevice].systemVersion floatValue] < 8) {
		LOGI(@"landscape get opposite: %@", NSStringFromCGSize(oppositeFrame.size));
		[landscapeView setFrame:oppositeFrame];
	} else {
		// if we start in landscape, the landscape view has to get the current size,
		// whereas the portrait has to get the opposite
		LOGI(@"landscape get frame: %@ and portrait gets opposite: %@", NSStringFromCGSize(frame.size),
			 NSStringFromCGSize(oppositeFrame.size));
		[landscapeView setFrame:frame];
		[portraitView setFrame:oppositeFrame];
	}
}

- (void)viewDidLoad {
	/* Force landscape view to match portrait view, because portrait view inherits
	   the device screen size at load */
	[self updateViewsFramesAccordingToLaunchOrientation];
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.contentViewController viewWillAppear:animated];
	[self.tabBarViewController viewWillAppear:animated];
	[self.stateBarViewController viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(orientationDidChange:)
												 name:UIDeviceOrientationDidChangeNotification
											   object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.contentViewController viewDidAppear:animated];
	[self.tabBarViewController viewDidAppear:animated];
	[self.stateBarViewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.contentViewController viewWillDisappear:animated];
	[self.tabBarViewController viewWillDisappear:animated];
	[self.stateBarViewController viewWillDisappear:animated];

	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self.contentViewController viewDidDisappear:animated];
	[self.tabBarViewController viewDidDisappear:animated];
	[self.stateBarViewController viewDidDisappear:animated];
}

#pragma mark - Rotation messages

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
								duration:(NSTimeInterval)duration {
	currentOrientation = toInterfaceOrientation;
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.contentViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.tabBarViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.stateBarViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
											duration:duration]; // Will invoke TPMultiLayout
	[self.contentViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.tabBarViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.stateBarViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self update:nil tabBar:nil stateBar:nil fullscreen:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.contentViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.tabBarViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.stateBarViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (interfaceOrientation == currentOrientation)
		return YES;
	return NO;
}

#pragma mark - Event Functions

- (void)orientationDidChange:(NSNotification *)notif {
	// Update rotation
	UIInterfaceOrientation correctOrientation =
		[self getCorrectInterfaceOrientation:[[UIDevice currentDevice] orientation]];
	if (currentOrientation != correctOrientation) {
		[UICompositeViewController setOrientation:correctOrientation
										 animated:currentOrientation != UIDeviceOrientationUnknown];
	}
}

#pragma mark -

/*
 Will simulate a device rotation
 */
+ (void)setOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated {
	UIView *firstResponder = nil;

	UIViewController *controller = nil;

	controller = [[UIApplication sharedApplication] keyWindow].rootViewController;
	CGRect frame = [[UIScreen mainScreen] bounds];
	UIInterfaceOrientation oldOrientation = controller.interfaceOrientation;

	NSTimeInterval animationDuration = animated ? 0.3f : 0.0;

	[controller willRotateToInterfaceOrientation:orientation duration:animationDuration];
	[controller willAnimateRotationToInterfaceOrientation:orientation duration:animationDuration];
	[controller didRotateFromInterfaceOrientation:oldOrientation];
	[UIView animateWithDuration:animationDuration
					 animations:^{
					   [controller.view setFrame:frame];
					 }];

	if (firstResponder == nil) {
		firstResponder = [UICompositeViewController findFirstResponder:controller.view];
	}

	[[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:animated];
	if (firstResponder) {
		[firstResponder resignFirstResponder];
		[firstResponder becomeFirstResponder];
	}
}

+ (UIView *)findFirstResponder:(UIView *)view {
	if (view.isFirstResponder) {
		return view;
	}
	for (UIView *subView in view.subviews) {
		UIView *ret = [UICompositeViewController findFirstResponder:subView];
		if (ret != nil)
			return ret;
	}
	return nil;
}

- (void)clearCache:(NSArray *)exclude {
	for (NSString *key in [viewControllerCache allKeys]) {
		bool remove = true;
		if (exclude != nil) {
			for (UICompositeViewDescription *description in exclude) {
				if ([key isEqualToString:description.content] || [key isEqualToString:description.stateBar] ||
					[key isEqualToString:description.tabBar]) {
					remove = false;
					break;
				}
			}
		}
		if (remove) {
			LOGI(@"Free cached view: %@", key);
			[viewControllerCache removeObjectForKey:key];
		}
	}
}

- (UIInterfaceOrientation)currentOrientation {
	return currentOrientation;
}

+ (void)addSubView:(UIViewController *)controller view:(UIView *)view {
	if (controller != nil) {
		[view addSubview:controller.view];
        if ([controller isKindOfClass:[UIMainBar class]]) {
            [view bringSubviewToFront:controller.view];
        }
	}
}

+ (void)removeSubView:(UIViewController *)controller {
	if (controller != nil) {
		[controller.view removeFromSuperview];
	}
}

- (UIViewController *)getCachedController:(NSString *)name {
	UIViewController *controller = nil;
	if (name != nil) {
		controller = [viewControllerCache objectForKey:name];
		if (controller == nil) {
			controller = [[NSClassFromString(name) alloc] init];
			[viewControllerCache setValue:controller forKey:name];
			[controller view]; // Load the view
		}
	}
	return controller;
}

- (UIInterfaceOrientation)getCorrectInterfaceOrientation:(UIDeviceOrientation)deviceOrientation {
	if (currentViewDescription != nil) {
		// If unknown return status bar orientation
		if (deviceOrientation == UIDeviceOrientationUnknown && currentOrientation == UIDeviceOrientationUnknown) {
			return [UIApplication sharedApplication].statusBarOrientation;
		}

		// Don't rotate in UIDeviceOrientationFaceUp UIDeviceOrientationFaceDown
		if (!UIDeviceOrientationIsPortrait(deviceOrientation) && !UIDeviceOrientationIsLandscape(deviceOrientation)) {
			if (currentOrientation == UIDeviceOrientationUnknown) {
				return [UIApplication sharedApplication].statusBarOrientation;
			}
			deviceOrientation = (UIDeviceOrientation)currentOrientation;
		}
		if (UIDeviceOrientationIsPortrait(deviceOrientation)) {
			if ([currentViewDescription portraitMode]) {
				return (UIInterfaceOrientation)deviceOrientation;
			} else {
				return UIInterfaceOrientationLandscapeLeft;
			}
		}
		if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
			if ([currentViewDescription landscapeMode]) {
				return (UIInterfaceOrientation)deviceOrientation;
			} else {
				return UIInterfaceOrientationPortrait;
			}
		}
	}
	return UIInterfaceOrientationPortrait;
}

#define IPHONE_STATUSBAR_HEIGHT 20

- (void)update:(UICompositeViewDescription *)description
		tabBar:(NSNumber *)tabBar
	  stateBar:(NSNumber *)stateBar
	fullscreen:(NSNumber *)fullscreen {

	UIViewController *oldContentViewController = self.contentViewController;
	UIViewController *oldStateBarViewController = self.stateBarViewController;
	UIViewController *oldTabBarViewController = self.tabBarViewController;
	// Copy view description
	UICompositeViewDescription *oldViewDescription = nil;

	if (description != nil) {
		oldViewDescription = currentViewDescription;
		currentViewDescription = [description copy];

		// Animate only with a previous screen
		if (oldViewDescription != nil && viewTransition != nil) {
			[contentView.layer removeAnimationForKey:@"transition"];
			[contentView.layer addAnimation:viewTransition forKey:@"transition"];
			if (oldViewDescription.stateBar != currentViewDescription.stateBar ||
				oldViewDescription.stateBarEnabled != currentViewDescription.stateBarEnabled ||
				[stateBarView.layer animationForKey:@"transition"] != nil) {
				[stateBarView.layer removeAnimationForKey:@"transition"];
				[stateBarView.layer addAnimation:viewTransition forKey:@"transition"];
			}
			if (oldViewDescription.tabBar != currentViewDescription.tabBar ||
				oldViewDescription.tabBarEnabled != currentViewDescription.tabBarEnabled ||
				[tabBarView.layer animationForKey:@"transition"] != nil) {
				[tabBarView.layer removeAnimationForKey:@"transition"];
				[tabBarView.layer addAnimation:viewTransition forKey:@"transition"];
			}
		}

		UIViewController *newContentViewController = [self getCachedController:description.content];
		UIViewController *newStateBarViewController = [self getCachedController:description.stateBar];
		UIViewController *newTabBarViewController = [self getCachedController:description.tabBar];

		[UICompositeViewController removeSubView:oldContentViewController];
		if (oldTabBarViewController != nil && oldTabBarViewController != newTabBarViewController) {
			[UICompositeViewController removeSubView:oldTabBarViewController];
		}
		if (oldStateBarViewController != nil && oldStateBarViewController != newStateBarViewController) {
			[UICompositeViewController removeSubView:oldStateBarViewController];
		}

		self.stateBarViewController = newStateBarViewController;
		self.contentViewController = newContentViewController;
		self.tabBarViewController = newTabBarViewController;

		// Update rotation
		UIInterfaceOrientation correctOrientation = [self
			getCorrectInterfaceOrientation:(UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation];
		if (currentOrientation != correctOrientation) {
			[UICompositeViewController setOrientation:correctOrientation
											 animated:currentOrientation != UIDeviceOrientationUnknown];
			if (UIInterfaceOrientationIsLandscape(correctOrientation)) {
				[self.contentViewController willAnimateRotationToInterfaceOrientation:correctOrientation duration:0];
				[self.tabBarViewController willAnimateRotationToInterfaceOrientation:correctOrientation duration:0];
				[self.stateBarViewController willAnimateRotationToInterfaceOrientation:correctOrientation duration:0];
			}
		} else {
			if (oldContentViewController != newContentViewController) {
				UIInterfaceOrientation oldOrientation = self.contentViewController.interfaceOrientation;
				[self.contentViewController willRotateToInterfaceOrientation:correctOrientation duration:0];
				[self.contentViewController willAnimateRotationToInterfaceOrientation:correctOrientation duration:0];
				[self.contentViewController didRotateFromInterfaceOrientation:oldOrientation];
			}
			if (oldTabBarViewController != newTabBarViewController) {
				UIInterfaceOrientation oldOrientation = self.tabBarViewController.interfaceOrientation;
				[self.tabBarViewController willRotateToInterfaceOrientation:correctOrientation duration:0];
				[self.tabBarViewController willAnimateRotationToInterfaceOrientation:correctOrientation duration:0];
				[self.tabBarViewController didRotateFromInterfaceOrientation:oldOrientation];
			}
			if (oldStateBarViewController != newStateBarViewController) {
				UIInterfaceOrientation oldOrientation = self.stateBarViewController.interfaceOrientation;
				[self.stateBarViewController willRotateToInterfaceOrientation:correctOrientation duration:0];
				[self.stateBarViewController willAnimateRotationToInterfaceOrientation:correctOrientation duration:0];
				[self.stateBarViewController didRotateFromInterfaceOrientation:oldOrientation];
			}
		}
	} else {
		oldViewDescription = (currentViewDescription != nil) ? [currentViewDescription copy] : nil;
	}

	if (currentViewDescription == nil) {
		return;
	}

	if (tabBar != nil) {
		if (currentViewDescription.tabBarEnabled != [tabBar boolValue]) {
			currentViewDescription.tabBarEnabled = [tabBar boolValue];
		} else {
			tabBar = nil; // No change = No Update
		}
	}

	if (stateBar != nil) {
		if (currentViewDescription.stateBarEnabled != [stateBar boolValue]) {
			currentViewDescription.stateBarEnabled = [stateBar boolValue];
		} else {
			stateBar = nil; // No change = No Update
		}
	}

	if (fullscreen != nil) {
		if (currentViewDescription.fullscreen != [fullscreen boolValue]) {
			currentViewDescription.fullscreen = [fullscreen boolValue];
			[[UIApplication sharedApplication] setStatusBarHidden:currentViewDescription.fullscreen
													withAnimation:UIStatusBarAnimationSlide];
		} else {
			fullscreen = nil; // No change = No Update
		}
	} else {
		[[UIApplication sharedApplication] setStatusBarHidden:currentViewDescription.fullscreen
												withAnimation:UIStatusBarAnimationNone];
	}

	// Start animation
	if (tabBar != nil || stateBar != nil || fullscreen != nil) {
		[UIView beginAnimations:@"resize" context:nil];
		[UIView setAnimationDuration:0.35];
		[UIView setAnimationBeginsFromCurrentState:TRUE];
	}

	CGRect contentFrame = contentView.frame;
	CGRect viewFrame = [self.view frame];

	// Resize StateBar
	CGRect stateBarFrame = stateBarView.frame;
	int origin = IPHONE_STATUSBAR_HEIGHT;
	if (currentViewDescription.fullscreen)
		origin = 0;

	if (self.stateBarViewController != nil && currentViewDescription.stateBarEnabled) {
		contentFrame.origin.y = origin + stateBarFrame.size.height;
		stateBarFrame.origin.y = origin;
	} else {
		contentFrame.origin.y = origin;
		stateBarFrame.origin.y = origin - stateBarFrame.size.height;
	}

	// Resize TabBar
	CGRect tabFrame = tabBarView.frame;
	if (self.tabBarViewController != nil && currentViewDescription.tabBarEnabled) {
		tabFrame.origin.y = viewFrame.size.height;
		tabFrame.origin.x = viewFrame.size.width;
		tabFrame.size.height = self.tabBarViewController.view.frame.size.height;
		// tabFrame.size.width = self.tabBarViewController.view.frame.size.width;
		tabFrame.origin.y -= tabFrame.size.height;
		tabFrame.origin.x -= tabFrame.size.width;
        contentFrame.size.height = viewFrame.size.height - contentFrame.origin.y - 70;

		// for some views, we need the content to overlap, in which case
		// we insert in the tab XIB a mask with tag -1 and with y = the amount of
		// points that the content should overlap.
//		for (UIView *view in self.tabBarViewController.view.subviews) {
//			if (view.tag == -1) {
//				contentFrame.size.height += view.frame.origin.y;
//				break;
//			}
//		}
	} else {
		contentFrame.size.height = viewFrame.size.height - contentFrame.origin.y;
		tabFrame.origin.y = viewFrame.size.height;
	}

	if (currentViewDescription.fullscreen) {
		contentFrame.origin.y = origin;
		contentFrame.size.height = viewFrame.size.height - contentFrame.origin.y;
	}

	// Set frames
	[contentView setFrame:contentFrame];
	[self.contentViewController.view setFrame:[contentView bounds]];
	[tabBarView setFrame:tabFrame];
	CGRect frame = [self.tabBarViewController.view frame];
	frame.size.width = [tabBarView bounds].size.width;
	[self.tabBarViewController.view setFrame:frame];
	[stateBarView setFrame:stateBarFrame];
	frame = [self.stateBarViewController.view frame];
	frame.size.width = [stateBarView bounds].size.width;
	[self.stateBarViewController.view setFrame:frame];

	// Commit animation
	if (tabBar != nil || stateBar != nil || fullscreen != nil) {
		[UIView commitAnimations];
	}

	// Change view
	if (description != nil) {
		[UICompositeViewController addSubView:self.contentViewController view:contentView];
		if (oldTabBarViewController == nil || oldTabBarViewController != self.tabBarViewController) {
			[UICompositeViewController addSubView:self.tabBarViewController view:tabBarView];
		}
		if (oldStateBarViewController == nil || oldStateBarViewController != self.stateBarViewController) {
			[UICompositeViewController addSubView:self.stateBarViewController view:stateBarView];
		}
	}

	// Dealloc old view description
}

- (void)changeView:(UICompositeViewDescription *)description {
	[self view]; // Force view load
	[self update:description tabBar:nil stateBar:nil fullscreen:nil];
}

- (void)setFullScreen:(BOOL)enabled {
	[self update:nil tabBar:nil stateBar:nil fullscreen:[NSNumber numberWithBool:enabled]];
}

- (void)setToolBarHidden:(BOOL)hidden {
	[self update:nil tabBar:[NSNumber numberWithBool:!hidden] stateBar:nil fullscreen:nil];
}

- (void)setStateBarHidden:(BOOL)hidden {
	[self update:nil tabBar:nil stateBar:[NSNumber numberWithBool:!hidden] fullscreen:nil];
}

- (UIViewController *)getCurrentViewController {
	return self.contentViewController;
}

- (BOOL)currentViewSupportsLandscape {
	return currentViewDescription ? currentViewDescription.landscapeMode : FALSE;
}

@end
