//==================================================================================================================================
//  SYMSession+AccountManager.h
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
#import "iSym.h"

//----------------------------------------------------------------------------------------------------------------------------------
//  SYMSession - Account Manager Category
//----------------------------------------------------------------------------------------------------------------------------------
@interface SYMSession (AccountManager)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Set the current account number.
 
 First enters Account Manager mode, then loads the given account as current for this session.
 
 @param account The account/member number to load.
 */
- (SYMError) AccountManager_loadAccount:(NSString *)account;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Starts a demand HtmlView specfile.
 
 Begins execution of the given HtmlView specfile on the currently loaded account.
 A current account must have been previously loaded with AccountManager_loadAccount:.
 
 @param specfile The name of the specfile (installed for demand use) to run.
 @return On succcess, returns specfile output (HTML); On error, returns `nil`.
 */
- (NSString *) AccountManager_demandHtmlBegin:(NSString *)specfile;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/**
 Completes a demand HtmlView specfile.
 
 Completes execution of the given HtmlView specfile, writing back any specified form data as key-value pairs.
 
 @param values Dictionary of key-value pairs to pass back to the specfile.
 */
- (SYMError) AccountManager_demandHtmlComplete:(NSDictionary *)values;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@end
