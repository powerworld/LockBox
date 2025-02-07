(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is TurboPower LockBox
 *
 * The Initial Developer of the Original Code is
 * TurboPower Software
 *
 * Portions created by the Initial Developer are Copyright (C) 1997-2002
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * Roman Kassebaum
 *
 * ***** END LICENSE BLOCK ***** *)
{*********************************************************}
{*                  LBRANDOM.PAS 2.08                    *}
{*     Copyright (c) 2002 TurboPower Software Co         *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit LbRandom;

interface

uses
  Types, Classes, SysUtils, LbCipher;

{ TLbRandomGenerator }
type
  TLbRandomGenerator = class
  strict private
    RandCount : Integer;
    Seed : TMD5Digest;
    procedure ChurnSeed;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RandomBytes( var buff; len : DWORD );
  end;

{ TLbRanLFS }
type
  TLbRanLFS = class
  strict private
    ShiftRegister : DWORD;
    procedure SetSeed;
    function LFS : byte;
  public
    constructor Create;
    procedure FillBuf( var buff; len : DWORD );
  end;

implementation

{ TLbRandomGenerator }

constructor TLbRandomGenerator.create;
begin
  inherited Create;
  ChurnSeed;
end;

destructor TLbRandomGenerator.Destroy;
begin
  RandCount := 0;
  FillChar( Seed, SizeOf( Seed ), $00 );
  inherited Destroy;
end;

procedure TLbRandomGenerator.ChurnSeed;
var
  RandomSeed : array[ 0..15 ] of byte;
  Context : TMD5Context;
  lcg : TLbRanLFS; 
  i : integer;
begin
  lcg := TLbRanLFS.Create;
  try
{$PUSH}
{$WARN 5057 OFF}
    lcg.FillBuf( RandomSeed, SizeOf( RandomSeed ));
{$POP}
    for i := 0 to 4 do begin
      TMD5.InitMD5( Context );
      TMD5.UpdateMD5( Context, Seed, SizeOf( Seed ));
      TMD5.UpdateMD5( Context, RandomSeed, SizeOf( RandomSeed ));
      TMD5.FinalizeMD5( Context, Seed );
    end;
  finally
    lcg.Free;
  end;
end;
{ -------------------------------------------------------------------------- }
procedure TLbRandomGenerator.RandomBytes( var buff; len : DWORD );
var
  Context : TMD5Context;
  TmpDig : TMD5Digest;
  Index : DWORD;
  m : DWORD;
  SizeOfTmpDig : integer;
begin
  SizeOfTmpDig := SizeOf( TmpDig );
  Index := 0;

  if(( len - Index ) < 16 )then
    m := len - Index
  else
    m := SizeOfTmpDig;

  While Index < len do begin
    TMD5.InitMD5( Context );
    TMD5.UpdateMD5( Context, Seed, sizeof( Seed ));
    TMD5.UpdateMD5( Context, RandCount, sizeof( RandCount ));
    TMD5.FinalizeMD5( Context, TmpDig );

    inc( RandCount );
    move( tmpDig, TByteArray( buff )[ Index ], m );
    inc( Index, m );

    if(( len - Index ) < 16 )then
      m := len - Index
    else
      m := SizeOfTmpDig;
  end;
end;

{ TLbRanLFS }
constructor TLbRanLFS.Create;
begin
  inherited Create;
  SetSeed;
end;

procedure TLbRanLFS.FillBuf( var buff; len : DWORD );
var
  l : DWORD;
  b : byte;
  tmp_byt : byte;
begin
  for l := 0 to pred( len )do begin
    tmp_byt := 0;
    for b := 0 to 7 do begin
      tmp_byt := ( tmp_byt shl 1 ) or LFS;
    end;
    TByteArray( buff )[ l ] := tmp_byt;
  end;
end;

procedure TLbRanLFS.SetSeed;
var
  wHour, wMin, wSec, wMSec: Word;
  hold : integer;
begin
  hold := 1;
  while true do begin
    DecodeTime(Time, wHour, wMin, wSec, wMSec);
    ShiftRegister := hold;
    ShiftRegister := ( ShiftRegister shl ( hold and $0000000F )) xor
                     (( DWORD( wHour or wSec ) shl 16 ) or
                      ( DWORD( wMin or wMSec  )));
    hold := ShiftRegister;
    inc( hold );
    if( ShiftRegister <> 0 )then
      break;
  end;
end;
{ -------------------------------------------------------------------------- }
function TLbRanLFS.LFS : byte;
begin
  ShiftRegister := (((( ShiftRegister shr 31 ) xor
                      ( ShiftRegister shr 6  ) xor
                      ( ShiftRegister shr 4  ) xor
                      ( ShiftRegister shr 2  ) xor
                      ( ShiftRegister shr 1  ) xor
                      ( ShiftRegister )) and $00000001 ) shl 31 ) or
                      ( ShiftRegister shr 1 );
                   
  result := ShiftRegister and $00000001;
end;

end.
