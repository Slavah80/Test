
/* WARNING: Could not reconcile some variable overlaps */

bool FUN_140001f28(uint param_1,undefined8 param_2,void *param_3)

{
  int iVar1;
  longlong local_res20;
  undefined local_38 [16];
  undefined local_28 [16];
  undefined local_18 [16];
  
  local_38 = CONCAT124(ZEXT412(param_1),1);
  local_28 = ZEXT816(0);
  local_18 = ZEXT816(0);
  iVar1 = GetAddrInfoW(param_2,0,local_38,&local_res20);
  if (iVar1 == 0) {
                    /* [BAD 1] memcpy */
    memcpy(param_3,*(void **)(local_res20 + 0x20),*(size_t *)(local_res20 + 0x10));
  }
  return iVar1 == 0;
}
