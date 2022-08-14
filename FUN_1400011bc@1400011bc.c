
void FUN_1400011bc(FILE *param_1,wchar_t *param_2)

{
  UINT UVar1;
  DWORD DVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  wchar_t *pwVar6;
  LPSTR lpMultiByteStr;
  UINT local_res18 [2];
  
  local_res18[0] = 1;
  iVar3 = 0;
  lpMultiByteStr = (LPSTR)0x0;
  fflush(param_1);
  DVar2 = FUN_1400010fc(param_1,local_res18);
  UVar1 = local_res18[0];
  if ((DVar2 != 0) || (local_res18[0] != 0)) {
    iVar3 = _fileno(param_1);
    iVar3 = _setmode(iVar3,0x20000);
  }
  iVar4 = FUN_140001008(local_res18);
  if (UVar1 == 0) {
    pwVar6 = wcschr(param_2,L'\r');
    if (pwVar6 == (wchar_t *)0x0) {
      iVar5 = _fileno(param_1);
      iVar3 = (-(uint)(iVar4 != 0) & 0x1c000) + 0x4000;
    }
    else {
      iVar5 = _fileno(param_1);
      iVar3 = 0x8000;
    }
    iVar3 = _setmode(iVar5,iVar3);
    if (iVar4 == 0) {
      iVar4 = WideCharToMultiByte(local_res18[0],0,param_2,-1,(LPSTR)0x0,0,(LPCSTR)0x0,(LPBOOL)0x0);
      lpMultiByteStr = (LPSTR)0x0;
      if (iVar4 != 0) {
        lpMultiByteStr = (LPSTR)LocalAlloc(0x40,(longlong)iVar4);
        if (lpMultiByteStr != (LPSTR)0x0) {
          WideCharToMultiByte(local_res18[0],0,param_2,-1,lpMultiByteStr,iVar4,(LPCSTR)0x0,
                              (LPBOOL)0x0);
          iVar5 = _fileno(param_1);
          _write(iVar5,lpMultiByteStr,iVar4 - 1);
        }
      }
      goto LAB_140001369;
    }
  }
  fwprintf(param_1,L"%ls");
LAB_140001369:
  fflush(param_1);
  iVar4 = _fileno(param_1);
  _setmode(iVar4,iVar3);
  if (lpMultiByteStr != (LPSTR)0x0) {
    LocalFree(lpMultiByteStr);
  }
  return;
}

