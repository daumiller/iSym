#import <Cocoa/Cocoa.h>
#import <iSym/iSym.h>

NSString *pass = @"Passed", *fail = @"FAILED";
void testFilesystem(SYMSession *sess, NSAutoreleasePool *pool);

int main (int argc, const char * argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  SYMError err;
  SYMSession *sess = [SYMSession sessionForServer:@"testServer"
                                             port:1337
                                          aixUser:@"testAixUser" 
                                          aixPass:@"testAixPass"
                                           prompt:@"$ "
                                          symUser:@"testSymUser"
                                      institution:4331];
  err = [sess connect];    if(err != SYMError_None) { NSLog(@"Session Connect Error: %d",   (int)err); [pool drain]; return -1; }
  err = [sess login];      if(err != SYMError_None) { NSLog(@"Session Login Error: %d",     (int)err); [pool drain]; return -1; }
  //--------------------------------------------------------------------------------------------------------------------------------
  
  testFilesystem(sess, pool);
  
  //--------------------------------------------------------------------------------------------------------------------------------
  err = [sess disconnect]; if(err != SYMError_None) { NSLog(@"Session Disconnect Error: %d",(int)err); [pool drain]; return -1; }

  NSLog(@"Exited Okay");
  [pool drain];
  return 0;
}

//==================================================================================================================================
void testFilesystem(SYMSession *sess, NSAutoreleasePool *pool)
{
  SYMError err;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //Filesystem_exists
  BOOL exTest;
  exTest = [sess Filesystem_exists:@"DA.ERR.TES+"        type:SYMFile_RepGen]; NSLog(@"File Exists Test 0 : %@", (exTest == YES) ? pass : fail );
  exTest = [sess Filesystem_exists:@"DA.ERR.TEST.A"      type:SYMFile_RepGen]; NSLog(@"File Exists Test 1 : %@", (exTest == YES) ? pass : fail );
  exTest = [sess Filesystem_exists:@"DA.ERR.TEST.C"      type:SYMFile_RepGen]; NSLog(@"File Exists Test 2 : %@", (exTest == NO ) ? pass : fail );
  exTest = [sess Filesystem_exists:@"DA.ERR.TEST.A"      type:SYMFile_Letter]; NSLog(@"File Exists Test 3 : %@", (exTest == NO ) ? pass : fail );
  exTest = [sess Filesystem_exists:@"DA.ERR.TEST.LETTER" type:SYMFile_Letter]; NSLog(@"File Exists Test 4 : %@", (exTest == YES) ? pass : fail );
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //Filesystem_get
  SYMFile *getTest = nil;
  err = [sess Filesystem_get:@"DA.ERR.TEST.B" type:SYMFile_RepGen file:&getTest];
  exTest = ((err != SYMError_None) || (getTest == nil));
  NSLog(@"File Get Test      : %@", (exTest == NO) ? pass : fail);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //Filesystem_rename
  err = [sess Filesystem_rename:@"DA.ERR.TEST.A" type:SYMFile_RepGen renameTo:@"DA.ERR.TEST.C"];
  exTest = (err == SYMError_None) && (![sess Filesystem_exists:@"DA.ERR.TEST.A" type:SYMFile_RepGen]) && [sess Filesystem_exists:@"DA.ERR.TEST.C" type:SYMFile_RepGen];
  [sess Filesystem_rename:@"DA.ERR.TEST.C" type:SYMFile_RepGen renameTo:@"DA.ERR.TEST.A"];
  NSLog(@"File Rename Test 0 : %@", (exTest == YES) ? pass : fail);
  err = [sess Filesystem_rename:@"DA.ERR.TEST.A" type:SYMFile_RepGen renameTo:@"DA.ERR.TEST.B"];
  NSLog(@"File Rename Test 1 : %@", (err != SYMError_None) ? pass : fail);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //Filesystem_read
  NSString *readStr = nil;
  err = [sess Filesystem_read:@"DA.LETTERFILE.READ.TEST" type:SYMFile_Letter content:&readStr];
  exTest = ((err != SYMError_None) || (readStr == nil) || ([readStr caseInsensitiveCompare:@"reading test"] != NSOrderedSame));
  NSLog(@"File Read Test     : %@", (exTest == NO) ? pass : fail);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //Filesystem_write
  NSString *writingTest = @"writing test";
  err = [sess Filesystem_write:@"DA.LETTERFILE.WRITE0" type:SYMFile_Letter content:writingTest];
  exTest = (err == SYMError_None) && [sess Filesystem_exists:@"DA.LETTERFILE.WRITE0" type:SYMFile_Letter];
  if(exTest)
  {
    readStr = nil;
    err = [sess Filesystem_read:@"DA.LETTERFILE.WRITE0" type:SYMFile_Letter content:&readStr];
    exTest = (err == SYMError_None) && (readStr != nil) && ([readStr caseInsensitiveCompare:writingTest] == NSOrderedSame);
  }
  NSLog(@"File Write Test    : %@", (exTest == YES) ? pass : fail);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //Filesystem_delete
  err = [sess Filesystem_delete:@"DA.LETTERFILE.WRITE0" type:SYMFile_Letter];
  exTest = (err == SYMError_None) && ![sess Filesystem_exists:@"DA.LETTERFILE.WRITE0" type:SYMFile_Letter];
  NSLog(@"File Delete Test   : %@", (exTest == YES) ? pass : fail);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //Filesystem_list
  NSArray *files;
  err = [sess Filesystem_list:@"DA.M+" type:SYMFile_RepGen files:&files];
  if(err != SYMError_None) { NSLog(@"Session Error: Listing Files: %d", (int)err); [sess disconnect]; [pool drain]; exit(-1); }
  
  NSLog(@"Found %u files matching \"DA.M+\"", (unsigned int)[files count]);
  NSDateFormatter *dfmt = [[NSDateFormatter alloc] init];
  [dfmt setDateFormat:@"yyyy-MM-dd hh:mm"];
  
  int max = (int)[files count];
  for(int i=0; i<max; i++)
  {
    SYMFile *curr = (SYMFile *)[files objectAtIndex:i];
    NSString *dateStr = [dfmt stringFromDate:curr.date];
    NSLog(@"FILE: %@ :: %06u :: %@", dateStr, (unsigned int)curr.size, curr.name);
  }
  [dfmt release];
}
//==================================================================================================================================
