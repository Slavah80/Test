
void FUN_1400039d4(void)

{
  DWORD DVar1;
  _FILETIME local_res8;
  _FILETIME local_res10;
  uint local_res18;
  undefined4 uStackX28;
  
  local_res10 = (_FILETIME)0x0;
  if (DAT_140006008 == 0x2b992ddfa232) {
    GetSystemTimeAsFileTime(&local_res10);
    local_res8 = local_res10;
    DVar1 = GetCurrentProcessId();
    local_res8 = (_FILETIME)((ulonglong)local_res8 ^ (ulonglong)DVar1);
    DVar1 = GetCurrentThreadId();
    local_res8 = (_FILETIME)((ulonglong)local_res8 ^ (ulonglong)DVar1);
    DVar1 = GetTickCount();
    local_res8 = (_FILETIME)((ulonglong)local_res8 ^ (ulonglong)DVar1 << 0x18);
    DVar1 = GetTickCount();
    local_res8 = (_FILETIME)((ulonglong)DVar1 ^ (ulonglong)local_res8 ^ (ulonglong)&local_res8);
    QueryPerformanceCounter((LARGE_INTEGER *)&local_res18);
    DAT_140006008 =
         ((ulonglong)local_res18 << 0x20 ^ CONCAT44(uStackX28,local_res18) ^ (ulonglong)local_res8)
         & 0xffffffffffff;
    if (DAT_140006008 == 0x2b992ddfa232) {
      DAT_140006008 = 0x2b992ddfa233;
    }
  }
  DAT_140006010 = ~DAT_140006008;
  return;
}

