
undefined8 FUN_140001e20(int param_1,undefined8 param_2,undefined8 param_3,undefined8 param_4)

{
  FILE *pFVar1;
  
  FUN_140001ce4();
  if (param_1 == 0) {
    pFVar1 = FUN_140003af8(1);
    FUN_1400013cc(pFVar1,0x2751,param_3,param_4);
  }
  else if (param_1 == 1) {
    pFVar1 = FUN_140003af8(1);
    FUN_1400013cc(pFVar1,0x2750,param_3,param_4);
    return 1;
  }
  return 0;
}

