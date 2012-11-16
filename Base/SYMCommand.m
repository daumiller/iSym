//==================================================================================================================================
//  SYMCommand.m
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import "SYMCommand.h"
//----------------------------------------------------------------------------------------------------------------------------------
static int _sym_command_idCurrent = 10000;
//==================================================================================================================================
@implementation SYMCommand
//----------------------------------------------------------------------------------------------------------------------------------
@synthesize command;
@synthesize data;
@synthesize parameters;
//----------------------------------------------------------------------------------------------------------------------------------
+ parse:(NSString *)raw
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SYMCommand *symCmd = [[SYMCommand alloc] init];
  
  symCmd->data = [raw copy];
  
  //hide any file data from the command\key parser
  NSRange FD = [raw rangeOfString:@"\u00FD"];
  NSRange FE = [raw rangeOfString:@"\u00FE"];
  if((FD.location != NSNotFound) && (FE.location != NSNotFound))
    raw = [NSString stringWithFormat:@"%@%@", [raw substringToIndex:FD.location], [raw substringFromIndex:FE.location+1]];
  
  //anything to parse?
  if(raw.length < 1) { [pool drain]; return [symCmd autorelease]; }
  
  //parameters to process?
  if(([raw rangeOfString:@"~"].location != NSNotFound) && ([raw rangeOfString:@"\u00FC"].location != NSNotFound))
  {
    //get end-of-command/beginning-of-parameter
    NSRange firstTilde = [raw rangeOfString:@"~"];
    if(firstTilde.location != NSNotFound)
      symCmd.command = [raw substringToIndex:firstTilde.location];
    
    //get parameters
    NSArray *tokens = [raw componentsSeparatedByString:@"~"];
    NSRange rngKey, rngVal;
    for(int i=1; i<tokens.count; i++)
    {
      NSString *curr = (NSString *)[tokens objectAtIndex:i];
      NSRange eqRng = [curr rangeOfString:@"="];
      int eqPos = (int)eqRng.location;
      
      if(eqRng.location != NSNotFound)
      {
        rngKey = NSMakeRange(0, eqPos);
        if([curr characterAtIndex:eqPos] == 252) rngKey.length--;
        
        int q = [curr characterAtIndex:(curr.length-1)];
        if(q == 23) q = 32;
        rngVal = NSMakeRange(eqPos+1, curr.length - (eqPos+1));
        if([curr characterAtIndex:(curr.length-1)] == 252) rngVal.length--;
        
        [symCmd setParam:[curr substringWithRange:rngKey] toValue:[curr substringWithRange:rngVal]];
      }
      else
      {
        rngKey = NSMakeRange(0, curr.length);
        if([curr characterAtIndex:curr.length-1] == 252) rngKey.length--;
        [symCmd setParam:[curr substringWithRange:rngKey] toValue:@""];
      }

    }
  }
  else
    symCmd->command = [raw copy];
  
  [pool drain];
  return [symCmd autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
+ command
{
  return [[[self alloc] init] autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- init
{
  self = [super init];
  self.command    = @"";
  self.data       = nil;
  self.parameters = [NSMutableDictionary dictionaryWithCapacity:1];
  [parameters setObject:[NSString stringWithFormat:@"%d",_sym_command_idCurrent++] forKey:@"MsgId"];
  return self;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) dealloc
{
  self.command    = nil;
  self.data       = nil;
  self.parameters = nil;
  [super dealloc];
}
//----------------------------------------------------------------------------------------------------------------------------------
- (BOOL) hasParam:(NSString *)param
{
  return ([parameters objectForKey:param] != nil);
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) getParam:(NSString *)param
{
  return [parameters objectForKey:param];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) setParam:(NSString *)param toValue:(NSString *)value
{
  if(value == nil) value = @"";
  [parameters setObject:value forKey:param];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (void) delParam:(NSString *)param
{
  [parameters removeObjectForKey:param];
}
//----------------------------------------------------------------------------------------------------------------------------------
- (NSString *) getPacket
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSMutableString *strA = [NSMutableString stringWithCapacity:(command.length+1)];
  [strA appendFormat:@"%@~", command];
  
  BOOL first = YES;
  NSArray *params = [parameters allKeys];
  for(NSString *key in params)
  {
    if(!first) [strA appendString:@"~"]; else first = NO;
    [strA appendString:key];
    NSString *value = [parameters objectForKey:key];
    if(value.length > 0) [strA appendFormat:@"=%@", value];
  }
  
  NSMutableString *strB = [NSMutableString stringWithCapacity:(strA.length+3)];
  [strB appendFormat:@"%c%d\r%@", 0x0007, strA.length, strA];
  
  NSString *packet = [strB copy];
  [pool drain];
  return [packet autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) getFileData
{
  if(!data) return nil;
  NSRange FD = [data rangeOfString:@"\u00FD"];
  NSRange FE = [data rangeOfString:@"\u00FE"];
  if((FD.location != NSNotFound) && (FE.location != NSNotFound))
    return [data substringWithRange:NSMakeRange(FD.location+1, FE.location-FD.location-1)];
  return @"";
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (NSString *) friendlyString
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSMutableString *str = [NSMutableString stringWithCapacity:command.length];
  [str appendString:command];
  
  for(NSString *key in parameters)
  {
    [str appendFormat:@"~%@",key];
    NSString *value = [parameters objectForKey:key];
    if(value.length > 0) [str appendFormat:@"=%@",value];
  }
  
  NSString *friendly = [str copy];
  [pool drain];
  return [friendly autorelease];
}
//----------------------------------------------------------------------------------------------------------------------------------
@end
//==================================================================================================================================
