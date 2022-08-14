
void FUN_1400016a8(longlong param_1,int param_2,int param_3,ulonglong param_4,uint param_5)

{
  ulong uVar1;
  FILE *pFVar2;
  longlong lVar3;
  wchar_t *local_18 [2];
  
  lVar3 = (longlong)param_3;
  if (param_3 == param_2 + -1) {
    pFVar2 = FUN_140003af8(1);
    FUN_1400013cc(pFVar2,0x2711,*(undefined8 *)(param_1 + lVar3 * 8),param_4);
                    /* WARNING: Subroutine does not return */
    exit(1);
  }
  uVar1 = wcstoul(*(wchar_t **)(param_1 + 8 + lVar3 * 8),local_18,0);
  if (((uint)(param_4 & 0xffffffff) <= uVar1) && (uVar1 <= param_5)) {
    return;
  }
  pFVar2 = FUN_140003af8(1);
  FUN_1400013cc(pFVar2,0x2712,*(undefined8 *)(param_1 + lVar3 * 8),param_4 & 0xffffffff);
                    /* WARNING: Subroutine does not return */
  exit(1);
}

