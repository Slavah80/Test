
void FUN_1400014a8(int param_1,longlong param_2,undefined2 *param_3)

{
  short *psVar1;
  
  psVar1 = *(short **)(param_2 + 0x20);
  if (((((*psVar1 == 0x17) && (param_1 == 0)) && (psVar1[4] == 0)) &&
      ((psVar1[5] == 0 && (psVar1[6] == 0)))) &&
     ((psVar1[7] == 0 && ((psVar1[8] == 0 && (psVar1[9] == -1)))))) {
    *param_3 = 2;
    *(undefined4 *)(param_3 + 2) = *(undefined4 *)(psVar1 + 10);
    param_3[1] = psVar1[1];
    DAT_140007760 = 0x10;
    return;
  }
  DAT_140007760 = *(undefined4 *)(param_2 + 0x10);
                    /* [BAD 1] memcpy */
  memcpy(param_3,*(void **)(param_2 + 0x20),*(size_t *)(param_2 + 0x10));
  return;
}

