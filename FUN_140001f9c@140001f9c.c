
ulonglong FUN_140001f9c(int *param_1,int param_2,undefined8 param_3)

{
  undefined8 in_RAX;
  FILE *pFVar1;
  ulonglong uVar2;
  wchar_t *pwVar3;
  
  if ((*param_1 == 0) || (*param_1 == param_2)) {
    *param_1 = param_2;
    uVar2 = CONCAT71((int7)((ulonglong)in_RAX >> 8),1);
  }
  else {
    pwVar3 = L"IPv6";
    if (param_2 == 2) {
      pwVar3 = L"IPv4";
    }
    pFVar1 = FUN_140003af8(1);
    uVar2 = FUN_1400013cc(pFVar1,0x2755,param_3,pwVar3);
    uVar2 = uVar2 & 0xffffffffffffff00;
  }
  return uVar2;
}

