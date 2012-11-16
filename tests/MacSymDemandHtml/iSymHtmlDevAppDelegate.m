//
//  iSymHtmlDevAppDelegate.m
//  iSymHtmlDev
//
//  Created by Dillon on 4/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "iSymHtmlDevAppDelegate.h"
#import "SYMHtmlController.h"
#import "iSym.h"

@implementation iSymHtmlDevAppDelegate

@synthesize window;
@synthesize webView;
@synthesize symHtml;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  //hard-coded; change these:
  SYMSession *reference = [SYMSession sessionForServer: @"127.0.0.1"
                                               aixUser: @"username"
                                               aixPass: @"password"
                                               symUser: @"symid"
                                           institution: 1];
  
  //root URL to allow intranet resource access
  NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithCapacity:0];
  [options setObject:@"http://www.your.intranet/" forKey:@"SYMHtmlController.RootURL"];

  //on-demand html repgen name, and account to run on
  symHtml = [SYMHtmlController NewControllerForView:webView usingConfig:options cloneSession:reference];
  [symHtml demandSpecfile:@"WIZ.ELECTRONIC.SERVICES" forMember:@"0000001000"];
}

@end
