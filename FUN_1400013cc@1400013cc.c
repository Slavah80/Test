
void FUN_1400013cc(FILE *param_1,DWORD param_2,undefined8 param_3,undefined8 param_4)

{
  DWORD DVar1;
  undefined8 local_res18;
  undefined8 local_res20;
  undefined8 *local_18;
  wchar_t *local_10;
  
  local_18 = &local_res18;
  local_res18 = param_3;
  local_res20 = param_4;
  DVar1 = FormatMessageW(0x900,DAT_140006698,param_2,0,(LPWSTR)&local_10,0,(va_list *)&local_18);
  if (DVar1 != 0) {
    FUN_1400011bc(param_1,local_10);
  }
  return;
}

