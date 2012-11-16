//==================================================================================================================================
//  SYMError.h
//  part of the iSym library
//  Copyright 2012 Dillon Aumiller
//==================================================================================================================================
typedef enum
{
  SYMError_None             =    0,
  SYMError_InUse            =    1,
  SYMError_CantConnect      =    2,
  SYMError_CantClose        =    3,
  SYMError_NotConnected     =    4,
  SYMError_SendError        =    5,
  SYMError_ReceiveError     =    6,
  SYMError_BadAixLogin      =    7,
  SYMError_BadSymitarInst   =    8,
  SYMError_BadSymitarId     =    9,
  SYMError_TooManyAttempts  =   10,
  SYMError_Protocol         =   11,
  SYMError_InvalidParameter =   12,
  SYMError_FileNotFound     =   13,
  SYMError_Unspecified      = 4095
} SYMError;
//==================================================================================================================================
