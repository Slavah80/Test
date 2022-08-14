
undefined * FUN_14000143c(undefined8 param_1)

{
  int iVar1;
  undefined *puVar2;
  undefined4 local_res10 [6];
  
  local_res10[0] = 0x7ff;
  iVar1 = GetIpErrorString(param_1,&DAT_1400066b0,local_res10);
  puVar2 = &DAT_1400066b0;
  if (iVar1 != 0) {
    puVar2 = &DAT_140004530;
  }
  return puVar2;
}

