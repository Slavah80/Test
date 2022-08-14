
/* WARNING: Could not reconcile some variable overlaps */

void FUN_140001774(longlong param_1,char param_2,undefined2 *param_3,undefined8 param_4)

{
  char cVar1;
  byte bVar2;
  undefined auVar3 [16];
  int iVar4;
  undefined8 uVar5;
  FILE *pFVar6;
  byte bVar7;
  DWORD DVar8;
  uint uVar9;
  char *pcVar10;
  char *pcVar11;
  byte bVar12;
  ulonglong uVar13;
  int iVar14;
  ulonglong uVar15;
  undefined auStack2280 [32];
  undefined8 local_8c8;
  undefined4 local_8c0;
  undefined4 local_8b8;
  char local_8a8;
  char local_8a7;
  byte local_8a6;
  byte local_8a5;
  char *local_8a0;
  undefined local_898 [4];
  undefined auStack2196 [4];
  undefined8 uStack2192;
  undefined local_888 [4];
  undefined auStack2180 [4];
  undefined8 uStack2176;
  undefined local_878 [48];
  undefined2 local_848 [1032];
  ulonglong local_38;
  
  local_38 = DAT_140006008 ^ (ulonglong)auStack2280;
  pcVar11 = *(char **)(param_1 + 0x20);
  pcVar10 = pcVar11 + *(byte *)(param_1 + 0x1b);
  local_8a8 = '\0';
  local_8a7 = param_2;
  local_8a0 = pcVar10;
LAB_14000185d:
  while( true ) {
    iVar14 = 0;
    if ((pcVar10 <= pcVar11) || (local_8a8 != '\0')) {
      FUN_1400035d0(local_38 ^ (ulonglong)auStack2280);
      return;
    }
    cVar1 = *pcVar11;
    if (cVar1 != '\0') break;
LAB_140001857:
    local_8a8 = '\x01';
  }
  if (cVar1 == '\x01') {
    pcVar11 = pcVar11 + 1;
    goto LAB_14000185d;
  }
  if (cVar1 != '\a') {
    if (cVar1 == 'D') {
      if (pcVar11 + 4 <= pcVar10) {
        bVar12 = pcVar11[2];
        bVar7 = pcVar11[1];
        uVar13 = (ulonglong)bVar7;
        local_8a5 = bVar7;
        if (bVar12 < 5) {
          pFVar6 = FUN_140003af8(1);
          FUN_1400013cc(pFVar6,0x2746,param_3,param_4);
          pcVar11 = pcVar11 + uVar13;
        }
        else {
          uVar15 = 5;
          local_8a6 = pcVar11[3] & 1;
          pFVar6 = FUN_140003af8(1);
          FUN_1400013cc(pFVar6,0x2745,param_3,param_4);
          bVar2 = local_8a6;
          cVar1 = local_8a7;
          param_3 = (undefined2 *)(ulonglong)(bVar7 + 1);
          bVar7 = bVar7 + 1;
          if ((uint)bVar12 <= bVar7 + 1) {
            bVar7 = bVar12;
          }
          if (8 < bVar7) {
            do {
              _local_898 = ZEXT816(0);
              if (iVar14 != 0) {
                pFVar6 = FUN_140003af8(1);
                FUN_1400013cc(pFVar6,0x2742,param_3,param_4);
                if (iVar14 == 1) {
                  pFVar6 = FUN_140003af8(1);
                  FUN_1400013cc(pFVar6,0x273f,param_3,param_4);
                  pFVar6 = FUN_140003af8(1);
                  FUN_1400013cc(pFVar6,0x274e,param_3,param_4);
                  iVar14 = 0;
                }
              }
              auVar3 = _local_898;
              iVar14 = iVar14 + 1;
              if (bVar2 != 0) {
                if ((uint)bVar7 < (int)uVar15 + 8U) break;
                _local_898 = CONCAT142(stack0xfffffffffffff76a,2);
                uStack2192 = SUB168(auVar3,8);
                _local_898 = (char *)CONCAT44(*(undefined4 *)(pcVar11 + (uVar15 - 1)),local_898);
                if (cVar1 == '\0') {
LAB_140001a2e:
                  param_4 = 0x16;
                  uVar5 = InetNtopW(2,auStack2196,local_878);
                  pFVar6 = FUN_140003af8(1);
                  FUN_1400013cc(pFVar6,0x2743,uVar5,param_4);
                }
                else {
                  local_8b8 = 4;
                  local_8c0 = 0;
                  local_8c8 = 0;
                  local_848[0] = 0;
                  iVar4 = GetNameInfoW(local_898,0x10,local_848,0x401);
                  if (iVar4 != 0) goto LAB_140001a2e;
                  param_4 = InetNtopW();
                  pFVar6 = FUN_140003af8(1);
                  FUN_1400013cc(pFVar6,0x274d,local_848,param_4);
                }
                uVar15 = (ulonglong)(byte)((char)uVar15 + 4);
              }
              uVar9 = *(uint *)(pcVar11 + (uVar15 - 1));
              uVar9 = (uVar9 >> 8 ^ uVar9 << 8) & 0xff00ff ^ uVar9 << 8;
              pFVar6 = FUN_140003af8(1);
              param_3 = (undefined2 *)(ulonglong)(uVar9 << 0x10 | uVar9 >> 0x10);
              FUN_1400013cc(pFVar6,0x2744,param_3,param_4);
              bVar12 = (char)uVar15 + 4;
              uVar15 = (ulonglong)bVar12;
            } while (bVar12 + 3 < (uint)bVar7);
            uVar13 = (ulonglong)local_8a5;
            pcVar10 = local_8a0;
          }
          pFVar6 = FUN_140003af8(1);
          FUN_1400013cc(pFVar6,0x273f,param_3,param_4);
          pcVar11 = pcVar11 + uVar13;
        }
        goto LAB_14000185d;
      }
      pFVar6 = FUN_140003af8(1);
      DVar8 = 0x2746;
      goto LAB_14000184d;
    }
    if (cVar1 == -0x7e) {
      pcVar11 = pcVar11 + 0xb;
      goto LAB_14000185d;
    }
    if (cVar1 != -0x7d) {
      if (cVar1 == -0x78) {
        pcVar11 = pcVar11 + 4;
      }
      else {
        if (cVar1 == -0x77) goto LAB_140001ad5;
        if (pcVar10 < pcVar11 + 2) goto LAB_140001857;
        pcVar11 = pcVar11 + (byte)pcVar11[1];
      }
      goto LAB_14000185d;
    }
  }
LAB_140001ad5:
  if (pcVar11 + 3 <= pcVar10) {
    bVar12 = pcVar11[1];
    _local_898 = pcVar11 + bVar12;
    if ((_local_898 <= pcVar10) && (2 < bVar12)) {
      bVar7 = pcVar11[2];
      if (bVar7 < 4) {
        pFVar6 = FUN_140003af8(1);
        DVar8 = 0x273e;
        pcVar11 = _local_898;
      }
      else {
        uVar13 = 4;
        pFVar6 = FUN_140003af8(1);
        FUN_1400013cc(pFVar6,0x2740,param_3,param_4);
        cVar1 = local_8a7;
        param_3 = (undefined2 *)(ulonglong)(bVar12 + 1);
        uVar9 = (uint)(byte)(bVar12 + 1);
        if ((uint)bVar7 <= bVar12 + 1) {
          uVar9 = (uint)bVar7;
        }
        if (7 < uVar9) {
          do {
            _local_888 = ZEXT816(0);
            if (iVar14 != 0) {
              pFVar6 = FUN_140003af8(1);
              FUN_1400013cc(pFVar6,0x2742,param_3,param_4);
              if (iVar14 == 1) {
                pFVar6 = FUN_140003af8(1);
                FUN_1400013cc(pFVar6,0x273f,param_3,param_4);
                pFVar6 = FUN_140003af8(1);
                FUN_1400013cc(pFVar6,0x2749,param_3,param_4);
                iVar14 = 0;
              }
            }
            auVar3 = _local_888;
            iVar14 = iVar14 + 1;
            _local_888 = CONCAT142(stack0xfffffffffffff77a,2);
            if (cVar1 == '\0') {
LAB_140001c76:
              param_4 = 0x16;
              param_3 = (undefined2 *)InetNtopW(2,auStack2180,local_878);
              pFVar6 = FUN_140003af8(1);
              FUN_1400013cc(pFVar6,0x2741,param_3,param_4);
            }
            else {
              local_8b8 = 4;
              local_8c0 = 0;
              local_8c8 = 0;
              local_848[0] = 0;
              iVar4 = GetNameInfoW(local_888,0x10,local_848);
              if (iVar4 != 0) goto LAB_140001c76;
              param_4 = InetNtopW();
              pFVar6 = FUN_140003af8(1);
              param_3 = local_848;
              FUN_1400013cc(pFVar6,0x274c,param_3,param_4);
            }
            bVar12 = (char)uVar13 + 4;
            uVar13 = (ulonglong)bVar12;
          } while (bVar12 + 3 < uVar9);
          pcVar10 = local_8a0;
        }
        pFVar6 = FUN_140003af8(1);
        DVar8 = 0x273f;
        pcVar11 = _local_898;
      }
      FUN_1400013cc(pFVar6,DVar8,param_3,param_4);
      goto LAB_14000185d;
    }
  }
  pFVar6 = FUN_140003af8(1);
  DVar8 = 0x273e;
LAB_14000184d:
  FUN_1400013cc(pFVar6,DVar8,param_3,param_4);
  goto LAB_140001857;
}

