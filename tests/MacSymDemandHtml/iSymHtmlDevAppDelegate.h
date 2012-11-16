//
//  iSymHtmlDevAppDelegate.h
//  iSymHtmlDev
//
//  Created by Dillon on 4/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WebView;
@class SYMHtmlController;

@interface iSymHtmlDevAppDelegate : NSObject <NSApplicationDelegate>
{
  NSWindow *window;
  WebView  *webView;
  SYMHtmlController *symHtml;
}

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet WebView  *webView;
@property (nonatomic, retain) IBOutlet SYMHtmlController *symHtml;

@end
