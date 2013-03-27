//==================================================================================================================================
//  SYMSession+Filesystem.m
//  part of the iSym library
//  Copyright 2012-2013 Dillon Aumiller
//==================================================================================================================================
#import "SYMSession+Filesystem.h"
#import "SYMCommand.h"
//----------------------------------------------------------------------------------------------------------------------------------
NSString *SYMFile_TypeStr[] = { @"Report"        ,  // SYMFile_Report
                                @"Letter"        ,  // SYMFile_Letter
                                @"RepWriter"     ,  // SYMFile_RepGen
                                @"Help"          ,  // SYMFile_Help
                                @"PCHTML"        ,  // SYMFile_HTML
                                @"PCDocsCU"      ,  // SYMFile_Documentation
                                @"PCForms"       ,  // SYMFile_SymForm
                                @"UpdateSoftware",  // SYMFile_UpdateSoftware
                                @"BSC"           ,  // SYMFile_BSC
                                @"Extract"       ,  // SYMFile_Extract
                                @"Batch"         ,  // SYMFile_Batch
                                @"Passport"      ,  // SYMFile_Passport
                                @"Data"          ,  // SYMFile_Data
                                @"EditFile"      }; // SYMFile_Edit
//----------------------------------------------------------------------------------------------------------------------------------
@implementation SYMSession (Filesystem)
//==================================================================================================================================
+ (NSDate *) Filesystem_convertDate:(NSString *)symDate andTime:(NSString *)symTime
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSDate *ret;
  NSMutableString  *strD  = [NSMutableString stringWithString:symDate];
  NSMutableString  *strT  = [NSMutableString stringWithString:symTime];
  NSDateComponents *dcomp = [[NSDateComponents alloc] init];
  NSCalendar *ical = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  
  //input : @"M/D/YYYY H:MM"
  //output: NSDate
  while([strD length] < 8) [strD insertString:@"0" atIndex:0];
  while([strT length] < 4) [strT insertString:@"0" atIndex:0];
  [dcomp setYear  :[[strD substringWithRange:NSMakeRange(4,4)] integerValue]];
  [dcomp setMonth :[[strD substringWithRange:NSMakeRange(0,2)] integerValue]];
  [dcomp setDay   :[[strD substringWithRange:NSMakeRange(2,2)] integerValue]];
  [dcomp setHour  :[[strT substringWithRange:NSMakeRange(0,2)] integerValue]];
  [dcomp setMinute:[[strT substringWithRange:NSMakeRange(2,2)] integerValue]];
  ret = [ical dateFromComponents:dcomp];
  
  [ret retain];
  [ical release];
  [dcomp release];
  [pool drain];
  
  return [ret autorelease];
}
//==================================================================================================================================
- (BOOL) Filesystem_exists:(NSString *)pattern type:(SYMFile_Type)type
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSArray *list;
  SYMError err = [self Filesystem_list:pattern type:type files:&list];
  if(err != SYMError_None) { [pool drain]; return NO; }
  if(list == nil)          { [pool drain]; return NO; }
  if([list count] == 0)    { [pool drain]; return NO; }
                             [pool drain]; return YES;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError) Filesystem_get:(NSString *)pattern type:(SYMFile_Type)type file:(SYMFile **)file
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSArray *list; *file = nil;
  
  SYMError ret = [self Filesystem_list:pattern type:type files:&list];
  if(ret != SYMError_None) { [pool drain]; return ret;                             }
  if(list == nil)          { [pool drain]; return SYMError_Filesystem_Unspecified; }
  if([list count] == 0)    { [pool drain]; return SYMError_Filesystem_NotFound;    }

  *file = [[list objectAtIndex:0] retain];
  [pool drain];
  [*file autorelease];
  return SYMError_None;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError) Filesystem_list:(NSString *)pattern type:(SYMFile_Type)type files:(NSArray **)files
{
  *files = nil;
  if(!connected || !loggedIn) return SYMError_NotConnected;
  if(![self lock]) return SYMError_InUse;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  //TODO: NOTE: this works, but should be implemented the correct way (one of: "EDITFILE.DATA" or "Edit File"?)
  if(type == SYMFile_Edit) pattern = @"E+";
  NSMutableArray *list = [NSMutableArray arrayWithCapacity:1];
  
  SYMCommand *cmd = [SYMCommand command];
  cmd.command = @"File";
  [cmd setParam:@"Type"   toValue:SYMFile_TypeStr[(int)type]];
  [cmd setParam:@"Name"   toValue:pattern];
  [cmd setParam:@"Action" toValue:@"List"];
  [self writeCommand:cmd];
  
  while(YES)
  {
    cmd = [self readCommand];
    if(cmd == nil) { [pool drain]; [self unlock]; return SYMError_Unspecified; }
    if([cmd hasParam:@"Status"]) break;
    if([cmd hasParam:@"Name"  ])
    {
      NSString  *fileName = [cmd getParam:@"Name"];
      NSDate    *fileDate = [SYMSession Filesystem_convertDate:[cmd getParam:@"Date"] andTime:[cmd getParam:@"Time"]];
      NSUInteger fileSize = (NSUInteger)[[cmd getParam:@"Size"] integerValue];
      NSUInteger fileSequence = 0; if([cmd hasParam:@"Sequence"]) fileSequence = (NSUInteger)[[cmd getParam:@"Sequence"] integerValue];
      
      SYMFile *file = [SYMFile fileWithServer:server
                                  Institution:institution
                                         Name:fileName
                                         Date:fileDate
                                         Size:fileSize
                                         Type:type
                                     Sequence:fileSequence];
      [list addObject:file];
    }
    if([cmd hasParam:@"Done"]) break;
  }
  
  NSArray *realRet = [list copy];
  [pool drain];
  [self unlock];
  *files = [realRet autorelease];
  return SYMError_None;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError) Filesystem_rename:(NSString *)pattern type:(SYMFile_Type)type renameTo:(NSString *)renameTo
{
  if(!connected || !loggedIn) return SYMError_NotConnected;
  if(type == SYMFile_Edit) return SYMError_Filesystem_InvalidActionForType;
  if(![self lock]) return SYMError_InUse;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SYMCommand *cmd = [SYMCommand command];
  cmd.command = @"File";
  [cmd setParam:@"Action"  toValue:@"Rename"];
  [cmd setParam:@"Type"    toValue:SYMFile_TypeStr[(int)type]];
  [cmd setParam:@"Name"    toValue:pattern];
  [cmd setParam:@"NewName" toValue:renameTo];
  [self writeCommand:cmd];
  
  SYMError ret = SYMError_Unspecified;
  cmd = [self readCommand];
  if(cmd == nil) { [pool drain]; [self unlock]; return SYMError_Unspecified; }
  if([cmd hasParam:@"Status"])
  {
    if([[cmd getParam:@"Status"] rangeOfString:@"No such file or directory"].location != NSNotFound)
      ret = SYMError_Filesystem_NotFound;
    else
      ret = SYMError_Filesystem_FilenameTooLong;
    //TODO: don't know if there are additional error descriptions or not,
    //but currently, FilenameTooLong is also returned for things like 'Can't Rename Because File Already Exists'...
    //need to WireShark these guys...
  }
  else if([cmd hasParam:@"Done"])
    ret = SYMError_None;
  
  [pool drain];
  [self unlock];
  return ret;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError) Filesystem_delete:(NSString *)pattern type:(SYMFile_Type)type
{
  if(!connected || !loggedIn) return SYMError_NotConnected;
  if(![self lock]) return SYMError_InUse;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  //TODO: NOTE: need to test this
  if(type == SYMFile_Edit) pattern = @"Edit File";
  
  SYMCommand *cmd = [SYMCommand command];
  cmd.command = @"File";
  [cmd setParam:@"Action"  toValue:@"Delete"];
  [cmd setParam:@"Type"    toValue:SYMFile_TypeStr[(int)type]];
  [cmd setParam:@"Name"    toValue:pattern];
  [self writeCommand:cmd];
  
  SYMError ret = SYMError_Unspecified;
  cmd = [self readCommand];
  if(cmd == nil) { [pool drain]; [self unlock]; return SYMError_Unspecified; }
  if([cmd hasParam:@"Status"])
  {
    if([[cmd getParam:@"Status"] rangeOfString:@"No such file or directory"].location != NSNotFound)
      ret = SYMError_Filesystem_NotFound;
    else
      ret = SYMError_Filesystem_FilenameTooLong;
  }
  else if([cmd hasParam:@"Done"])
    ret = SYMError_None;
  
  [pool drain];
  [self unlock];
  return ret;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError) Filesystem_read:(NSString *)pattern type:(SYMFile_Type)type content:(NSString **)content
{
  *content = nil;
  if(!connected || !loggedIn) return SYMError_NotConnected;
  if(![self lock]) return SYMError_InUse;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  //TODO: NOTE: this needs testing
  if(type == SYMFile_Edit) pattern = @"EDITFILE.DATA";
  
  NSMutableString *wip = [NSMutableString stringWithCapacity:4096];
  SYMCommand *cmd = [SYMCommand command];
  cmd.command = @"File";
  [cmd setParam:@"Action" toValue:@"Retrieve"];
  [cmd setParam:@"Type"   toValue:SYMFile_TypeStr[(int)type]];
  [cmd setParam:@"Name"   toValue:pattern];
  [self writeCommand:cmd];
  
  while(self.connected && self.loggedIn)
  {
    cmd = [self readCommand];
    if([cmd hasParam:@"Status"])
    {
      SYMError ret;
      
      if([[cmd getParam:@"Status"] rangeOfString:@"No such file or directory"].location != NSNotFound)
        ret = SYMError_Filesystem_NotFound;
      else if([[cmd getParam:@"Status"] rangeOfString:@"Cannot view a blank report"].location != NSNotFound)
      {
        *content = @"";
        ret = SYMError_None;
      }
      else
        ret = SYMError_Filesystem_FilenameTooLong;
      
      [pool drain];
      [self unlock];
      return ret;
    }
    
    NSString *chunk = [cmd getFileData];
    if([chunk length] > 0)     [wip appendString:chunk];
    if(type == SYMFile_Report) [wip appendString:@"\n"];
    
    if([cmd hasParam:@"Done"])
      break;
  }
  
  NSString *retStr = [[NSString stringWithString:wip] retain];
  [pool drain];
	[self unlock];
  *content = [retStr autorelease];
  return SYMError_None;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError) Filesystem_write:(NSString *)pattern type:(SYMFile_Type)type content:(NSString *)content
{
  if(!connected || !loggedIn) return SYMError_NotConnected;
  if(![self lock]) return SYMError_InUse;
  
  NSAutoreleasePool *pool2, *pool = [[NSAutoreleasePool alloc] init];
  if(content == nil) content = [NSString stringWithFormat:@""];
  //TODO: this needs testing
  if(type == SYMFile_Edit) pattern = @"EDITFILE.DATA";
  
  SYMCommand *cmd = [SYMCommand command];
  cmd.command = @"File";
  [cmd setParam:@"Action" toValue:@"Store"];
  [cmd setParam:@"Type"   toValue:SYMFile_TypeStr[(int)type]];
  [cmd setParam:@"Name"   toValue:pattern];
  
  //write command, read result
  [self wakeUp];
  [self writeCommand:cmd];
  cmd = [self readCommand];
  if(cmd == nil) { [pool drain]; [self unlock]; return SYMError_Unspecified; }
  
  //check for error
  if([cmd hasParam:@"Status"])
    if([[cmd getParam:@"Status"] rangeOfString:@"Filename is too long"].location != NSNotFound)
      { [pool drain]; [self unlock]; return SYMError_Filesystem_FilenameTooLong; }
  
  //check for validity by presence of "BadCharList" command
  int readCmds = 0;
  while(self.connected && self.loggedIn && ![cmd hasParam:@"BadCharList"] && (readCmds < 6))
  {
    cmd = [self readCommand];
    readCmds++;
  }
  if(![cmd hasParam:@"BadCharList"])
  {
    [pool drain];
    [self unlock];
    return SYMError_Unspecified;
  }
  
  //replace 'bad' characters
  pool2 = [[NSAutoreleasePool alloc] init];
  NSArray *badChars = [[cmd getParam:@"BadCharList"] componentsSeparatedByString:@","];
  for(NSString *badASCII in badChars)
  {
    NSString *badChar = [NSString stringWithFormat:@"%c", [badASCII integerValue]];
    content = [content stringByReplacingOccurrencesOfString:badChar withString:@""];
  }
  //only keep the last copy of content (we don't want 23 copies of a 32 MB file hanging around until EOF...)
  [content retain];
  [pool2 release];
  [content autorelease];
  
  //get chunk size (and maximum file size)
  NSUInteger chunkMax = 1024;
  if([cmd hasParam:@"MaxBuff"])
    chunkMax = (NSUInteger)[[cmd getParam:@"MaxBuff"] integerValue];
  if([content length] > (999 * chunkMax))
  {
    //NOTE: this makes a maximum filesize of (99999 * 999) ~= 99 MB
    [pool drain];
    [self unlock];
    return SYMError_Filesystem_FileTooLarge;
  }
  
  NSUInteger sent=0, block=0, len = [content length];
  NSUInteger chunkSize;
  NSString *blockStr, *chunkStr, *chunkSizeStr; unsigned char *resp, statResp[] = {0, 0, 0, 0, 0, 0, 0, 0x4E};
  while(self.connected && self.loggedIn && (sent < len))
  {
    pool2 = [[NSAutoreleasePool alloc] init]; //this would only create 2x filesize, but we're still going to free as we go
    chunkSize = (len - sent);
    if(chunkSize > chunkMax) chunkSize = chunkMax;
    chunkStr     = [content substringWithRange:NSMakeRange(sent, chunkSize)];
    chunkSizeStr = [NSString stringWithFormat:@"%05u", chunkSize];
    blockStr     = [NSString stringWithFormat:@"%03u", block];
    
    //resend chunk until correct received acknowledgement
    resp = statResp;
    while(resp[7] == 0x4E)
    {
      if(resp && (resp != statResp)) free(resp);
      [self writeString:[NSString stringWithFormat:@"PROT%@DATA%@", blockStr, chunkSizeStr]];
      [self writeString:chunkStr];
      resp = [self readBytesOfLength:16];
    }
    if(resp && (resp != statResp)) free(resp);
    [pool2 drain];
    
    block++;
    sent += chunkSize;
  }
  
  //send end-of-store command; read result
  [self writeString:[NSString stringWithFormat:@"PROT%03uEOF\x020\x020\x020\x020\x020\x020",block]];
  resp = [self readBytesOfLength:16];
  if(resp) free(resp);
  cmd = [self readCommand];
  
  [self wakeUp];
  [pool drain];
  [self unlock];
  return SYMError_None;
}
//==================================================================================================================================
@end
