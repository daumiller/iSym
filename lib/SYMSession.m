//==================================================================================================================================
//  SYMSession.m
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import "FastSocket.h"
#import "SYMCommand.h"
#import "SYMSession.h"
//==================================================================================================================================
@implementation SYMSession
//==================================================================================================================================
//  PROPERTIES
//==================================================================================================================================
@synthesize connected;
@synthesize loggedIn;
@synthesize server;
@synthesize institution;
@synthesize aixUser;
@synthesize aixPass;
@synthesize symUser;
@synthesize lastActive;
@synthesize keepAliveSeconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (int) timeout { return timeout; }
- (void) setTimeout:(int)inTimeout
{
  timeout = inTimeout;
  if(socket) [socket setTimeout:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (BOOL) keepAlive { return keepAlive; }
- (void) setKeepAlive:(BOOL)inKeepAlive
{
  if(connected && loggedIn)
  {
    if( keepAlive && !inKeepAlive) [self keepAliveStop];
    if(!keepAlive &&  inKeepAlive) [self keepAliveStart];
  }
  keepAlive = inKeepAlive;
}
//==================================================================================================================================
//  CONSTRUCTORS
//==================================================================================================================================
+ sessionForServer:(NSString *) Server
           aixUser:(NSString *) AixUser
           aixPass:(NSString *) AixPass
           symUser:(NSString *) SymUser
       institution:(int)        Institution
{
  return [[[SYMSession alloc] initForServer: Server
                                       port: 23
                                    aixUser: AixUser
                                    aixPass: AixPass
                                     prompt: @"$ "
                                    symUser: SymUser
                                institution: Institution] autorelease];;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
+ sessionForServer:(NSString *) Server
              port:(int)        Port
           aixUser:(NSString *) AixUser
           aixPass:(NSString *) AixPass
            prompt:(NSString *) Prompt
           symUser:(NSString *) SymUser
       institution:(int)        Institution
{
  return [[[SYMSession alloc] initForServer: Server
                                       port: Port
                                    aixUser: AixUser
                                    aixPass: AixPass
                                     prompt: Prompt
                                    symUser: SymUser
                                institution: Institution] autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- initForServer:(NSString *) Server
           port:(int)        Port
        aixUser:(NSString *) AixUser
        aixPass:(NSString *) AixPass
         prompt:(NSString *) Prompt
        symUser:(NSString *) SymUser
    institution:(int)        Institution
{
  self = [super init];
  socket           = nil;
  lock             = [[NSLock alloc] init];
  server           = [Server copy];
  port             = Port;
  prompt           = [Prompt copy];
  institution      = Institution;
  aixUser          = [AixUser copy];
  aixPass          = [AixPass copy];
  symUser          = [SymUser copy];
  lastActive       = [[NSDate alloc] init];
  keepAlive        = YES;
  keepAliveThread  = nil;
  keepAliveSeconds = 60;
  timeout          = 30000;
  connected        = NO;
  loggedIn         = NO;
  return self;
}
//==================================================================================================================================
//  DESTRUCTOR
//==================================================================================================================================
- (void) dealloc
{
  if(keepAlive)            { [self keepAliveStop]; keepAlive = NO; }
  if(loggedIn || loggedIn) { [self disconnect];    [socket close]; }
  
  [socket          release];
  [lock            release];
  [server          release];
  [prompt          release];
  [aixUser         release];
  [aixPass         release];
  [symUser         release];
  [lastActive      release];
  [keepAliveThread release];
  
  [super dealloc];
}
//==================================================================================================================================
//  PUBLIC
//==================================================================================================================================
- (NSString *)toString
{
  return [NSString stringWithFormat:@"%@@%@:%d", symUser, server, institution];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (BOOL) equalTo:(SYMSession *)other
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *a = [self  toString];
  NSString *b = [other toString];
  BOOL result = ([a localizedCaseInsensitiveCompare:b] == NSOrderedSame);
  
  [pool drain];
  return result;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMSession *)copyWithZone:(NSZone *)zone
{
  return [[SYMSession allocWithZone:zone] initForServer: server
                                                   port: port
                                                aixUser: aixUser
                                                aixPass: aixPass
                                                 prompt: prompt
                                                symUser: symUser
                                            institution: institution];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMSession *)copyAndLogin:(BOOL)login
{
  SYMSession *copy = [self copy];
  if(login) [copy login];
  return copy;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError) connect
{
  if(![self lock]) return SYMError_InUse;
  
  if(loggedIn || connected) [self disconnect];
  if(socket != nil) [socket release];
  socket = [[FastSocket alloc] initWithHost:server andPort:[NSString stringWithFormat:@"%d",port]];
  [socket setTimeout:timeout];
  
  connected = NO;
  if(![socket connect])
  {
    [self unlock];
    return SYMError_CantConnect;
  }
  else
    connected = YES;
  
  [self unlock];
  [self update];
  return SYMError_None;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMError) disconnect
{
  //we'll attempt to lock (for 1 second), but continue anyway (to force disconnects)
  BOOL didLock = [self lockWait:1000];
  
  if(connected && loggedIn)
  {
    //attempt to exit symitar cleanly
    unsigned char logout[2] = {(unsigned char)'l', 0x1B};
    [self writeBytes:logout fromOffset:0 ofLength:2];
    loggedIn = NO;
  }
  
  if(keepAlive) [self keepAliveStop];
  if(![socket close]) { if(didLock) [self unlock]; return SYMError_CantClose; }
  
  if(didLock) [self unlock];
  connected = loggedIn = NO;
  return SYMError_None;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMError) login
{
  SYMError err;
  
  if(!connected)
  {
    err = [self connect];
    if(err != SYMError_None) return err;
  }
  
  err = [self loginAix]; if(err != SYMError_None) return err;
  err = [self loginSym]; if(err != SYMError_None) return err;
  
  [self update];
  [self keepAliveStop]; //make sure we're not already running...
  if(keepAlive) [self keepAliveStart];
  
  return SYMError_None;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMError) loginAix
{
  if(!connected)   return SYMError_NotConnected;
  if(![self lock]) return SYMError_InUse;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  unsigned char telnet0[ 3] = {0xFF, 0xFB, 0x18};
  unsigned char telnet1[13] = {0xFF, 0xFA, 0x18, 0x00, 0x61, 0x69, 0x78, 0x74, 0x65, 0x72, 0x6D, 0xFF, 0xF0};
  unsigned char telnet2[ 3] = {0xFF, 0xFD, 0x01};
  unsigned char telnet3[ 9] = {0xFF, 0xFD, 0x03, 0xFF, 0xFC, 0x1F, 0xFF, 0xFC, 0x01};
  
  [self writeBytes:telnet0 fromOffset:0 ofLength: 3];
  [self writeBytes:telnet1 fromOffset:0 ofLength:13];
  [self writeBytes:telnet2 fromOffset:0 ofLength: 3];
  [self writeBytes:telnet3 fromOffset:0 ofLength: 9];
  [self writeString:[NSString stringWithFormat:@"%@\r",aixUser]];
  NSString *stat = [self expectStrings:[NSArray arrayWithObjects:@"Password:",@"[c",nil]];
  if(stat == nil) { [pool drain]; [self unlock]; return SYMError_ReceiveError; }
  
  if([stat rangeOfString:@"[c"].location == NSNotFound)
  {
    [self writeString:[NSString stringWithFormat:@"%@\r",aixPass]];
    stat = [self expectString:@"login"];
    if(stat == nil)
      { [pool drain]; [self unlock]; return SYMError_BadAixLogin; }
    if([stat rangeOfString:@"invalid login"].location != NSNotFound)
      { [pool drain]; [self unlock]; return SYMError_BadAixLogin; }
  }
  
  [pool drain];
  [self unlock];
  [self update];
  return SYMError_None;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMError) loginSym
{
  if(!connected)   return SYMError_NotConnected;
  if(![self lock]) return SYMError_InUse;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *stat = [self expectStrings:[NSArray arrayWithObjects:prompt,@">",@"SymStart~Global",nil]];
  if(stat == nil) { [pool drain]; [self unlock]; return SYMError_ReceiveError; }
  
  if([stat rangeOfString:@"[c"].location != NSNotFound)
    [self writeString:@"WINDOWSLEVEL=3\n"];
  if(([stat rangeOfString:prompt].location != NSNotFound) || ([stat rangeOfString:@">"].location != NSNotFound))
    [self writeString:@"export WINDOWSLEVEL=3\n"];
  
  if([stat rangeOfString:@"SymStart~Global"].location == NSNotFound)
  {
    stat = [self expectStrings:[NSArray arrayWithObjects:prompt,@">",@"SymStart~Global",nil]];
    if(([stat rangeOfString:prompt].location != NSNotFound) || ([stat rangeOfString:@">"].location != NSNotFound))
      [self writeString:@"export WINDOWSLEVEL=3\n"];
    if(stat == nil) { [pool drain]; [self unlock]; return SYMError_ReceiveError; }
    if(([stat rangeOfString:prompt].location != NSNotFound) || ([stat rangeOfString:@">"].location != NSNotFound))
      [self writeString:[NSString stringWithFormat:@"sym %d\r",institution]];
  }
  
  unsigned char symB0[2] = {0x1B, 0xFE};
  stat = [self expectStrings:[NSArray arrayWithObjects:@"sym Error",[SYMSession decodeStringBytes:symB0 ofLength:2],nil]];
  if(stat == nil)
    { [pool drain]; [self unlock]; return SYMError_ReceiveError;   }
  if([stat rangeOfString:@"sym Error"].location != NSNotFound)
    { [pool drain]; [self unlock]; return SYMError_BadSymitarInst; }
  
  unsigned char symB1[1] = {0xFC};
  stat = [self expectBytes:symB1 ofLength:1];
  if(stat == nil) { [pool drain]; [self unlock]; return SYMError_ReceiveError; }
  SYMCommand *cmd = [SYMCommand parse:[stat substringWithRange:NSMakeRange(0, stat.length-1)]];
  
  NSString *cmdInp = @"Input";
  NSString *cmdErr = @"SymLogonError";
  while([cmd.command localizedCaseInsensitiveCompare:cmdInp] != NSOrderedSame)
  {
    if([cmd.command localizedCaseInsensitiveCompare:cmdErr] == NSOrderedSame)
      if([[cmd getParam:@"Text"] rangeOfString:@"Too Many Invalid Password Attempts"].location != NSNotFound)
      {
        [pool drain];
        [self unlock];
        return SYMError_TooManyAttempts;
      }
    cmd = [self readCommand];
    if(cmd == nil) { [pool drain]; [self unlock]; return SYMError_ReceiveError; }
  }
  
  [self writeString:[NSString stringWithFormat:@"%@\r",symUser]];
  cmd = [self readCommand];
  if(cmd == nil) { [pool drain]; [self unlock]; return SYMError_ReceiveError; }
  if([cmd.command localizedCaseInsensitiveCompare:@"SymLogonInvalidUser"] == NSOrderedSame)
  {
    [self writeString:@"\r"];
    [self readCommand];
    [self unlock];
    [pool drain];
    return SYMError_BadSymitarId;
  }
  
  if([cmd.command localizedCaseInsensitiveCompare:cmdErr] == NSOrderedSame)
  {
    if([[cmd getParam:@"Text"] rangeOfString:@"Too Many Invalid Password Attempts"].location != NSNotFound)
    {
      [pool drain];
      [self unlock];
      return SYMError_TooManyAttempts;
    }
    [pool drain];
    [self unlock];
    return SYMError_ReceiveError;
  }
  
  [self writeString:@"\r"]; cmd=[self readCommand]; if(cmd==nil){[pool drain];[self unlock];return SYMError_ReceiveError;}
  //SymLogonUserLoggedIn~UserNum=***~Password=******~...~HostPaused~Global
  [self writeString:@"\r"]; cmd=[self readCommand]; if(cmd==nil){[pool drain];[self unlock];return SYMError_ReceiveError;}
  //Input~HelpCode=10202
  loggedIn = YES;
  [pool drain];
  [self unlock];
  [self update];
  return SYMError_None;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) wakeUp
{
  [self writeString:@"WakeUp"];
  [self update];
}

//==================================================================================================================================
//  PUBLIC: PROTOCOL: ACCOUNT MANAGER
//==================================================================================================================================
- (SYMError) AccountManager_LoadAccount:(NSString *)account
{
  if(account == nil)         return SYMError_InvalidParameter;
  if([account length] != 10) return SYMError_InvalidParameter;
  
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
  return SYMError_None;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) AccountManager_DemandHtml_Begin:(NSString *)specfile
{
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
  if(cmd == nil) { [pool drain]; return nil; }
  
  [html appendString:@"</HTML>"];
  NSString *result = [html copy];
  [pool drain];
  return [result autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMError) AccountManager_DemandHtml_Complete:(NSDictionary *)values
{
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
  return SYMError_None;
}

//==================================================================================================================================
//  PROTECTED
//==================================================================================================================================
//    Conversions (ASCII/UTF8/INT/BYTE)
//----------------------------------------------------------------------------------------------------------------------------------
+ (NSData *) encodeStringData:(NSString *)string
{
  int length;
  unsigned char *bytes = [self encodeStringBytes:string getLength:&length];
  NSData *result = [NSData dataWithBytes:(const void *)bytes length:(NSUInteger)length];
  free(bytes);
  return result;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
+ (unsigned char *) encodeStringBytes:(NSString *)string getLength:(int *)length
{
  //NOTE: free() me!!!
  int len = (int)[string length];
  unsigned char *bytes = (unsigned char *)malloc(len);
  for(int i=0; i<len; i++)
    bytes[i] = (unsigned char)[string characterAtIndex:(NSUInteger)i];
  if(length != NULL) *length = len;
  return bytes;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
+ (NSString *) decodeStringData :(NSData *)data
{
  return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
+ (NSString *) decodeStringBytes:(unsigned char *)bytes ofLength :(int)length
{
  NSData   *tmpData = [[NSData alloc] initWithBytes:bytes length:length];
  NSString *result  = [[[NSString alloc] initWithData:tmpData encoding:NSASCIIStringEncoding] autorelease];
  [tmpData release];
  return result;
}
//----------------------------------------------------------------------------------------------------------------------------------
//    Writing
//----------------------------------------------------------------------------------------------------------------------------------
- (void) writeString:(NSString *)string
{
  [self writeString:string andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeString:(NSString *)string andWait:(int)milliseconds
{
  int length;
  unsigned char *bytes = [SYMSession encodeStringBytes:string getLength:&length];
  [self writeBytes:bytes fromOffset:0 ofLength:length andWait:milliseconds];
  free(bytes);
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeCommand:(SYMCommand *)command
{
  [self writeCommand:command andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeCommand:(SYMCommand *)command andWait:(int)milliseconds
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *cmdPacket = [command getPacket];
  int length;
  unsigned char *bytes = [SYMSession encodeStringBytes:cmdPacket getLength:&length];
  [self writeBytes:bytes fromOffset:0 ofLength:length andWait:milliseconds];
  free(bytes);
  [pool drain];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeData:(NSData *)data
{
  [self writeData:data andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeData:(NSData *)data andWait:(int)milliseconds
{
  [self writeBytes:(unsigned char *)[data bytes] fromOffset:0 ofLength:(int)[data length] andWait:milliseconds];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeData:(NSData *)data fromOffset:(int)offset ofLength:(int)length
{
  [self writeBytes:(unsigned char *)[data bytes] fromOffset:offset ofLength:length andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeData:(NSData *)data fromOffset:(int)offset ofLength:(int)length andWait:(int)milliseconds
{
  [self writeBytes:(unsigned char *)[data bytes] fromOffset:offset ofLength:length andWait:milliseconds];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeBytes:(unsigned char *)bytes fromOffset:(int)offset ofLength:(int)length
{
  [self writeBytes:bytes fromOffset:offset ofLength:length andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) writeBytes:(unsigned char *)bytes fromOffset:(int)offset ofLength:(int)length andWait:(int)milliseconds
{
  int oldTimeout = socket.timeout;
  [socket setTimeout:(milliseconds / 1000)];
  [socket sendBytes:bytes+offset count:length];
  [socket setTimeout:oldTimeout];
}
//----------------------------------------------------------------------------------------------------------------------------------
//    Reading
//----------------------------------------------------------------------------------------------------------------------------------
- (NSString *) readStringOfLength:(int)length
{
  return [self readStringOfLength:length andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) readStringOfLength:(int)length andWait:(int)milliseconds
{
  unsigned char *read = [self readBytesOfLength:length andWait:milliseconds];
  if(read == NULL) return nil;
  NSString *result = [SYMSession decodeStringBytes:read ofLength:length];
  free(read);
  return result;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMCommand *) readCommand
{
  return [self readCommandAndWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMCommand *) readCommandAndWait:(int)milliseconds
{
  //TODO: timeout ignored...
  static unsigned char cmdHead[2] = {0x1B, 0xFE};
  static unsigned char cmdTail[1] = {0xFC};
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *str1 = [self expectBytes:cmdHead ofLength:2]; if(str1 == nil) { [pool drain]; return nil; }
  NSString *str2 = [self expectBytes:cmdTail ofLength:1]; if(str2 == nil) { [pool drain]; return nil; }
  
  SYMCommand *cmd = [SYMCommand parse:str2];
  
  if([cmd.command localizedCaseInsensitiveCompare:@"MsgDlg"] == NSOrderedSame)
    if([cmd hasParam:@"Text"])
      if([[cmd getParam:@"Text"] rangeOfString:@"From PID"].location != NSNotFound)
        cmd = [self readCommandAndWait:milliseconds];
  
  [cmd retain];
  [pool drain];
  [cmd autorelease];
  return cmd;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSData *) readDataOfLength:(int)length
{
  return [self readDataOfLength:length andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSData *) readDataOfLength:(int)length andWait:(int)milliseconds
{
  unsigned char *read = [self readBytesOfLength:length andWait:timeout];
  if(read == NULL) return nil;
  NSData *result = [NSData dataWithBytes:read length:length];
  free(read);
  return result;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (unsigned char *) readBytesOfLength:(int)length
{
  return [self readBytesOfLength:length andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (unsigned char *) readBytesOfLength:(int)length andWait:(int)milliseconds
{
  //NOTE: free() me!!!
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSDate *start = [NSDate date];
  NSTimeInterval interval = milliseconds / 1000.0;
  int read = 0, oldTimeout = socket.timeout;
  unsigned char *buff = (unsigned char *)malloc(length);
  [socket setTimeout:(timeout / 1000)];
  while(connected && (read < length))
  {
    if(-[start timeIntervalSinceNow] > interval)
    {
      [pool drain];
      [socket setTimeout:oldTimeout];
      return NULL;
    }
    read += (int)[socket receiveBytes:(buff+read) limit:(length-read)];
  }
  
  [socket setTimeout:oldTimeout];
  [pool drain];
  return buff;
}
//----------------------------------------------------------------------------------------------------------------------------------
//    Expecting
//----------------------------------------------------------------------------------------------------------------------------------
- (NSString *) expectString :(NSString *)string
{
  return [self expectString:string andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) expectString :(NSString *)string andWait:(int)milliseconds
{
  NSAutoreleasePool *pool  = [[NSAutoreleasePool alloc] init];
  NSMutableString   *read  = [NSMutableString string];
  NSDate            *start = [NSDate date];
  NSTimeInterval  interval = milliseconds / 1000.0;
  
  while(([read rangeOfString:string].location == NSNotFound) && (-[start timeIntervalSinceNow] < interval))
    [read appendString:[self readStringOfLength:1]];

  if([read rangeOfString:string].location == NSNotFound)
  {
    [pool drain];
    return nil;
  }
  
  NSString *result = [read copy];
  [pool drain];
  return [result autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) expectStrings:(NSArray *)strings
{
  return [self expectStrings:strings andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) expectStrings:(NSArray *)strings andWait:(int)milliseconds
{
  NSAutoreleasePool *pool  = [[NSAutoreleasePool alloc] init];
  NSMutableString   *read  = [NSMutableString string];
  NSDate            *start = [NSDate date];
  NSTimeInterval  interval = milliseconds / 1000.0;
  BOOL               found = NO;
  
  while((!found) && (-[start timeIntervalSinceNow] < interval))
  {
    [read appendString:[self readStringOfLength:1]];
    for(NSString *curr in strings)
    {
      if([read rangeOfString:curr].location != NSNotFound)
      {
        found = YES;
        break;
      }
    }
  }
  
  if(!found)
  {
    [pool drain];
    return nil;
  }
  
  NSString *result = [read copy];
  [pool drain];
  return [result autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) expectBytes:(unsigned char *)bytes ofLength:(int)length
{
  return [self expectBytes:bytes ofLength:length andWait:timeout];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) expectBytes:(unsigned char *)bytes ofLength:(int)length andWait:(int)milliseconds
{
  NSAutoreleasePool *pool  = [[NSAutoreleasePool alloc] init];
  NSMutableData     *read  = [NSMutableData dataWithCapacity:length];
  NSData        *expecting = [NSData dataWithBytes:(const void *)bytes length:length];
  NSDate            *start = [NSDate date];
  NSTimeInterval  interval = milliseconds / 1000.0;
  NSRange           lookIn = NSMakeRange(0, 0);
  BOOL               found = NO;
  
  while((!found) && (-[start timeIntervalSinceNow] < interval))
  {
    unsigned char *ch = [self readBytesOfLength:1];
    [read appendBytes:ch length:1];
    free(ch);
    
    lookIn.length = [read length];
    found = ([read rangeOfData:expecting options:0 range:lookIn].location != NSNotFound);
  }
  
  if(!found)
  {
    [pool drain];
    return nil;
  }
  
  NSString *result = [SYMSession decodeStringData:read];
  [result retain];
  [pool drain];
  return [result autorelease];
}
//==================================================================================================================================
//  PRIVATE
//==================================================================================================================================
- (BOOL) lock
{
  return [lock tryLock];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (BOOL) lockWait:(int)milliseconds
{
  NSDate *until = [[NSDate alloc] initWithTimeIntervalSinceNow:((double)timeout / 1000.0)];
  BOOL result = [lock lockBeforeDate:until];
  [until release];
  return result;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) unlock
{
  [lock unlock];
}
//----------------------------------------------------------------------------------------------------------------------------------
- (void) update
{
  self.lastActive = [[NSDate alloc] init];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) keepAliveStart
{
  if((!connected) || (!loggedIn)) return;
  if(keepAliveThread != nil) [self keepAliveStop];
  
  keepAlive = YES;
  keepAliveThread = [[NSThread alloc] initWithTarget:self selector:@selector(keepAliveRun) object:nil];
  [keepAliveThread start];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) keepAliveStop
{
  if(!keepAlive) return;
  keepAlive = NO;
  
  if(keepAliveThread == nil) return;
  [keepAliveThread cancel];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) keepAliveRun
{
  int oldTimeout;
  
  while(![keepAliveThread isCancelled])
  {
    if(-[lastActive timeIntervalSinceNow] > (double)keepAliveSeconds)
    {
      if([self lock])
      {
        oldTimeout = timeout;
        timeout = 5000;
        [self wakeUp];
        timeout = oldTimeout;
        [self unlock];
        [self update];
      }
    }
    [NSThread sleepForTimeInterval:1.0];
  }
  
  keepAliveThread = nil;
}
//==================================================================================================================================
@end
//==================================================================================================================================
