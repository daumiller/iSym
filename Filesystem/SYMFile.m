//==================================================================================================================================
//  SYMFile.m
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import "SYMFile.h"
@implementation SYMFile
//==================================================================================================================================
@synthesize server;
@synthesize institution;
@synthesize name;
@synthesize date;
@synthesize size;
@synthesize type;
@synthesize sequence;
//----------------------------------------------------------------------------------------------------------------------------------
+ (SYMFile *) fileWithServer:(NSString *)Server Institution:(NSUInteger)Institution Name:(NSString *)Name Date:(NSDate *)Date Size:(NSUInteger)Size Type:(SYMFile_Type)Type Sequence:(NSUInteger)Sequence
{
  return [[[SYMFile alloc] initWithServer:Server Institution:Institution Name:Name Date:Date Size:Size Type:Type Sequence:Sequence] autorelease];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
+ (SYMFile *) newFileWithServer:(NSString *)Server Institution:(NSUInteger)Institution Name:(NSString *)Name Date:(NSDate *)Date Size:(NSUInteger)Size Type:(SYMFile_Type)Type Sequence:(NSUInteger)Sequence
{
  return [[SYMFile alloc] initWithServer:Server Institution:Institution Name:Name Date:Date Size:Size Type:Type Sequence:Sequence];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- initWithServer:(NSString *)Server Institution:(NSUInteger)Institution Name:(NSString *)Name Date:(NSDate *)Date Size:(NSUInteger)Size Type:(SYMFile_Type)Type Sequence:(NSUInteger)Sequence;
{
  self = [super init];
  if(self)
  {
    server      = [Server retain];
    institution = Institution;
    name        = [Name retain];
    date        = [Date retain];
    size        = Size;
    type        = Type;
    sequence    = Sequence;
  }
  return self;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (BOOL) isSameAs:(SYMFile *)file
{
  if(type        != file.type       ) return NO;
  if(institution != file.institution) return NO;
  if(name != nil)
    if([name localizedCompare:file.name] != NSOrderedSame)
      return NO;
  if(server != nil)
    if([server localizedCaseInsensitiveCompare:file.server] != NSOrderedSame)
      return NO;

  return YES;
}
//----------------------------------------------------------------------------------------------------------------------------------
- (void) dealloc
{
  [server release];
  [name   release];
  [date   release];
  [super dealloc];
}
//==================================================================================================================================
@end
