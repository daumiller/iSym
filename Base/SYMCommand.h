//==================================================================================================================================
//  SYMCommand.h
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import <Foundation/Foundation.h>
//==================================================================================================================================
/**
 The `SYMCommand` class contains a 'packet' of information for Symitar communication.
 
 This class shouldn't be needed unless you are writing new functionality outside of the SYMSession categories.
 */
@interface SYMCommand : NSObject
{
  //Crappy ivars required for 32 bit Mac runtime (compiling on SL)...
  NSString *command;
  NSString *data;
  NSMutableDictionary *parameters;
}
//----------------------------------------------------------------------------------------------------------------------------------
/** Command name. */
@property (nonatomic, retain) NSString            *command;
/** Raw data. */
@property (nonatomic, retain) NSString            *data;
/** Data parsed into key-value pairs. */
@property (nonatomic, retain) NSMutableDictionary *parameters;
//----------------------------------------------------------------------------------------------------------------------------------
/**
 Create new SYMCommand from raw data.
 
 @param raw Raw data to be parsed.
 */
+ parse:(NSString *)raw;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Basic constructor */
+ command;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Basic constructor */
- init;
//----------------------------------------------------------------------------------------------------------------------------------
/**
 Check for existence of key-value pair.
 
 @param param Key name to check for.
 */
- (BOOL)       hasParam:(NSString *)param;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Get value for key.
 
 @param param Key name to get value of.
 */
- (NSString *) getParam:(NSString *)param;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Set value for key.
 
 + If key doesn't exist, will be created; If key does exist, will be overwrote.
 + Value should **NOT** be `nil`, but a zero-length string is okay.
 
 @param param Key name to set value of.
 @param value Value to set.
 */
- (void)       setParam:(NSString *)param toValue:(NSString *)value;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Remove a key-value pair.
 
 @param param Key name to be removed.
 */
- (void)       delParam:(NSString *)param;
//----------------------------------------------------------------------------------------------------------------------------------
/**
 Serialize to a ready-to-send string.
 */
- (NSString *) getPacket;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Extracts file data from command's raw data.
 */
- (NSString *) getFileData;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Returns a human-friendly serialization.
 
 Returned string is similar to `getPacket`, with non-printing characters removed.
 */
- (NSString *) friendlyString;
//----------------------------------------------------------------------------------------------------------------------------------
@end
//==================================================================================================================================
