//==================================================================================================================================
//  SYMSession.h
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import <Foundation/Foundation.h>
#import "SYMError.h"
//----------------------------------------------------------------------------------------------------------------------------------
@class FastSocket;
@class SYMCommand;
//==================================================================================================================================
/**
 The `SYMSession` class maintains a single Symitar institution connection.
 The base class can be used for raw communication, but the provided categories attempt to abstract all needed functionality.
 */
@interface SYMSession : NSObject <NSCopying>
{
  FastSocket *socket;
  NSLock     *lock;
  NSString   *server;
  int         port;
  NSString   *prompt;
  int         institution;
  NSString   *aixUser;
  NSString   *aixPass;
  NSString   *symUser;
  BOOL        keepAlive;
  NSThread   *keepAliveThread;
  int         keepAliveSeconds;
  int         timeout;
  BOOL        connected;
  BOOL        loggedIn;
  //Crappy ivar required for 32 bit Mac runtime...
  NSDate *lastActive;
}
//----------------------------------------------------------------------------------------------------------------------------------
//  PROPERTIES
//----------------------------------------------------------------------------------------------------------------------------------
/** Is session connected to server? */
@property (readonly) BOOL      connected;
/** Is session logged in to AIX and Symitar? */
@property (readonly) BOOL      loggedIn;
/** IP/Hostname of Symitar server. */
@property (readonly) NSString *server;
/** Symitar institution number. */
@property (readonly) int       institution;
/** AIX user name. */
@property (readonly) NSString *aixUser;
/** AIX user password. */
@property (readonly) NSString *aixPass;
/** Symitar user ID. */
@property (readonly) NSString *symUser;
/** Last activity time for this session. */
@property (assign)   NSDate   *lastActive;
/** Default command timeout, in milliseconds. */
@property (assign)   int       timeout;
/** Attempt to keep session from timing out? */
@property (assign)   BOOL      keepAlive;
/** Keep-alive packet sending interval, in seconds. */
@property (assign)   int       keepAliveSeconds;
//----------------------------------------------------------------------------------------------------------------------------------
//  CONSTRUCTORS
//----------------------------------------------------------------------------------------------------------------------------------
/** Basic constructor. */
+ sessionForServer:(NSString *) Server
           aixUser:(NSString *) AixUser
           aixPass:(NSString *) AixPass
           symUser:(NSString *) SymUser
       institution:(int)        Institution;

/** Extra-options constructor. */
+ sessionForServer:(NSString *) Server
              port:(int)        Port
           aixUser:(NSString *) AixUser
           aixPass:(NSString *) AixPass
            prompt:(NSString *) Prompt
           symUser:(NSString *) SymUser
       institution:(int)        Institution;

/** Constructor. */
- initForServer:(NSString *) Server
              port:(int)        Port
           aixUser:(NSString *) AixUser
           aixPass:(NSString *) AixPass
            prompt:(NSString *) Prompt
           symUser:(NSString *) SymUser
       institution:(int)        Institution;
//----------------------------------------------------------------------------------------------------------------------------------
//  PUBLIC
//----------------------------------------------------------------------------------------------------------------------------------
/**
 String consisting of Symitar ID, Server IP/Hostname, and Institution Number.
 
 Suitable for comparison to other sessions (used this way by equalTo:).
 */
- (NSString *)toString;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Are two sessions comparable?
 
 @param other Session to compare to.
 */
- (BOOL) equalTo:(SYMSession *)other;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
- (SYMSession *)copyWithZone:(NSZone *)zone;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Copy/Clone a session and optionally login.
 
 @param login Immediately login?
 */
- (SYMSession *)copyAndLogin:(BOOL)login;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Connect to server.
 
 Establishes telnet connection **only**.
 */
- (SYMError) connect;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Disconnect from server.
 
 Will attempt to logout, if currently logged in.
 */
- (SYMError) disconnect;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Login to both AIX and Symitar.
 */
- (SYMError) login;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Login to AIX only.
 */
- (SYMError) loginAix;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Login to Symitar.
 
 This should only be called after a successful call to loginAix.
 */
- (SYMError) loginSym;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Send a wakeup packet.
 
 This is the packet used for keep-alive functionality.
 */
- (void)     wakeUp;

//----------------------------------------------------------------------------------------------------------------------------------
//  PROTECTED
//----------------------------------------------------------------------------------------------------------------------------------
/** Convert NSString to NSData, as needed for reading/writing. */
+ (NSData        *) encodeStringData :(NSString      *)string;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Convert NSString to bytes, as needed for reading/writing. */
+ (unsigned char *) encodeStringBytes:(NSString      *)string getLength:(int *)length;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Convert NSData to NSString, as needed for reading/writing. */
+ (NSString      *) decodeStringData :(NSData        *)data;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Convert bytes to NSString, as needed for reading/writing. */
+ (NSString      *) decodeStringBytes:(unsigned char *)bytes  ofLength :(int  )length;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/** Write to Symitar session stream. */
- (void) writeString :(NSString      *)string;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeString :(NSString      *)string   andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeCommand:(SYMCommand    *)command;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeCommand:(SYMCommand    *)command  andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeData   :(NSData        *)data;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeData   :(NSData        *)data     andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeData   :(NSData        *)data   fromOffset:(int)offset ofLength:(int)length;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeData   :(NSData        *)data   fromOffset:(int)offset ofLength:(int)length  andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeBytes  :(unsigned char *)bytes  fromOffset:(int)offset ofLength:(int)length;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Write to Symitar session stream. */
- (void) writeBytes  :(unsigned char *)bytes  fromOffset:(int)offset ofLength:(int)length  andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/** Read from Symitar session stream. */
- (NSString      *) readStringOfLength:(int)length;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Read from Symitar session stream. */
- (NSString      *) readStringOfLength:(int)length andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Read from Symitar session stream. */
- (SYMCommand    *) readCommand;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Read from Symitar session stream. */
- (SYMCommand    *) readCommandAndWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Read from Symitar session stream. */
- (NSData        *) readDataOfLength  :(int)length;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Read from Symitar session stream. */
- (NSData        *) readDataOfLength  :(int)length andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Read from Symitar session stream. */
- (unsigned char *) readBytesOfLength :(int)length;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Read from Symitar session stream. */
- (unsigned char *) readBytesOfLength :(int)length andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/** Wait to read expected data from Symitar stream. */
- (NSString *) expectString :(NSString      *)string;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Wait to read expected data from Symitar stream. */
- (NSString *) expectString :(NSString      *)string   andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Wait to read expected data from Symitar stream. */
- (NSString *) expectStrings:(NSArray       *)strings;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Wait to read expected data from Symitar stream. */
- (NSString *) expectStrings:(NSArray       *)strings  andWait:(int)milliseconds;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Wait to read expected data from Symitar stream. */
- (NSString *) expectBytes  :(unsigned char *)bytes  ofLength:(int)length;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/** Wait to read expected data from Symitar stream. */
- (NSString *) expectBytes  :(unsigned char *)bytes  ofLength:(int)length  andWait:(int)milliseconds;

//----------------------------------------------------------------------------------------------------------------------------------
//  PRIVATE
//----------------------------------------------------------------------------------------------------------------------------------
//lock/unlock for use at the protocol level, not during single read/write/expect operations
/** Attempt to lock session (for connection/login/category-level functions). */
- (BOOL) lock;
/** Attempt to lock session (for connection/login/category-level functions). */
- (BOOL) lockWait:(int)milliseconds;
/** Unlock session. */
- (void) unlock;

- (void) update; //categories shouldn't call this; handled by read/write functions
- (void) keepAliveStart;
- (void) keepAliveStop;
- (void) keepAliveRun;

//----------------------------------------------------------------------------------------------------------------------------------
@end
//==================================================================================================================================
