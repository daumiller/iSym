//
//  SYMHtmlController.h
//  iSymHtmlDev
//
//  Created by Dillon on 4/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "SYMError.h";
@class SYMSession;

@protocol SYMToolTab
- (BOOL) receiveFocus : (id <SYMToolTab>) from;
- (BOOL) loseFocus    : (id <SYMToolTab>) to;
@end

//we'll eventually need some sort of protocol,
//and a reference within our SYMHtmlController to our owner,
//for a SYMHtml <-> Voyage delegate/protocol
//to allow certain HTML actions to propagate all the way up
//to the application level (and possibly be redistributed out to another SYMToolTab)
//--these calls will get a [copy|reference]? from our getRequestPostDictionary input
//--and possibly some functionality to allow it to output through the same (our) connection?

@interface SYMHtmlController : NSObject <SYMToolTab>
{
  NSDictionary *config;
  SYMSession   *session;
  WebView      *view;
  NSString     *specfile;
  NSString     *member;
}

+ HtmlControllerForView:(WebView *)webview usingConfig:(NSDictionary *)configuration cloneSession:(SYMSession *)clone;
+ NewControllerForView:(WebView *)webview usingConfig:(NSDictionary *)configuration cloneSession:(SYMSession *)clone;
- initForWebView:(WebView *)webview usingConfig:(NSDictionary *)configuration cloneSession:(SYMSession *)clone;

- (SYMError) login;
- (SYMError) demandSpecfile:(NSString *)filename forMember:(NSString *)member;

- (BOOL) receiveFocus : (id <SYMToolTab>) from;
- (BOOL) loseFocus    : (id <SYMToolTab>) to;

-                   (void)webView: (WebView *)      webView
  decidePolicyForNavigationAction: (NSDictionary *) actionInformation
                          request: (NSURLRequest *) request
                            frame: (WebFrame *)     frame
                 decisionListener: (id <WebPolicyDecisionListener>) listener;

- (NSDictionary *) getRequestPostDictionary:(NSURLRequest *)request;

@end
