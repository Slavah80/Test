
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void FUN_140003630(undefined8 param_1)

{
  DWORD64 ControlPc;
  PRUNTIME_FUNCTION FunctionEntry;
  DWORD64 local_38;
  ulonglong local_30;
  PVOID local_28;
  undefined8 uStack32;
  undefined8 uStack24;
  
  RtlCaptureContext(&DAT_1400061b0);
  ControlPc = DAT_1400062a8;
  FunctionEntry = RtlLookupFunctionEntry(DAT_1400062a8,&local_38,(PUNWIND_HISTORY_TABLE)0x0);
  if (FunctionEntry == (PRUNTIME_FUNCTION)0x0) {
    DAT_1400062a8 = *DAT_140006248;
    DAT_140006248 = DAT_140006248 + 1;
  }
  else {
    RtlVirtualUnwind(0,local_38,ControlPc,FunctionEntry,(PCONTEXT)&DAT_1400061b0,&local_28,&local_30
                     ,(PKNONVOLATILE_CONTEXT_POINTERS)0x0);
  }
  _DAT_140006120 = DAT_1400062a8;
  _DAT_140006110 = 0xc0000409;
  _DAT_140006114 = 1;
  _DAT_140006128 = 3;
  DAT_140006130 = 2;
  DAT_140006138 = DAT_140006008;
  DAT_140006140 = DAT_140006010;
  uStack32 = DAT_140006008;
  uStack24 = DAT_140006010;
  _DAT_140006230 = param_1;
  __raise_securityfailure((_EXCEPTION_POINTERS *)&PTR_DAT_140004000);
  return;
}

