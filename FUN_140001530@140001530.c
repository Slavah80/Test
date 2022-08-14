
/* WARNING: Could not reconcile some variable overlaps */

bool FUN_140001530(uint param_1,longlong param_2,undefined2 *param_3,longlong param_4,short *param_5
                  ,undefined8 param_6,char param_7)

{
  short sVar1;
  int iVar2;
  short *psVar3;
  longlong lVar4;
  longlong lVar5;
  bool bVar6;
  longlong local_res20;
  undefined local_48 [16];
  undefined local_38 [16];
  undefined local_28 [16];
  
  local_48._4_12_ = ZEXT412(param_1);
  local_48._0_4_ = 4;
  *param_5 = 0;
  local_38 = ZEXT816(0);
  local_28 = ZEXT816(0);
  local_res20 = param_4;
  iVar2 = GetAddrInfoW(param_2,0,local_48,&local_res20);
  if (iVar2 == 0) {
    FUN_1400014a8(param_1,local_res20,param_3);
    if (param_7 != '\0') {
      GetNameInfoW(param_3,DAT_140007760,param_5,0x401,0,0,4);
    }
    FreeAddrInfoW(local_res20);
    bVar6 = true;
  }
  else {
    local_48 = CONCAT124(local_48._4_12_,2);
    iVar2 = GetAddrInfoW(param_2,0,local_48,&local_res20);
    if (iVar2 == 0) {
      FUN_1400014a8(param_1,local_res20,param_3);
      lVar4 = 0x401;
      if (*(longlong *)(local_res20 + 0x18) != 0) {
        param_2 = *(longlong *)(local_res20 + 0x18);
      }
      lVar5 = param_2 - (longlong)param_5;
      do {
        if ((lVar4 == -0x7ffffbfd) || (sVar1 = *(short *)(lVar5 + (longlong)param_5), sVar1 == 0))
        break;
        *param_5 = sVar1;
        param_5 = param_5 + 1;
        lVar4 = lVar4 + -1;
      } while (lVar4 != 0);
      bVar6 = lVar4 != 0;
      psVar3 = param_5 + -1;
      if (bVar6) {
        psVar3 = param_5;
      }
      *psVar3 = 0;
      FreeAddrInfoW(local_res20);
    }
    else {
      bVar6 = false;
    }
  }
  return bVar6;
}

