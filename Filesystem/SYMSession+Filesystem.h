//==================================================================================================================================
//  SYMSession+Filesystem.h
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import <Foundation/Foundation.h>
#import "SYMSession.h"
#import "SYMFile.h"

//----------------------------------------------------------------------------------------------------------------------------------
//  SYMSession - Filesystem Category
//----------------------------------------------------------------------------------------------------------------------------------
@interface SYMSession (Filesystem)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Check if file exists.
 
 @param pattern Name of file to check.
 @param type Type of file to check.
 */
- (BOOL) Filesystem_exists:(NSString *)pattern type:(SYMFile_Type)type;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Get a file handle.
 
 On error, the value pointed to by the `file` parameter will be set to `nil`.
 
 @param pattern Name of file to get.
 @param type Type of file to get.
 @param file Pointer to SYMFile to receive open object on success.
 */
- (SYMError) Filesystem_get:(NSString *)pattern type:(SYMFile_Type)type file:(SYMFile **)file;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Get a list of files.
 
 On error, the value pointed to by the `files` parameter will be set to `nil`.
 On success with zero results, the value pointed to by the `files` parameter will contain a zero-length NSArray.
 
 @param pattern Pattern of files to list.
 @param type Type of files to list.
 @param files Pointer to NSArray to receive list on success.
 */
- (SYMError) Filesystem_list:(NSString *)pattern type:(SYMFile_Type)type files:(NSArray **)files;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Rename a file.
 
 @param pattern Current name of file.
 @param type Type of file to be renamed.
 @param renameTo New name of file to be set.
 */
- (SYMError) Filesystem_rename:(NSString *)pattern type:(SYMFile_Type)type renameTo:(NSString *)renameTo;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Delete a file.
 
 @param pattern Name of file to delete.
 @param type Type of file to delete.
 */
- (SYMError) Filesystem_delete:(NSString *)pattern type:(SYMFile_Type)type;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Read a file.
 
 On error, the value pointed to by `content` will be set to `nil`.
 On success, `content` will be set to an NSString containing the entire file's contents.
 
 **Note**: The current protocol used by Symitar limits any files read/wrote to a maximum size of around 95 MB.
 
 @param pattern Name of file to read.
 @param type Type of file to read.
 @param content Pointer to NSString to receive file contents.
 */
- (SYMError) Filesystem_read:(NSString *)pattern type:(SYMFile_Type)type content:(NSString **)content;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Write a file.
 
 + This function can be used to create a file.
 + Passing `nil` (or a zero-length string) for `content` is acceptable.
 
 **Note**: The current protocol used by Symitar limits any files read/wrote to a maximum size of around 95 MB.
 
 @param pattern Name of file to write.
 @param type Type of file to write.
 @param content Content to write to file.
 */
- (SYMError) Filesystem_write:(NSString *)pattern type:(SYMFile_Type)type content:(NSString *)content;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@end
