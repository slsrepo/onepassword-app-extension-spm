//
//  1Password Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OnePasswordExtension.h"

// Version
#define VERSION_NUMBER @(112)
static NSString *const AppExtensionVersionNumberKey = @"version_number";

// Available App Extension Actions
static NSString *const kUTTypeAppExtensionFindLoginAction = @"org.appextension.find-login-action";
static NSString *const kUTTypeAppExtensionSaveLoginAction = @"org.appextension.save-login-action";
static NSString *const kUTTypeAppExtensionChangePasswordAction = @"org.appextension.change-password-action";
static NSString *const kUTTypeAppExtensionFillWebViewAction = @"org.appextension.fill-webview-action";
static NSString *const kUTTypeAppExtensionFillBrowserAction = @"org.appextension.fill-browser-action";

// WebView Dictionary keys
static NSString *const AppExtensionWebViewPageFillScript = @"fillScript";
static NSString *const AppExtensionWebViewPageDetails = @"pageDetails";

@implementation OnePasswordExtension

#pragma mark - Public Methods

+ (OnePasswordExtension *)sharedExtension {
	static dispatch_once_t onceToken;
	static OnePasswordExtension *__sharedExtension;

	dispatch_once(&onceToken, ^{
		__sharedExtension = [OnePasswordExtension new];
	});

	return __sharedExtension;
}

- (BOOL)isSystemAppExtensionAPIAvailable {
#ifdef __IPHONE_8_0
	return NSClassFromString(@"NSExtensionItem") != nil;
#else
	return NO;
#endif
}

- (BOOL)isAppExtensionAvailable {
	if ([self isSystemAppExtensionAPIAvailable]) {
		return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"org-appextension-feature-password-management://"]];
	}

	return NO;
}

#pragma mark - Native app Login
- (void)findLoginForURLString:(NSString *)URLString forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *loginDictionary, NSError *error))completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (![self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to findLoginForURLString, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}

#ifdef __IPHONE_8_0
	NSDictionary *item = @{ AppExtensionVersionNumberKey: VERSION_NUMBER, AppExtensionURLStringKey: URLString };

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionFindLoginAction];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to findLoginForURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
			if (completion) {
				completion(loginDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - New User Registration

- (void)storeLoginForURLString:(NSString *)URLString loginDetails:(NSDictionary *)loginDetailsDict passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *, NSError *))completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(loginDetailsDict != nil, @"loginDetailsDict must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (![self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to storeLoginForURLString, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}


#ifdef __IPHONE_8_0
	NSMutableDictionary *newLoginAttributesDict = [NSMutableDictionary new];
	newLoginAttributesDict[AppExtensionVersionNumberKey] = VERSION_NUMBER;
	newLoginAttributesDict[AppExtensionURLStringKey] = URLString;
	[newLoginAttributesDict addEntriesFromDictionary:loginDetailsDict];
	if (passwordGenerationOptions.count > 0) {
		newLoginAttributesDict[AppExtensionPasswordGereratorOptionsKey] = passwordGenerationOptions;
	}

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:newLoginAttributesDict viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionSaveLoginAction];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to storeLoginForURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
			if (completion) {
				completion(loginDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - Change Password

- (void)changePasswordForLoginForURLString:(NSString *)URLString loginDetails:(NSDictionary *)loginDetailsDict passwordGenerationOptions:(NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(NSDictionary *loginDict, NSError *error))completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (![self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to changePasswordForLoginWithUsername, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}

#ifdef __IPHONE_8_0
	NSMutableDictionary *item = [NSMutableDictionary new];
	item[AppExtensionVersionNumberKey] = VERSION_NUMBER;
	item[AppExtensionURLStringKey] = URLString;
	[item addEntriesFromDictionary:loginDetailsDict];
	if (passwordGenerationOptions.count > 0) {
		item[AppExtensionPasswordGereratorOptionsKey] = passwordGenerationOptions;
	}

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionChangePasswordAction];

	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to changePasswordForLoginWithUsername: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
			if (completion) {
				completion(loginDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - Web View Login Support

- (void)fillLoginIntoWebView:(id)webView forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(BOOL success, NSError *error))completion {
	NSAssert(webView != nil, @"webView must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

#ifdef __IPHONE_8_0
	if ([webView isKindOfClass:[UIWebView class]]) {
		[self fillLoginIntoUIWebView:webView webViewController:viewController sender:(id)sender completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
	else if ([webView isKindOfClass:[WKWebView class]]) {
		[self fillLoginIntoWKWebView:webView forViewController:viewController sender:(id)sender completion:^(BOOL success, NSError *error) {
			if (completion) {
				completion(success, error);
			}
		}];
	}
#endif
	else {
		[NSException raise:@"Invalid argument: web view must be an instance of WKWebView or UIWebView." format:@""];
	}
#endif
}

#pragma mark - Browser filling Support

- (BOOL)isOnePasswordExtensionActivityType:(NSString *)activityType {
	return [@"com.agilebits.onepassword-ios.extension" isEqualToString:activityType] || [@"com.agilebits.beta.onepassword-ios.extension" isEqualToString:activityType];
}

- (void)createExtensionItemForWebView:(id)webView completion:(void (^)(NSExtensionItem *extensionItem, NSError *error))completion {
	NSAssert(webView != nil, @"webView must not be nil");

#ifdef __IPHONE_8_0
	if ([webView isKindOfClass:[UIWebView class]]) {
		UIWebView *uiWebView = (UIWebView *)webView;
		NSString *collectedPageDetails = [uiWebView stringByEvaluatingJavaScriptFromString:OPWebViewCollectFieldsScript];

		[self createExtensionItemForURLString:uiWebView.request.URL.absoluteString webPageDetails:collectedPageDetails completion:completion];
	}
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
	else if ([webView isKindOfClass:[WKWebView class]]) {
		WKWebView *wkWebView = (WKWebView *)webView;
		[wkWebView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *evaluateError) {
			if (!result) {
				NSLog(@"1Password Extension failed to collect web page fields: %@", evaluateError);
				NSError *failedToCollectFieldsError = [OnePasswordExtension failedToCollectFieldsErrorWithUnderlyingError:evaluateError];
				if (completion) {
					if ([NSThread isMainThread]) {
						completion(nil, failedToCollectFieldsError);
					}
					else {
						dispatch_async(dispatch_get_main_queue(), ^{
							completion(nil, failedToCollectFieldsError);
						});
					}
				}

				return;
			}

			[self createExtensionItemForURLString:wkWebView.URL.absoluteString webPageDetails:result completion:completion];
		}];
	}
#endif
	else {
		[NSException raise:@"Invalid argument: web view must be an instance of WKWebView or UIWebView." format:@""];
	}
#endif
}

- (void)fillReturnedItems:(NSArray *)returnedItems intoWebView:(id)webView completion:(void (^)(BOOL success, NSError *error))completion {
	if (returnedItems.count == 0) {
		NSError *error = [OnePasswordExtension extensionCancelledByUserError];
		if (completion) {
			completion(NO, error);
		}

		return;
	}

	[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *error) {
		if (!loginDictionary) {
			if (completion) {
				completion(NO, error);
			}

			return;
		}

		NSString *fillScript = loginDictionary[AppExtensionWebViewPageFillScript];
		[self executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *executeFillScriptError) {
			if (completion) {
				completion(success, executeFillScriptError);
			}
		}];
	}];
}

#pragma mark - Private methods

- (void)findLoginIn1PasswordWithURLString:(NSString *)URLString collectedPageDetails:(NSString *)collectedPageDetails forWebViewController:(UIViewController *)forViewController sender:(id)sender withWebView:(id)webView completion:(void (^)(BOOL success, NSError *error))completion {
	if ([URLString length] == 0) {
		NSError *URLStringError = [OnePasswordExtension failedToObtainURLStringFromWebViewError];
		NSLog(@"Failed to findLoginIn1PasswordWithURLString: %@", URLStringError);
		completion(NO, URLStringError);
	}

	NSError *jsonError = nil;
	NSData *data = [collectedPageDetails dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *collectedPageDetailsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];

	if (collectedPageDetailsDictionary.count == 0) {
		NSLog(@"Failed to parse JSON collected page details: %@", jsonError);
		completion(NO, jsonError);
	}

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : collectedPageDetailsDictionary };

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:forViewController sender:sender typeIdentifier:kUTTypeAppExtensionFillWebViewAction];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to findLoginIn1PasswordWithURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(NO, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems[0] completion:^(NSDictionary *loginDictionary, NSError *processExtensionItemError) {
			if (!loginDictionary) {
				if (completion) {
					completion(NO, processExtensionItemError);
				}

				return;
			}

			NSString *fillScript = loginDictionary[AppExtensionWebViewPageFillScript];
			[self executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *executeFillScriptError) {
				if (completion) {
					completion(success, executeFillScriptError);
				}
			}];
		}];
	};

	[forViewController presentViewController:activityViewController animated:YES completion:nil];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
- (void)fillLoginIntoWKWebView:(WKWebView *)webView forViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(BOOL success, NSError *error))completion {
	[webView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *error) {
		if (!result) {
			NSLog(@"1Password Extension failed to collect web page fields: %@", error);
			if (completion) {
				completion(NO,[OnePasswordExtension failedToCollectFieldsErrorWithUnderlyingError:error]);
			}

			return;
		}

		[self findLoginIn1PasswordWithURLString:webView.URL.absoluteString collectedPageDetails:result forWebViewController:viewController sender:sender withWebView:webView completion:^(BOOL success, NSError *findLoginError) {
			if (completion) {
				completion(success, findLoginError);
			}
		}];
	}];
}
#endif

- (void)fillLoginIntoUIWebView:(UIWebView *)webView webViewController:(UIViewController *)viewController sender:(id)sender completion:(void (^)(BOOL success, NSError *error))completion {
	NSString *collectedPageDetails = [webView stringByEvaluatingJavaScriptFromString:OPWebViewCollectFieldsScript];
	[self findLoginIn1PasswordWithURLString:webView.request.URL.absoluteString collectedPageDetails:collectedPageDetails forWebViewController:viewController sender:sender withWebView:webView completion:^(BOOL success, NSError *error) {
		if (completion) {
			completion(success, error);
		}
	}];
}

- (void)executeFillScript:(NSString *)fillScript inWebView:(id)webView completion:(void (^)(BOOL success, NSError *error))completion {
	if (!fillScript) {
		NSLog(@"Failed to executeFillScript, fillScript is missing");
		if (completion) {
			completion(NO, [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedString(@"Failed to fill web page because script is missing", @"1Password Extension Error Message") underlyingError:nil]);
		}

		return;
	}

	NSMutableString *scriptSource = [OPWebViewFillScript mutableCopy];
	[scriptSource appendFormat:@"(document, %@);", fillScript];

	if ([webView isKindOfClass:[UIWebView class]]) {
		NSString *result = [((UIWebView *)webView) stringByEvaluatingJavaScriptFromString:scriptSource];
		BOOL success = (result != nil);
		NSError *error = nil;

		if (!success) {
			NSLog(@"Cannot executeFillScript, stringByEvaluatingJavaScriptFromString failed");
			error = [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedString(@"Failed to fill web page because script could not be evaluated", @"1Password Extension Error Message") underlyingError:nil];
		}

		if (completion) {
			completion(success, error);
		}

		return;
	}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
	if ([webView isKindOfClass:[WKWebView class]]) {
		[((WKWebView *)webView) evaluateJavaScript:scriptSource completionHandler:^(NSString *result, NSError *evaluationError) {
			BOOL success = (result != nil);
			NSError *error = nil;

			if (!success) {
				NSLog(@"Cannot executeFillScript, evaluateJavaScript failed: %@", evaluationError);
				error = [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedString(@"Failed to fill web page because script could not be evaluated", @"1Password Extension Error Message") underlyingError:error];
			}

			if (completion) {
				completion(success, error);
			}
		}];

		return;
	}
#endif

	[NSException raise:@"Invalid argument: web view must be an instance of WKWebView or UIWebView." format:@""];
}

#ifdef __IPHONE_8_0
- (void)processExtensionItem:(NSExtensionItem *)extensionItem completion:(void (^)(NSDictionary *loginDictionary, NSError *error))completion {
	if (extensionItem.attachments.count == 0) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item had no attachments." };
		NSError *error = [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeUnexpectedData userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}

	NSItemProvider *itemProvider = extensionItem.attachments[0];
	if (![itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item attachment does not conform to kUTTypePropertyList type identifier" };
		NSError *error = [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeUnexpectedData userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}


	[itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *loginDictionary, NSError *itemProviderError)
	 {
		 NSError *error = nil;
		 if (!loginDictionary) {
			 NSLog(@"Failed to loadItemForTypeIdentifier: %@", itemProviderError);
			 error = [OnePasswordExtension failedToLoadItemProviderDataErrorWithUnderlyingError:itemProviderError];
		 }

		 if (completion) {
			 if ([NSThread isMainThread]) {
				 completion(loginDictionary, error);
			 }
			 else {
				 dispatch_async(dispatch_get_main_queue(), ^{
					 completion(loginDictionary, error);
				 });
			 }
		 }
	 }];
}

- (UIActivityViewController *)activityViewControllerForItem:(NSDictionary *)item viewController:(UIViewController*)viewController sender:(id)sender typeIdentifier:(NSString *)typeIdentifier {
#ifdef __IPHONE_8_0

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:typeIdentifier];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];

	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		controller.popoverPresentationController.barButtonItem = sender;
	}
	else if ([sender isKindOfClass:[UIView class]]) {
		controller.popoverPresentationController.sourceView = [sender superview];
		controller.popoverPresentationController.sourceRect = [sender frame];
	}
	else {
		NSLog(@"sender can be nil on iPhone");
	}

	return controller;
#else
	return nil;
#endif
}

#endif

- (void)createExtensionItemForURLString:(NSString *)URLString webPageDetails:(NSString *)webPageDetails completion:(void (^)(NSExtensionItem *extensionItem, NSError *error))completion {
	NSError *jsonError = nil;
	NSData *data = [webPageDetails dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *webPageDetailsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];

	if (webPageDetailsDictionary.count == 0) {
		NSLog(@"Failed to parse JSON collected page details: %@", jsonError);
		completion(nil, jsonError);
	}

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : webPageDetailsDictionary };

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeAppExtensionFillBrowserAction];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	if (completion) {
		if ([NSThread isMainThread]) {
			completion(extensionItem, nil);
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(extensionItem, nil);
			});
		}
	}
}

#pragma mark - Errors

+ (NSError *)systemAppExtensionAPINotAvailableError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"App Extension API is not available is this version of iOS", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeAPINotAvailable userInfo:userInfo];
}


+ (NSError *)extensionCancelledByUserError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"1Password Extension was cancelled by the user", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeCancelledByUser userInfo:userInfo];
}

+ (NSError *)failedToContactExtensionErrorWithActivityError:(NSError *)activityError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Failed to contact the 1Password Extension", @"1Password Extension Error Message");
	if (activityError) {
		userInfo[NSUnderlyingErrorKey] = activityError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToContactExtension userInfo:userInfo];
}

+ (NSError *)failedToCollectFieldsErrorWithUnderlyingError:(NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Failed to execute script that collects web page information", @"1Password Extension Error Message");
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeCollectFieldsScriptFailed userInfo:userInfo];
}

+ (NSError *)failedToFillFieldsErrorWithLocalizedErrorMessage:(NSString *)errorMessage underlyingError:(NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (errorMessage) {
		userInfo[NSLocalizedDescriptionKey] = errorMessage;
	}
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFillFieldsScriptFailed userInfo:userInfo];
}

+ (NSError *)failedToLoadItemProviderDataErrorWithUnderlyingError:(NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Failed to parse information returned by 1Password Extension", @"1Password Extension Error Message");
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToLoadItemProviderData userInfo:userInfo];
}

+ (NSError *)failedToObtainURLStringFromWebViewError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to obtain URL String from web view. The web view must be loaded completely when calling the 1Password Extension", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToObtainURLStringFromWebView userInfo:userInfo];
}

#pragma mark - WebView field collection and filling scripts

static NSString *const OPWebViewCollectFieldsScript = @"document.collect=n;document.elementsByOPID={};\
function n(d,e){function f(a,c){var b=a[c];return'string'==typeof b||'function'==typeof a.getAttribute&&(b=a.getAttribute(c),'string'==typeof b)?b:null}function g(a){var c,b;if(!a)return'';if(a._idCache)return a._idCache;if('BODY'==a.tagName)return a.tagName;c=a.parentNode;if(!c)return'';b=c.childNodes;for(c=0;c<=b.length;c++)if(b[c]==a)return c=g(a.parentNode)+'/'+a.tagName+'['+c+']',a._idCache=c;return''}function p(a){return a.options?(a=Array.prototype.slice.call(a.options).map(function(a){var b=a.text,\
b=b?k(b).replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,''):null;return[b?b:null,a.value]}),{options:a}):null}function r(a){var c;for(a=a.parentElement||a.parentNode;a&&'td'!=k(a.tagName);)a=a.parentElement||a.parentNode;if(!a||void 0===a)return null;c=a.parentElement||a.parentNode;if('tr'!=c.tagName.toLowerCase())return null;c=c.previousElementSibling;if(!c||'tr'!=(c.tagName+'').toLowerCase()||c.cells&&a.cellIndex>=c.cells.length)return null;a=c.cells[a.cellIndex];return a.innerText||\
a.textContent}function v(a){var c=d.documentElement,b=a.getBoundingClientRect(),f=c.getBoundingClientRect(),e=b.left-c.clientLeft,c=b.top-c.clientTop;return a.offsetParent?0>e||e>f.width||0>c||c>f.height?s(a):(f=a.ownerDocument.elementFromPoint(e+3,c+3))?'label'===k(f.tagName)?f===w(a):f.tagName===a.tagName:!1:!1}function s(a){for(var c;a!==d&&a;a=a.parentNode)if(c=t.getComputedStyle?t.getComputedStyle(a,null):a.style,'none'===c.display||'hidden'==c.visibility)return!1;return a===d}function w(a){function c(a){return String.prototype.replace.call(a,\
\"'\",\"\\\\'\")}var b;if(c(a.id)&&(b=d.querySelector(\"label[for='\"+c(a.id)+\"']\"))||c(a.name)&&(b=d.querySelector(\"label[for='\"+c(a.name)+\"']\")))return b.innerText;for(;a&&a!=d;a=a.parentNode)if('label'===k(a.tagName))return a.innerText;return null}function h(a,c,b){null!==b&&void 0!==b&&(a[c]=b)}function k(a){return'string'===typeof a?a.toLowerCase():(''+a).toLowerCase()}var t=d.defaultView?d.defaultView:window,l=RegExp('(pin|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)',\
'i'),B=Array.prototype.slice.call(d.querySelectorAll('form')).map(function(a,c){var b={},d='__form__'+c;a.opid=d;b.opid=d;h(b,'htmlName',f(a,'name'));h(b,'htmlID',f(a,'id'));h(b,'htmlAction',q(f(a,'action')));h(b,'htmlMethod',f(a,'method'));return b}),y=Array.prototype.slice.call(d.querySelectorAll('input, select')).map(function(a,c){var b={},e='__'+c;d.elementsByOPID[e]=a;a.opid=e;b.opid=e;b.elementNumber=c;b.maxLength=-1==a.maxLength?999:a.maxLength;b.visible=s(a);b.viewable=v(a);b.parentId=g(a.parentNode);\
h(b,'htmlID',f(a,'id'));h(b,'htmlName',f(a,'name'));h(b,'htmlClass',f(a,'class'));if('hidden'!=k(a.type)){h(b,'label-tag',w(a));h(b,'label-data',f(a,'data-label'));h(b,'label-aria',f(a,'aria-label'));h(b,'label-top',r(a));for(var e=[],m=a;m&&m.nextSibling;){m=m.nextSibling;if(u(m))break;x(e,m)}h(b,'label-right',e.join(''));e=[];z(a,e);e=e.reverse().join('');h(b,'label-left',e);h(b,'placeholder',f(a,'placeholder'))}h(b,'rel',f(a,'rel'));h(b,'type',k(f(a,'type')));a:switch(k(a.type)){case 'checkbox':e=\
a.checked?'✓':'';break a;default:e=a.value}h(b,'value',e);h(b,'checked',a.checked);h(b,'autoCompleteType',a.getAttribute('x-autocompletetype')||a.getAttribute('autocompletetype')||a.getAttribute('autocomplete'));h(b,'selectInfo',p(a));h(b,'aria-hidden','true'==a.getAttribute('aria-hidden'));h(b,'aria-disabled','true'==a.getAttribute('aria-disabled'));h(b,'aria-haspopup','true'==a.getAttribute('aria-haspopup'));a.form&&(b.form=a.form.opid);e=(l.test(b.value)||l.test(b.htmlID)||l.test(b.htmlName)||\
l.test(b.placeholder)||l.test(b['label-tag'])||l.test(b['label-data'])||l.test(b['label-aria']))&&('text'==b.type||'password'==b.type&&!b.visible);b.fakeTested=e;return b});y.filter(function(a){return a.fakeTested}).forEach(function(a){var c=d.elementsByOPID[a.opid];c.getBoundingClientRect();!c||c&&'function'!==typeof c.click||c.click();c.focus();A(c,'keydown');A(c,'keyup');A(c,'keypress');c.click&&c.click();a.postFakeTestVisible=s(c);a.postFakeTestViewable=v(c);a=c.ownerDocument.createEvent('HTMLEvents');\
var b=c.ownerDocument.createEvent('HTMLEvents');A(c,'keydown');A(c,'keyup');A(c,'keypress');b.initEvent('input',!0,!0);c.dispatchEvent(b);a.initEvent('change',!0,!0);c.dispatchEvent(a);c.blur()});return{documentUUID:e,title:d.title,url:t.location.href,forms:function(a){var c={};a.forEach(function(a){c[a.opid]=a});return c}(B),fields:y,collectedTimestamp:(new Date).getTime()}};document.elementForOPID=C;function A(d,e){var f;f=d.ownerDocument.createEvent('KeyboardEvent');f.initKeyboardEvent?f.initKeyboardEvent(e,!0,!0):f.initKeyEvent&&f.initKeyEvent(e,!0,!0,null,!1,!1,!1,!1,0,0);d.dispatchEvent(f)}function x(d,e){var f;f='';3===e.nodeType?f=e.nodeValue:1===e.nodeType&&(f=e.innerText||e.textContent);var g=null;f&&(g=f.trim(),g=0<g.length?g:null);(f=g)&&d.push(f)}\
function u(d){var e;d&&void 0!==d?(e='select option input form textarea iframe button body head'.split(' '),d?(d=d?(d.tagName||'').toLowerCase():'',e=e.constructor==Array?0<=e.indexOf(d):d===e):e=!1):e=!0;return e}function z(d,e,f){var g;for(f||(f=0);d&&d.previousSibling;){d=d.previousSibling;if(u(d))return;x(e,d)}if(d&&0===e.length){for(g=null;!g;){d=d.parentElement||d.parentNode;if(!d)return;for(g=d.previousSibling;g&&!u(g)&&g.lastChild;)g=g.lastChild}u(g)||(x(e,g),0===e.length&&z(g,e,f+1))}}\
function C(d){var e;if(void 0===d||null===d)return null;try{var f=Array.prototype.slice.call(document.querySelectorAll('input, select')),g=f.filter(function(e){return e.opid==d});if(0<g.length)e=g[0],1<g.length&&console.warn('More than one element found with opid '+d);else{var p=parseInt(d.split('__')[1],10);isNaN(p)||(e=f[p])}}catch(r){console.error('An unexpected error occurred: '+r)}finally{return e}};var D=/^[\\/\\?]/;function q(d){if(!d)return null;if(0==d.indexOf('http'))return d;var e=window.location.protocol+'//'+window.location.hostname;window.location.port&&''!=window.location.port&&(e+=':'+window.location.port);d.match(D)||(d='/'+d);return e+d};\
(function collect(uuid) { var pageDetails = document.collect(document, uuid); return JSON.stringify(pageDetails); })('uuid');";

static NSString *const OPWebViewFillScript = @"var f=!0,h=!0;document.fill=k;\
function k(a){var b,c=[],d=a.properties,e=1,g;d&&d.delay_between_operations&&(e=d.delay_between_operations);if(null!=a.savedURL&&0===a.savedURL.indexOf('https://')&&'http:'==document.location.protocol&&(b=confirm('1Password warning: This is an unsecured HTTP page, and any information you submit can potentially be seen and changed by others. This Login was originally saved on a secure (HTTPS) page.\\n\\nDo you still wish to fill this login?'),0==b))return;g=function(a,b){var d=a[0];void 0===d?b():('delay'===\
d.operation?e=d.parameters[0]:c.push(l(d)),setTimeout(function(){g(a.slice(1),b)},e))};if(b=a.options)h=b.animate,f=b.markFilling;a.hasOwnProperty('script')&&(b=a.script,g(b,function(){c=Array.prototype.concat.apply(c,void 0);a.hasOwnProperty('autosubmit')&&'function'==typeof autosubmit&&setTimeout(function(){autosubmit(a.autosubmit,d.allow_clicky_autosubmit)},AUTOSUBMIT_DELAY);'object'==typeof protectedGlobalPage&&protectedGlobalPage.a('fillItemResults',{documentUUID:documentUUID,fillContextIdentifier:a.fillContextIdentifier,\
usedOpids:c},function(){})}))}var u={fill_by_opid:m,fill_by_query:n,click_on_opid:p,click_on_query:q,touch_all_fields:r,simple_set_value_by_query:s,focus_by_opid:t,delay:null};function l(a){var b;if(a.hasOwnProperty('operation')&&a.hasOwnProperty('parameters'))b=a.operation,a=a.parameters;else if('[object Array]'===Object.prototype.toString.call(a))b=a[0],a=a.splice(1);else return null;return u.hasOwnProperty(b)?u[b].apply(this,a):null}function m(a,b){var c;return(c=v(a))?(w(c,b),c.opid):null}\
function n(a,b){var c;c=document.querySelectorAll(a);return Array.prototype.map.call(c,function(a){w(a,b);return a.opid},this)}function s(a,b){var c,d=[];c=document.querySelectorAll(a);Array.prototype.forEach.call(c,function(a){void 0!==a.value&&(a.value=b,d.push(a.opid))});return d}function t(a){if(a=v(a))'function'===typeof a.click&&a.click(),'function'===typeof a.focus&&a.focus();return null}function p(a){return(a=v(a))?x(a)?a.opid:null:null}\
function q(a){a=document.querySelectorAll(a);return Array.prototype.map.call(a,function(a){x(a);'function'===typeof a.click&&a.click();'function'===typeof a.focus&&a.focus();return a.opid},this)}function r(){y()};var z={'true':!0,y:!0,1:!0,yes:!0,'✓':!0},A=200;function w(a,b){var c;if(a&&null!==b&&void 0!==b)switch(f&&a.form&&!a.form.opfilled&&(a.form.opfilled=!0),a.type?a.type.toLowerCase():null){case 'checkbox':c=b&&1<=b.length&&z.hasOwnProperty(b.toLowerCase())&&!0===z[b.toLowerCase()];a.checked===c||B(a,function(a){a.checked=c});break;case 'radio':!0===z[b.toLowerCase()]&&a.click();break;default:a.value==b||B(a,function(a){a.value=b})}}\
function B(a,b){C(a);b(a);D(a);E(a)&&(a.className+=' com-agilebits-onepassword-extension-animated-fill',setTimeout(function(){a&&a.className&&(a.className=a.className.replace(/(\\s)?com-agilebits-onepassword-extension-animated-fill/,''))},A))};document.elementForOPID=v;function F(a,b){var c;c=a.ownerDocument.createEvent('KeyboardEvent');c.initKeyboardEvent?c.initKeyboardEvent(b,!0,!0):c.initKeyEvent&&c.initKeyEvent(b,!0,!0,null,!1,!1,!1,!1,0,0);a.dispatchEvent(c)}function C(a){x(a);a.focus();F(a,'keydown');F(a,'keyup');F(a,'keypress')}\
function D(a){var b=a.ownerDocument.createEvent('HTMLEvents'),c=a.ownerDocument.createEvent('HTMLEvents');F(a,'keydown');F(a,'keyup');F(a,'keypress');c.initEvent('input',!0,!0);a.dispatchEvent(c);b.initEvent('change',!0,!0);a.dispatchEvent(b);a.blur()}function x(a){if(!a||a&&'function'!==typeof a.click)return!1;a.click();return!0}\
function G(){var a=RegExp('(pin|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)','i');return Array.prototype.slice.call(document.querySelectorAll(\"input[type='text']\")).filter(function(b){return b.value&&a.test(b.value)},this)}function y(){G().forEach(function(a){C(a);a.click&&a.click();D(a)})}\
function E(a){var b;if(b=h)a:{b=a;for(var c=a.ownerDocument,c=c?c.defaultView:{},d;b&&b!==document;){d=c.getComputedStyle?c.getComputedStyle(b,null):b.style;if('none'===d.display||'hidden'==d.visibility){b=!1;break a}b=b.parentNode}b=b===document}return b?-1!=='email text password number tel url'.split(' ').indexOf(a.type||''):!1}\
function v(a){var b;if(void 0===a||null===a)return null;try{var c=Array.prototype.slice.call(document.querySelectorAll('input, select')),d=c.filter(function(b){return b.opid==a});if(0<d.length)b=d[0],1<d.length&&console.warn('More than one element found with opid '+a);else{var e=parseInt(a.split('__')[1],10);isNaN(e)||(b=c[e])}}catch(g){console.error('An unexpected error occurred: '+g)}finally{return b}};\
(function(ownerDocument, script){ownerDocument.fill(script); return {'success': true}; })";

@end
