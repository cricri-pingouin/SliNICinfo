Unit Unit1;

Interface

Uses
  SysUtils, Classes, Controls, Forms, WinSock, StdCtrls, Nb30;

Type
  TForm1 = Class(TForm)
    Memo1: TMemo;
    Procedure FormActivate(Sender: TObject);
  Private
    { Private declarations }
  Public
    { Public declarations }
  End;

Var
  Form1: TForm1;

Implementation

{$R *.dfm}
{$H+}

Function GetMACAdress: String;
Var
  NCB: PNCB;
  Adapter: PAdapterStatus;
  RetCode: char;
  i: integer;
  Lenum: PlanaEnum;
  _SystemID: String;
Begin
  Result := '';
  _SystemID := '';
  Getmem(NCB, SizeOf(TNCB));
  Fillchar(NCB^, SizeOf(TNCB), 0);
  Getmem(Lenum, SizeOf(TLanaEnum));
  Fillchar(Lenum^, SizeOf(TLanaEnum), 0);
  Getmem(Adapter, SizeOf(TAdapterStatus));
  Fillchar(Adapter^, SizeOf(TAdapterStatus), 0);
  Lenum.Length := chr(0);
  NCB.ncb_command := chr(NCBENUM);
  NCB.ncb_buffer := Pointer(Lenum);
  NCB.ncb_length := SizeOf(Lenum);
  RetCode := Netbios(NCB);
  i := 0;
  Repeat
    Fillchar(NCB^, SizeOf(TNCB), 0);
    NCB.ncb_command := chr(NCBRESET);
    NCB.ncb_lana_num := Lenum.lana[i];
    RetCode := Netbios(NCB);
    Fillchar(NCB^, SizeOf(TNCB), 0);
    NCB.ncb_command := chr(NCBASTAT);
    NCB.ncb_lana_num := Lenum.lana[i];
    // Must be 16
    NCB.ncb_callname := '*               ';
    NCB.ncb_buffer := Pointer(Adapter);
    NCB.ncb_length := SizeOf(TAdapterStatus);
    RetCode := Netbios(NCB);
    //---- calc _systemId from mac-address[2-5] XOR mac-address[1]...
    If (RetCode = chr(0)) Or (RetCode = chr(6)) Then
      _SystemID := IntToHex(Ord(Adapter.adapter_address[0]), 2) + '-' + IntToHex(Ord(Adapter.adapter_address[1]), 2) + '-' + IntToHex(Ord(Adapter.adapter_address[2]), 2) + '-' + IntToHex(Ord(Adapter.adapter_address[3]), 2) + '-' + IntToHex(Ord(Adapter.adapter_address[4]), 2) + '-' + IntToHex(Ord(Adapter.adapter_address[5]), 2);
    Inc(i);
  Until (i >= Ord(Lenum.Length)) Or (_SystemID <> '00-00-00-00-00-00');
  FreeMem(NCB);
  FreeMem(Adapter);
  FreeMem(Lenum);
  GetMacAdress := _SystemID;
End;

Function GetIPAddress: String;
Type
  TaPInAddr = Array[0..10] Of PInAddr;

  PaPInAddr = ^TaPInAddr;
Var
  phe: PHostEnt;
  pptr: PaPInAddr;
  Buffer: Array[0..63] Of Char;
  i: Integer;
  GInitData: TWSAData;
Begin
  WSAStartup($101, GInitData);
  Result := '';
  GetHostName(Buffer, SizeOf(Buffer));
  phe := GetHostByName(Buffer);
  If phe = nil Then
    Exit;
  pptr := PaPInAddr(phe^.h_addr_list);
  i := 0;
  While pptr^[i] <> nil Do
  Begin
    Result := Result + inet_ntoa(pptr^[i]^);
    Inc(i);
  End;
  WSACleanup;
End;

Function IPAddrToName(IPAddr: String): String;
Var
  SockAddrIn: TSockAddrIn;
  HostEnt: PHostEnt;
  WSAData: TWSAData;
Begin
  WSAStartup($101, WSAData);
  SockAddrIn.sin_addr.s_addr := inet_addr(PChar(IPAddr));
  HostEnt := gethostbyaddr(@SockAddrIn.sin_addr.S_addr, 4, AF_INET);
  If HostEnt <> nil Then
    Result := StrPas(HostEnt^.h_name)
  Else
    Result := '';
End;

Procedure TForm1.FormActivate(Sender: TObject);
Begin
  Memo1.Text := 'Computer name: ' + IPAddrToName(GetIPAddress) + #13#10 + 'IP address: ' + GetIPAddress + #13#10 + 'MAC address: ' + GetMACAdress;
End;

End.

