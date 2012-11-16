//==================================================================================================================================
//  SYMFile.h
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import <Foundation/Foundation.h>
//==================================================================================================================================
typedef enum
{
  SYMFile_Report         =  0,
  SYMFile_Letter         =  1,
  SYMFile_RepGen         =  2,
  SYMFile_Help           =  3,
  SYMFile_HTML           =  4,
  SYMFile_Documentation  =  5,
  SYMFile_SymForm        =  6,
  SYMFile_UpdateSoftware =  7,
  SYMFile_BSC            =  8,
  SYMFile_Extract        =  9,
  SYMFile_Batch          = 10,
  SYMFile_Passport       = 11,
  SYMFile_Data           = 12,
  SYMFile_Edit           = 13
} SYMFile_Type;
//==================================================================================================================================
/**
 The `SYMFile` class holds a reference to a file in a Symitar Institution.
 */
@interface SYMFile : NSObject
{
  NSString    *server;
  NSUInteger   institution;
  NSString    *name;
  NSDate      *date;
  NSUInteger   size;
  SYMFile_Type type;
  NSUInteger   sequence;
}
//----------------------------------------------------------------------------------------------------------------------------------
/** IP/hostname of the Symitar server that this file resides on. */
@property (readonly) NSString    *server;
/** Institution number that this file resides on. */
@property (readonly) NSUInteger   institution;
/** Name of this file. */
@property (readonly) NSString    *name;
/** Date this file was last modified. */
@property (readonly) NSDate      *date;
/** Size (in bytes) of this file. */
@property (readonly) NSUInteger   size;
/** Type of this file (Letter/RepGen/...). */
@property (readonly) SYMFile_Type type;
/** Sequence number (for reports). */
@property (readonly) NSUInteger   sequence;
//----------------------------------------------------------------------------------------------------------------------------------
/**
 Constructor
 */
+ (SYMFile *) fileWithServer:(NSString *)Server Institution:(NSUInteger)Institution Name:(NSString *)Name Date:(NSDate *)Date Size:(NSUInteger)Size Type:(SYMFile_Type)Type Sequence:(NSUInteger)Sequence;
/**
 Constructor (non-autoreleased)
 */
+ (SYMFile *) newFileWithServer:(NSString *)Server Institution:(NSUInteger)Institution Name:(NSString *)Name Date:(NSDate *)Date Size:(NSUInteger)Size Type:(SYMFile_Type)Type Sequence:(NSUInteger)Sequence;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Constructor
 */
- initWithServer:(NSString *)Server Institution:(NSUInteger)Institution Name:(NSString *)Name Date:(NSDate *)Date Size:(NSUInteger)Size Type:(SYMFile_Type)Type Sequence:(NSUInteger)Sequence;
/**
 File comparer.
 
 Tests files for equal `type`, `institution`, `name` and `server`.
 
 @param file SYMFile to compare to.
 */
- (BOOL) isSameAs:(SYMFile *)file;
//----------------------------------------------------------------------------------------------------------------------------------
@end
//==================================================================================================================================


//TODO:
/*
 SYMFile local read/write/rename/delete commands
 that will take a SYMSessionManager refrence.
 SYMSessionManager will, given a server & inst, return existing connection if available, or clone existing connection if busy
*/
