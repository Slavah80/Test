
undefined4 FUN_140003888(undefined4 param_1)

{
  HMODULE pHVar1;
  int *piVar2;
  
  pHVar1 = GetModuleHandleW((LPCWSTR)0x0);
  if ((pHVar1 != (HMODULE)0x0) && (piVar2 = FUN_14000382c((short *)pHVar1), piVar2 != (int *)0x0)) {
    if (*(short *)(piVar2 + 0x17) == 2) {
      return 2;
    }
    if (*(short *)(piVar2 + 0x17) == 3) {
      return 1;
    }
  }
  return param_1;
}

