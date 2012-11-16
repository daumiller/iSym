//
//  SYMHtmlController.m
//  iSymHtmlDev
//
//  Created by Dillon on 4/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "iSym.h"
#import "SYMHtmlController.h"
static BOOL _SYMHtmlController_registered = NO;

//==================================================================================================================================
@implementation SYMHtmlController
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError) login
{
  return [session login];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//TODO: maybe offer a version of this allowing a dictionary of input parameters
//that are passed in in a program-generated <HEAD> section, 
- (SYMError) demandSpecfile:(NSString *)filename forMember:(NSString *)account
{
  if(specfile != nil) { [specfile release]; specfile = nil; }
  if(member   != nil) { [member release];   member   = nil; }
  if(!session.connected || !session.loggedIn) return SYMError_NotConnected;

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  
  SYMError err = [session AccountManager_LoadAccount:account];
  if(err != SYMError_None) { [pool drain]; return err; }
  
  //TODO: check for specfile existance here
  specfile = [filename copy];
  member   = [account copy];
  NSString *html = [session AccountManager_DemandHtml_Begin:filename];
  NSString *base = (NSString *)[config objectForKey:@"SYMHtmlController.RootURL"];
  [[view mainFrame] loadHTMLString:html baseURL:[NSURL URLWithString:base]];
  [pool drain];
  return SYMError_None;
}
//----------------------------------------------------------------------------------------------------------------------------------
+ HtmlControllerForView:(WebView *)webview usingConfig:(NSDictionary *)configuration cloneSession:(SYMSession *)clone
{
  return [[[SYMHtmlController alloc] initForWebView:webview usingConfig:configuration cloneSession:clone] autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
+ NewControllerForView:(WebView *)webview usingConfig:(NSDictionary *)configuration cloneSession:(SYMSession *)clone
{
  return [[SYMHtmlController alloc] initForWebView:webview usingConfig:configuration cloneSession:clone];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) commonInit
{
  if(!_SYMHtmlController_registered)
  {
    _SYMHtmlController_registered = YES;
    [WebView registerURLSchemeAsLocal:@"symitar://"];
  }
  [view setPolicyDelegate:self];
  [session login];
  NSString *initURL = [config objectForKey:@"SYMHtmlController.InitURL"];
  if(initURL != nil) [[view mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:initURL]]];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- initForWebView:(WebView *)webview usingConfig:(NSDictionary *)configuration cloneSession:(SYMSession *)clone
{
  self = [super init];
  if(self)
  {
    config  = configuration;
    session = [clone copy];
    view    = webview;
    [self commonInit];
  }
  return self;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) dealloc
{
  if(specfile != nil) [specfile release];
  if(member   != nil) [member release];
  if(session.loggedIn || session.connected) [session disconnect];
  [session release];
  [super dealloc];
}
//----------------------------------------------------------------------------------------------------------------------------------
- (BOOL) receiveFocus : (id <SYMToolTab>) from
{
  return YES;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (BOOL) loseFocus    : (id <SYMToolTab>) to
{
  return YES;
}
//----------------------------------------------------------------------------------------------------------------------------------
-                   (void)webView: (WebView *)      webView
  decidePolicyForNavigationAction: (NSDictionary *) actionInformation
                          request: (NSURLRequest *) request
                            frame: (WebFrame *)     frame
                 decisionListener: (id <WebPolicyDecisionListener>) listener
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
 
  NSString *base = (NSString *)[config objectForKey:@"SYMHtmlController.RootURL"];
  NSString *path = [[request URL] absoluteString]; 
  if([path isEqualToString:@"symitar://HTMLView~Action=Post"])
  {
    NSDictionary *post = [self getRequestPostDictionary:request];
    [session AccountManager_DemandHtml_Complete:post];
    [[view mainFrame] loadHTMLString:@"<HTML><BODY>completed</BODY></HTML>" baseURL:[NSURL URLWithString:base]]; //TODO: change this (maybe to "about:blank"?)
  }
  else if([path isEqualToString:@"symitar://HTMLView~Action=Command"])
  {
    //first, get our post data and complete the request
    NSDictionary *post = [self getRequestPostDictionary:request];
    [session AccountManager_DemandHtml_Complete:post];
    
    //then check for global parameters
    NSString *setMember = [post objectForKey:@"member"];
    if(setMember != nil)
    {
      if(member != nil) [member release];
      member = [setMember copy];
    }
    
    //then specific commands
    NSString *command = [post objectForKey:@"command"];
    if([command compare:@"forward"] == NSOrderedSame)
    {
      
      NSString *setSpecfile = [post objectForKey:@"specfile"];
      if(setSpecfile != nil)
      {
        if(specfile != nil) [specfile release];
        [self demandSpecfile:setSpecfile forMember:member];
      }
    }
    //default
    else
      [[view mainFrame] loadHTMLString:@"<HTML><BODY>//not yet implemented</BODY></HTML>" baseURL:[NSURL URLWithString:base]];
  }
  else if([path isEqualToString:@"symitar://HTMLView~Action=Ajax"])
  {
    NSDictionary *post = [self getRequestPostDictionary:request];
    [session AccountManager_DemandHtml_Complete:post];
    [[view mainFrame] loadHTMLString:@"<HTML><BODY>//not yet implemeneted</BODY></HTML>" baseURL:[NSURL URLWithString:base]];
  }
  else //TODO: Here: maybe a configuration option to disallow non-handled requests?
    [listener use];
  
  [pool drain];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSDictionary *) getRequestPostDictionary:(NSURLRequest *)request
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
  NSArray *parms = [body componentsSeparatedByString:@"&"];
  [body release];
  
  NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithCapacity:0];
  NSString *key, *val;
  for(NSString *curr in parms)
  {
    NSRange eqPos = [curr rangeOfString:@"="];
    if(eqPos.location == NSNotFound)
      [post setObject:@"" forKey:[[curr stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    else
    {
      key = [curr substringToIndex:eqPos.location];
      val = [curr substringFromIndex:eqPos.location+1];
      [post setObject:[[val stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
               forKey:[[key stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }    
  }
  
  [pool drain];
  return [post autorelease];
}
//----------------------------------------------------------------------------------------------------------------------------------
@end
//==================================================================================================================================
