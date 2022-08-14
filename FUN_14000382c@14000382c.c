
int * FUN_14000382c(short *param_1)

{
  int *piVar1;
  int *piVar2;
  
  piVar1 = (int *)0x0;
  piVar2 = piVar1;
  if (((((longlong)param_1 - 1U < 0xfffffffffffffffe) && (*param_1 == 0x5a4d)) &&
      (-1 < *(int *)(param_1 + 0x1e))) &&
     ((*(uint *)(param_1 + 0x1e) < 0x10000000 &&
      (piVar2 = (int *)((longlong)*(int *)(param_1 + 0x1e) + (longlong)param_1),
      *(int *)((longlong)*(int *)(param_1 + 0x1e) + (longlong)param_1) != 0x4550)))) {
    piVar2 = piVar1;
  }
  return piVar2;
}

