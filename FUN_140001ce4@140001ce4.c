
void FUN_140001ce4(void)

{
  uint uVar1;
  FILE *pFVar2;
  int iVar3;
  undefined auStack232 [32];
  ulonglong local_c8;
  int local_c0;
  uint local_b8;
  undefined local_a8 [144];
  ulonglong local_18;
  
  local_18 = DAT_140006008 ^ (ulonglong)auStack232;
  if (DAT_140006690 != 0) {
    local_b8 = 2;
    local_c0 = 0;
    if (DAT_1400060c0 == 0xffffffff) {
      DAT_1400060c0 = 0;
    }
    local_c8 = 0;
    GetNameInfoW(&DAT_1400076e0,DAT_140007760,local_a8);
    iVar3 = DAT_140006690 - DAT_140006694;
    uVar1 = (uint)(iVar3 * 100) / DAT_140006690;
    pFVar2 = FUN_140003af8(1);
    local_c8 = local_c8 & 0xffffffff00000000 | (ulonglong)DAT_140006694;
    local_c0 = iVar3;
    local_b8 = uVar1;
    FUN_1400013cc(pFVar2,0x274f,local_a8,(ulonglong)DAT_140006690);
    if (DAT_1400066a4 != 0) {
      uVar1 = DAT_1400066a8 / DAT_1400066a4;
      pFVar2 = FUN_140003af8(1);
      local_c8 = local_c8 & 0xffffffff00000000 | (ulonglong)uVar1;
      FUN_1400013cc(pFVar2,0x2753,(ulonglong)DAT_1400060c0,(ulonglong)DAT_1400066a0);
    }
  }
  FUN_1400035d0(local_18 ^ (ulonglong)auStack232);
  return;
}

