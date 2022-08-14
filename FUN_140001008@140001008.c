
void FUN_140001008(undefined4 *param_1)

{
  DWORD DVar1;
  int iVar2;
  undefined auStack216 [32];
  WCHAR local_b8 [80];
  ulonglong local_18;
  
  local_18 = DAT_140006008 ^ (ulonglong)auStack216;
  DVar1 = GetEnvironmentVariableW(L"OutputEncoding",local_b8,0x50);
  *param_1 = 1;
  if ((DVar1 - 1 < 0x4e) && (iVar2 = _wcsicmp(local_b8,L"Unicode"), iVar2 != 0)) {
    iVar2 = _wcsicmp(local_b8,L"Ansi");
    if (iVar2 == 0) {
      *param_1 = 0;
    }
    else {
      iVar2 = _wcsicmp(local_b8,L"UTF8");
      if ((iVar2 == 0) || (iVar2 = _wcsicmp(local_b8,L"UTF-8"), iVar2 == 0)) {
        *param_1 = 0xfde9;
      }
    }
  }
  FUN_1400035d0(local_18 ^ (ulonglong)auStack216);
  return;
}

