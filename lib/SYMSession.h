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

  NSDate *lastActive;
}
//----------------------------------------------------------------------------------------------------------------------------------
//  PROPERTIES
//----------------------------------------------------------------------------------------------------------------------------------
@property (readonly) BOOL      connected;
@property (readonly) BOOL      loggedIn;
@property (readonly) NSString *server;
@property (readonly) int       institution;
@property (readonly) NSString *aixUser;
@property (readonly) NSString *aixPass;
@property (readonly) NSString *symUser;
@property (assign)   NSDate   *lastActive;
@property (assign)   int       timeout;
@property (assign)   BOOL      keepAlive;
@property (assign)   int       keepAliveSeconds;
//----------------------------------------------------------------------------------------------------------------------------------
//  CONSTRUCTORS
//----------------------------------------------------------------------------------------------------------------------------------
+ sessionForServer:(NSString *) Server
           aixUser:(NSString *) AixUser
           aixPass:(NSString *) AixPass
           symUser:(NSString *) SymUser
       institution:(int)        Institution;

+ sessionForServer:(NSString *) Server
              port:(int)        Port
           aixUser:(NSString *) AixUser
           aixPass:(NSString *) AixPass
            prompt:(NSString *) Prompt
           symUser:(NSString *) SymUser
       institution:(int)        Institution;

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
- (NSString *)toString;
- (BOOL) equalTo:(SYMSession *)other;

- (SYMSession *)copyWithZone:(NSZone *)zone;
- (SYMSession *)copyAndLogin:(BOOL)login;

- (SYMError) connect;
- (SYMError) disconnect;
- (SYMError) login;
- (SYMError) loginAix;
- (SYMError) loginSym;
- (void)     wakeUp;

//----------------------------------------------------------------------------------------------------------------------------------
//  PUBLIC: PROTOCOL: ACCOUNT MANAGER
//----------------------------------------------------------------------------------------------------------------------------------
- (SYMError)   AccountManager_LoadAccount:(NSString *)account;
- (NSString *) AccountManager_DemandHtml_Begin:(NSString *)specfile;
- (SYMError)   AccountManager_DemandHtml_Complete:(NSDictionary *)values;

//----------------------------------------------------------------------------------------------------------------------------------
//  PROTECTED
//----------------------------------------------------------------------------------------------------------------------------------
+ (NSData        *) encodeStringData :(NSString      *)string;
+ (unsigned char *) encodeStringBytes:(NSString      *)string getLength:(int *)length;
+ (NSString      *) decodeStringData :(NSData        *)data;
+ (NSString      *) decodeStringBytes:(unsigned char *)bytes  ofLength :(int  )length;

- (void) writeString :(NSString      *)string;
- (void) writeString :(NSString      *)string   andWait:(int)milliseconds;
- (void) writeCommand:(SYMCommand    *)command;
- (void) writeCommand:(SYMCommand    *)command  andWait:(int)milliseconds;
- (void) writeData   :(NSData        *)data;
- (void) writeData   :(NSData        *)data     andWait:(int)milliseconds;
- (void) writeData   :(NSData        *)data   fromOffset:(int)offset ofLength:(int)length;
- (void) writeData   :(NSData        *)data   fromOffset:(int)offset ofLength:(int)length  andWait:(int)milliseconds;
- (void) writeBytes  :(unsigned char *)bytes  fromOffset:(int)offset ofLength:(int)length;
- (void) writeBytes  :(unsigned char *)bytes  fromOffset:(int)offset ofLength:(int)length  andWait:(int)milliseconds;

- (NSString      *) readStringOfLength:(int)length;
- (NSString      *) readStringOfLength:(int)length andWait:(int)milliseconds;
- (SYMCommand    *) readCommand;
- (SYMCommand    *) readCommandAndWait:(int)milliseconds;
- (NSData        *) readDataOfLength  :(int)length;
- (NSData        *) readDataOfLength  :(int)length andWait:(int)milliseconds;
- (unsigned char *) readBytesOfLength :(int)length;
- (unsigned char *) readBytesOfLength :(int)length andWait:(int)milliseconds;

- (NSString *) expectString :(NSString      *)string;
- (NSString *) expectString :(NSString      *)string   andWait:(int)milliseconds;
- (NSString *) expectStrings:(NSArray       *)strings;
- (NSString *) expectStrings:(NSArray       *)strings  andWait:(int)milliseconds;
- (NSString *) expectBytes  :(unsigned char *)bytes  ofLength:(int)length;
- (NSString *) expectBytes  :(unsigned char *)bytes  ofLength:(int)length  andWait:(int)milliseconds;

//----------------------------------------------------------------------------------------------------------------------------------
//  PRIVATE
//----------------------------------------------------------------------------------------------------------------------------------
//lock/unlock for use at the protocol level, not during single read/write/expect operations
- (BOOL) lock;
- (BOOL) lockWait:(int)milliseconds;
- (void) unlock;

- (void) update;
- (void) keepAliveStart;
- (void) keepAliveStop;
- (void) keepAliveRun;

//----------------------------------------------------------------------------------------------------------------------------------
@end
//==================================================================================================================================
