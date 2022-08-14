
ulonglong FUN_140001e74(void)

{
  LSTATUS LVar1;
  undefined4 extraout_var;
  undefined4 extraout_var_00;
  undefined4 extraout_var_01;
  ulonglong uVar2;
  byte bVar3;
  int local_res8 [2];
  DWORD local_res10 [2];
  DWORD local_res18 [2];
  HKEY local_res20;
  
  local_res20 = (HKEY)0x0;
  local_res8[0] = 0;
  local_res10[0] = 4;
  LVar1 = RegOpenKeyExW((HKEY)0xffffffff80000002,
                        L"SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters",0,1,&local_res20);
  uVar2 = CONCAT44(extraout_var,LVar1);
  if (LVar1 == 0) {
    LVar1 = RegQueryValueExW(local_res20,L"DefaultTTL",(LPDWORD)0x0,local_res18,(LPBYTE)local_res8,
                             local_res10);
    uVar2 = CONCAT44(extraout_var_00,LVar1);
  }
  bVar3 = 0x80;
  if (local_res8[0] != 0) {
    bVar3 = (byte)local_res8[0];
  }
  if (local_res20 != (HKEY)0x0) {
    LVar1 = RegCloseKey(local_res20);
    uVar2 = CONCAT44(extraout_var_01,LVar1);
  }
  return uVar2 & 0xffffffffffffff00 | (ulonglong)bVar3;
}

