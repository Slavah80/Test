
DWORD FUN_1400010fc(FILE *param_1,undefined4 *param_2)

{
  int _FileHandle;
  DWORD DVar1;
  BOOL BVar2;
  HANDLE hFile;
  undefined4 uVar3;
  DWORD local_res18 [4];
  
  _FileHandle = _fileno(param_1);
  hFile = (HANDLE)_get_osfhandle(_FileHandle);
  if (hFile == (HANDLE)0xffffffffffffffff) {
    return 6;
  }
  DVar1 = GetFileType(hFile);
  uVar3 = 0;
  if (DVar1 == 0) {
    DVar1 = GetLastError();
    if (DVar1 != 0) {
      DVar1 = GetLastError();
      return DVar1;
    }
  }
  else if (((DVar1 & 0xffff7fff) == 2) &&
          ((BVar2 = GetConsoleMode(hFile,local_res18), BVar2 != 0 ||
           (DVar1 = GetLastError(), DVar1 != 6)))) {
    uVar3 = 1;
  }
  *param_2 = uVar3;
  return 0;
}

