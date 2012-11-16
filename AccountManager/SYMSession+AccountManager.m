//==================================================================================================================================
//  SYMSession+AccountManager.m
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import "SYMSession+AccountManager.h"

@implementation SYMSession (AccountManager)
//==================================================================================================================================
- (SYMError) AccountManager_loadAccount:(NSString *)account
{
  if(account == nil)         return SYMError_InvalidParameter;
  if([account length] != 10) return SYMError_InvalidParameter;
  if(![self lock])           return SYMError_InUse;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SYMCommand *cmd;
  
  static uint8 bAcctMgr[3] = {(uint8)'m', (uint8)'1', 0x1B};
  [self writeBytes:bAcctMgr fromOffset:0 ofLength:3];
  cmd = [self readCommand];
  
  while((cmd != nil) && ([cmd.command localizedCaseInsensitiveCompare:@"Input"] != NSOrderedSame))
    cmd = [self readCommand];
  if(cmd == nil)
  {
    [pool drain];
    [self unlock];
    return SYMError_Protocol;
  }
  
  [self writeString:[NSString stringWithFormat:@"%@\r",account]];
  cmd = [self readCommand];
  
  while((cmd != nil) && ([cmd.command localizedCaseInsensitiveCompare:@"Input"] != NSOrderedSame))
    cmd = [self readCommand];
  if(cmd == nil)
  { [pool drain]; return SYMError_Protocol; }
  if(![cmd hasParam:@"HelpCode"])
  { [pool drain]; return SYMError_Protocol; }
  if([[cmd getParam:@"HelpCode"] localizedCaseInsensitiveCompare:@"11201"] != NSOrderedSame)
  { [pool drain]; return SYMError_Protocol; }
  
  [pool drain];
  [self unlock];
  return SYMError_None;
}
//==================================================================================================================================
- (NSString *) AccountManager_demandHtmlBegin:(NSString *)specfile
{
  if(![self lock]) return nil;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SYMCommand *cmd;
  
  [self writeString:[NSString stringWithFormat:@"%@\r",specfile]];
  cmd = [self readCommand];
  NSMutableString *html = [NSMutableString stringWithCapacity:0];
  [html appendString:@"<HTML>"];
  
  BOOL done = NO;
  while((cmd != nil) && (!done))
  {
    if([cmd.command localizedCaseInsensitiveCompare:@"HTMLView"] == NSOrderedSame)
      if([cmd hasParam:@"Action"])
        if([cmd getParam:@"Action"] != nil)
          if([cmd getParam:@"Action"].length > 0)
            if([[cmd getParam:@"Action"] localizedCaseInsensitiveCompare:@"Line"] == NSOrderedSame)
              [html appendString:[cmd getFileData]];
    
    cmd = [self readCommand];
    
    if([cmd.command localizedCaseInsensitiveCompare:@"HTMLView"] == NSOrderedSame)
      if([cmd hasParam:@"Action"])
        if([cmd getParam:@"Action"] != nil)
          if([cmd getParam:@"Action"].length > 0)
            if([[cmd getParam:@"Action"] localizedCaseInsensitiveCompare:@"Display"] == NSOrderedSame)
              done = YES;
  }
  if(cmd == nil) { [pool drain]; [self unlock]; return nil; }
  
  [html appendString:@"</HTML>"];
  NSString *result = [html copy];
  [pool drain];
  [self unlock];
  return [result autorelease];
}
//==================================================================================================================================
- (SYMError) AccountManager_demandHtmlComplete:(NSDictionary *)values
{
  if(![self lock]) return SYMError_InUse;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SYMCommand *cmd;
  
  if(values != nil)
  {
    NSArray *keys = [values allKeys];
    for(NSString *key in keys)
    {
      NSString *value = [values objectForKey:key];
      [self writeString:[NSString stringWithFormat:@"%@=%@\r",key,value]];
    }
  }
  
  [self writeString:@"\r"];    cmd = [self readCommand];
  [self writeString:@"EOD\r"]; cmd = [self readCommand];
  
  while((cmd != nil) && ([cmd.command localizedCaseInsensitiveCompare:@"Input"] != NSOrderedSame))
    cmd = [self readCommand];
  if(cmd == nil)
  { [pool drain]; return SYMError_Protocol; }
  if(![cmd hasParam:@"HelpCode"])
  { [pool drain]; return SYMError_Protocol; }
  if([[cmd getParam:@"HelpCode"] localizedCaseInsensitiveCompare:@"11201"] != NSOrderedSame)
  { [pool drain]; return SYMError_Protocol; }
  
  [pool drain];
  [self unlock];
  return SYMError_None;
}
//==================================================================================================================================
@end
