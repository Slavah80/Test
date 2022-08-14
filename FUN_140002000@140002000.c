
/* WARNING: Could not reconcile some variable overlaps */

void FUN_140002000(uint param_1,longlong param_2)

{
  char *pcVar1;
  char cVar2;
  ushort uVar3;
  bool bVar4;
  bool bVar5;
  char cVar6;
  byte bVar7;
  DWORD DVar8;
  int iVar9;
  uint uVar10;
  NET_IF_COMPARTMENT_ID CompartmentId;
  NTSTATUS NVar11;
  int iVar12;
  FILE *pFVar13;
  undefined *puVar14;
  ulonglong uVar15;
  undefined7 extraout_var;
  undefined7 extraout_var_00;
  HANDLE IcmpHandle;
  ushort *puVar16;
  char *hMem;
  undefined4 *puVar17;
  FILE *pFVar18;
  uint uVar19;
  undefined8 uVar20;
  char *pcVar21;
  ushort **ppuVar22;
  undefined4 *puVar23;
  ushort **ppuVar24;
  ushort **ppuVar25;
  uint uVar26;
  ushort *puVar27;
  DWORD *pDVar28;
  undefined2 *puVar29;
  ushort *puVar30;
  ushort **ppuVar31;
  ulonglong uVar32;
  ushort **ppuVar33;
  undefined auStackY2680 [32];
  undefined8 in_stack_fffffffffffff5b0;
  byte local_a17;
  char local_a16;
  uint local_a14;
  uint local_a10;
  ulonglong local_a08;
  ulonglong local_a00;
  undefined8 local_9f8;
  ushort *local_9f0;
  uint local_9e8;
  uint local_9e4;
  uint local_9e0;
  uint local_9dc;
  undefined4 local_9d8;
  undefined4 local_9d4;
  undefined8 local_9d0;
  undefined4 local_9c8;
  undefined *local_9c0;
  undefined4 *local_9b8;
  undefined local_9b0;
  undefined local_9af;
  byte local_9ae;
  char local_9ad;
  undefined *local_9a8;
  ushort *local_998 [16];
  FILE local_918 [3];
  undefined local_888 [48];
  short local_858 [1032];
  ulonglong local_48;
  
  local_48 = DAT_140006008 ^ (ulonglong)auStackY2680;
  ppuVar24 = (ushort **)0x0;
  local_9e0 = 4;
  local_a08 = 0;
  local_9dc = 0;
  local_9f8 = (char *)((ulonglong)local_9f8 & 0xffffffff00000000);
  ppuVar25 = (ushort **)0x1;
  uVar26 = 1;
  local_a16 = '\0';
  local_9c0 = (undefined *)0x0;
  cVar2 = '\0';
  local_a10 = 0;
  local_9c8 = 0;
  local_a17 = 0;
  local_9d4 = 4000;
  local_9b8 = (undefined4 *)0x0;
  local_9e8 = 0x20;
  local_a00 = local_a00 & 0xffffffff00000000;
  bVar4 = false;
  SetThreadUILanguage(0);
  puVar30 = (ushort *)0x0;
  HeapSetInformation((HANDLE)0x0,HeapEnableTerminationOnCorruption,(PVOID)0x0,0);
  pFVar13 = FUN_140003af8(1);
  DVar8 = FUN_1400010fc(pFVar13,&local_9e4);
  if ((DVar8 == 0) && (local_9e4 == 0)) {
    iVar9 = FUN_140001008(&local_9e4);
    if (iVar9 == 0) {
      if (((local_9e4 == 0xfde9) && (iVar9 = fgetpos(pFVar13,&local_9d0), iVar9 == 0)) &&
         (CONCAT44(local_9d0._4_4_,(undefined4)local_9d0) == 0)) {
        iVar9 = _fileno(pFVar13);
        _setmode(iVar9,0x8000);
        iVar9 = _fileno(pFVar13);
        _write(iVar9,&DAT_14000452c,3);
      }
    }
    else {
      iVar9 = fgetpos(pFVar13,&local_9d0);
      if ((iVar9 == 0) && (CONCAT44(local_9d0._4_4_,(undefined4)local_9d0) == 0)) {
        iVar9 = _fileno(pFVar13);
        _setmode(iVar9,0x20000);
        fwprintf(pFVar13,L"");
      }
    }
  }
  uVar10 = WSAStartup(2,(LPWSADATA)&DAT_140007780);
  if (uVar10 != 0) {
    puVar14 = FUN_14000143c((ulonglong)uVar10);
    pFVar13 = FUN_140003af8(1);
    FUN_1400013cc(pFVar13,0x274a,puVar14,puVar30);
                    /* WARNING: Subroutine does not return */
    exit(1);
  }
                    /* [BAD 1] memset */
  memset(local_998,0,0x80);
                    /* [BAD 1] memset */
  memset(local_858,0,0x802);
  pFVar13 = local_918;
  puVar27 = (ushort *)0x82;
                    /* [BAD 1] memset */
  memset(pFVar13,0,0x82);
  uVar15 = FUN_140001e74();
  uVar20 = 2;
  local_9e4 = local_9e4 & 0xffffff00 | (uint)(byte)uVar15;
  if ((int)param_1 < 2) {
LAB_140002245:
    FUN_140001480(pFVar13,uVar20,puVar27,puVar30);
    uVar26 = 1;
    goto LAB_140003262;
  }
  puVar30 = (ushort *)0xfffd;
  ppuVar22 = ppuVar25;
  ppuVar33 = ppuVar24;
  if (1 < param_1) {
    do {
      iVar9 = 2;
      local_9f0 = *(ushort **)(param_2 + (longlong)ppuVar22 * 8);
      if ((((*local_9f0 - 0x2d & 0xfffd) == 0) &&
          ((((uVar3 = local_9f0[1], iVar12 = iVar9, uVar3 == 0x34 || (iVar12 = 0x17, uVar3 == 0x36))
            || ((uVar3 == 0x52 || (iVar12 = iVar9, uVar3 == 0x66)))) ||
           ((0x69 < uVar3 &&
            ((uVar3 < 0x6c || ((0x71 < uVar3 && ((uVar3 < 0x74 || (uVar3 == 0x76)))))))))))) &&
         (uVar20 = FUN_140001f9c((int *)&local_a00,iVar12,local_9f0), (char)uVar20 == '\0'))
      goto LAB_140003262;
      puVar30 = (ushort *)0xfffd;
      uVar10 = (int)ppuVar22 + 1;
      ppuVar22 = (ushort **)(ulonglong)uVar10;
    } while (uVar10 < param_1);
    ppuVar33 = (ushort **)(local_a00 & 0xffffffff);
    if ((uint)local_a00 == 2) {
      uVar20 = 0;
      local_9d0._0_4_ = 0;
      iVar9 = GetIpForwardTable(0,&local_9d0);
      if (iVar9 != 0x7a) {
        pFVar13 = FUN_140003af8(1);
        FUN_1400013cc(pFVar13,0x275c,uVar20,puVar30);
                    /* WARNING: Subroutine does not return */
        exit(1);
      }
    }
  }
  puVar27 = (ushort *)0x6b;
  ppuVar22 = ppuVar25;
  if (1 < param_1) {
LAB_14000235e:
    puVar27 = (ushort *)0x6b;
    uVar10 = (uint)ppuVar22;
    puVar30 = &DAT_1400076e0;
    puVar16 = *(ushort **)(param_2 + (longlong)ppuVar22 * 8);
    local_9f0 = puVar16;
    if ((*puVar16 - 0x2d & 0xfffd) != 0) {
      if ((uint)local_9f8 != 0) {
        pFVar13 = FUN_140003af8(1);
        DVar8 = 0x271c;
        puVar16 = local_9f0;
        goto LAB_14000291c;
      }
      puVar27 = &DAT_1400076e0;
      bVar5 = FUN_140001530((uint)ppuVar33,(longlong)puVar16,&DAT_1400076e0,(longlong)&DAT_1400076e0
                            ,local_858,in_stack_fffffffffffff5b0,local_a16);
      if ((!bVar5) || ((DAT_1400076e0 == 2 && (DAT_1400076e4 == -1)))) {
        pFVar13 = FUN_140003af8(1);
        DVar8 = 0x271d;
        puVar16 = local_9f0;
        goto LAB_14000291c;
      }
      local_9f8 = (char *)CONCAT44(local_9f8._4_4_,1);
      local_9f8._0_4_ = 1;
      local_9dc = uVar10;
      goto LAB_1400028e5;
    }
    uVar3 = puVar16[1];
    puVar30 = (ushort *)(longlong)(int)local_a10;
    uVar19 = (uint)uVar3;
    ppuVar31 = (ushort **)puVar30;
    if (uVar3 < 0x6b) {
      if (uVar3 == 0x6a) {
        if ((int)ppuVar24 == 0) {
          if (0x28 < (int)(local_a10 + 3)) goto LAB_14000297e;
          cVar2 = cVar2 + '\x03';
          local_9c0 = &DAT_140007920;
          *(ushort *)((longlong)puVar30 + 0x140007920) = 899;
          *(undefined *)((longlong)puVar30 + 0x140007922) = 4;
LAB_140002613:
          uVar10 = (uint)ppuVar22;
          if (uVar10 < param_1 - 2) {
            puVar16 = *(ushort **)(param_2 + (ulonglong)(uVar10 + 1) * 8);
            if (*puVar16 == 0x2d) goto LAB_1400028c3;
            if (0x24 < (int)(local_a10 + 3)) goto LAB_14000297e;
            ppuVar22 = (ushort **)(ulonglong)(uVar10 + 1);
            local_9f0 = puVar16;
            do {
              ppuVar24 = (ushort **)&local_9d8;
              puVar27 = (ushort *)&local_9f0;
              iVar9 = RtlIpv4StringToAddressW();
              if (iVar9 < 0) goto LAB_14000296d;
              ppuVar31 = (ushort **)(ulonglong)local_a10;
              cVar2 = cVar2 + '\x04';
              *(undefined4 *)
               (&DAT_140007920 + (*(byte *)((longlong)puVar30 + 0x140007921) + local_a10)) =
                   local_9d8;
              *(char *)((longlong)puVar30 + 0x140007921) =
                   *(char *)((longlong)puVar30 + 0x140007921) + '\x04';
              puVar27 = (ushort *)(ulonglong)*local_9f0;
              if (*local_9f0 == 0) goto LAB_140002613;
              do {
                iVar9 = iswctype((wint_t)puVar27,8);
                if (iVar9 == 0) break;
                local_9f0 = local_9f0 + 1;
                puVar27 = (ushort *)(ulonglong)*local_9f0;
              } while (*local_9f0 != 0);
            } while (*local_9f0 != 0);
            ppuVar31 = (ushort **)(ulonglong)local_a10;
            goto LAB_140002613;
          }
          goto LAB_1400028c3;
        }
LAB_14000298f:
        pFVar13 = FUN_140003af8(1);
        DVar8 = 0x273d;
        goto LAB_14000325a;
      }
      if ((uVar19 != 0x34) && (uVar19 != 0x36)) {
        if (uVar19 - 0x3f == 0) {
          FUN_140001480((ulonglong)(uVar19 - 0x3f),2,0x6b,puVar30);
                    /* WARNING: Subroutine does not return */
          exit(0);
        }
        if (uVar19 == 0x52) {
          local_a17 = local_a17 | 1;
        }
        else {
          if (uVar19 == 0x53) {
            if (uVar10 == param_1 - 1) {
              pFVar13 = FUN_140003af8(1);
LAB_140002934:
              DVar8 = 0x2711;
            }
            else {
              ppuVar33 = (ushort **)(local_a00 & 0xffffffff);
              puVar27 = (ushort *)local_998;
              uVar10 = uVar10 + 1;
              bVar5 = FUN_140001f28((uint)local_a00,*(undefined8 *)(param_2 + (ulonglong)uVar10 * 8)
                                    ,puVar27);
              if ((int)CONCAT71(extraout_var,bVar5) != 0) {
                local_a08 = (ulonglong)uVar10;
                goto LAB_1400028e5;
              }
              pFVar13 = FUN_140003af8(1);
              DVar8 = 0x2754;
              puVar16 = *(ushort **)(param_2 + (ulonglong)uVar10 * 8);
            }
            goto LAB_14000291c;
          }
          if (uVar19 != 0x61) {
            if (uVar19 == 99) {
              if (uVar10 == param_1 - 1) {
                pFVar13 = FUN_140003af8(1);
                puVar16 = local_9f0;
                goto LAB_140002934;
              }
              puVar30 = (ushort *)0x0;
              CompartmentId = FUN_1400016a8(param_2,param_1,uVar10,0,0xffffffff);
              NVar11 = SetCurrentThreadCompartmentId(CompartmentId);
              if (NVar11 != 0) {
                DVar8 = 0x271a;
                if (NVar11 == 5) {
                  DVar8 = 0x275d;
                }
                pFVar13 = FUN_140003af8(1);
                puVar16 = local_9f0;
                goto LAB_14000291c;
              }
            }
            else {
              if (uVar19 == 0x66) {
                local_a17 = local_a17 | 2;
                goto LAB_1400028d4;
              }
              if (uVar19 != 0x69) {
LAB_1400029a0:
                pFVar13 = FUN_140003af8(1);
                uVar20 = 0x271b;
                puVar27 = local_9f0;
                FUN_1400013cc(pFVar13,0x271b,local_9f0,puVar30);
                goto LAB_140002245;
              }
              puVar30 = (ushort *)ppuVar25;
              local_9e4 = FUN_1400016a8(param_2,param_1,uVar10,1,0xff);
            }
            goto LAB_140002467;
          }
          local_a16 = '\x01';
        }
      }
    }
    else if (uVar19 == 0x6b) {
      if ((int)ppuVar24 != 0) goto LAB_14000298f;
      if (0x28 < (int)(local_a10 + 3)) goto LAB_14000297e;
      cVar2 = cVar2 + '\x03';
      local_9c0 = &DAT_140007920;
      *(ushort *)((longlong)puVar30 + 0x140007920) = 0x389;
      *(undefined *)((longlong)puVar30 + 0x140007922) = 4;
LAB_1400028ba:
      uVar10 = (uint)ppuVar22;
      if (uVar10 < param_1 - 2) {
        puVar16 = *(ushort **)(param_2 + (ulonglong)(uVar10 + 1) * 8);
        if (*puVar16 == 0x2d) goto LAB_1400028c3;
        if (0x24 < (int)(local_a10 + 3)) goto LAB_14000297e;
        ppuVar22 = (ushort **)(ulonglong)(uVar10 + 1);
        local_9f0 = puVar16;
        do {
          ppuVar24 = (ushort **)&local_9d8;
          puVar27 = (ushort *)&local_9f0;
          iVar9 = RtlIpv4StringToAddressW();
          if (iVar9 < 0) goto LAB_14000296d;
          ppuVar31 = (ushort **)(ulonglong)local_a10;
          cVar2 = cVar2 + '\x04';
          *(undefined4 *)(&DAT_140007920 + (*(byte *)((longlong)puVar30 + 0x140007921) + local_a10))
               = local_9d8;
          *(char *)((longlong)puVar30 + 0x140007921) =
               *(char *)((longlong)puVar30 + 0x140007921) + '\x04';
          puVar27 = (ushort *)(ulonglong)*local_9f0;
          if (*local_9f0 == 0) goto LAB_1400028ba;
          do {
            iVar9 = iswctype((wint_t)puVar27,8);
            if (iVar9 == 0) break;
            local_9f0 = local_9f0 + 1;
            puVar27 = (ushort *)(ulonglong)*local_9f0;
          } while (*local_9f0 != 0);
        } while (*local_9f0 != 0);
        ppuVar31 = (ushort **)(ulonglong)local_a10;
        goto LAB_1400028ba;
      }
LAB_1400028c3:
      local_a10 = (int)ppuVar31 + (uint)*(byte *)((longlong)puVar30 + 0x140007921);
      ppuVar31 = (ushort **)(ulonglong)local_a10;
      ppuVar24 = ppuVar25;
    }
    else {
      if (uVar19 == 0x6c) {
        puVar30 = (ushort *)0x0;
        local_9e8 = FUN_1400016a8(param_2,param_1,uVar10,0,0xffdc);
        goto LAB_140002467;
      }
      if (uVar19 != 0x6e) {
        if (uVar19 == 0x70) {
          ppuVar33 = (ushort **)(local_a00 & 0xffffffff);
          bVar4 = true;
          goto LAB_1400028e5;
        }
        if (uVar19 == 0x72) {
          if ((int)(local_a10 + 3) < 0x29) {
            *(undefined *)((longlong)puVar30 + 0x140007920) = 7;
            *(undefined *)((longlong)puVar30 + 0x140007922) = 4;
            local_9c0 = &DAT_140007920;
            ppuVar31 = ppuVar25;
            cVar6 = FUN_1400016a8(param_2,param_1,uVar10,1,9);
            bVar7 = cVar6 * '\x04' + 3;
            local_a10 = local_a10 + bVar7;
            puVar27 = (ushort *)ppuVar22;
            if ((int)local_a10 < 0x29) {
LAB_140002708:
              uVar10 = uVar10 + 1;
              cVar2 = cVar2 + bVar7;
              *(byte *)((longlong)puVar30 + 0x140007921) = bVar7;
              puVar27 = (ushort *)ppuVar22;
              goto LAB_1400028d4;
            }
          }
        }
        else {
          if (uVar19 != 0x73) {
            if (uVar19 == 0x74) {
              local_9e0 = 0xffffffff;
              goto LAB_1400028d4;
            }
            if (uVar19 == 0x76) {
              puVar30 = (ushort *)0x0;
              local_9c8 = FUN_1400016a8(param_2,param_1,uVar10,0,0xff);
            }
            else {
              if (uVar19 != 0x77) goto LAB_1400029a0;
              puVar30 = (ushort *)0x0;
              local_9d4 = FUN_1400016a8(param_2,param_1,uVar10,0,0xffffffff);
            }
            goto LAB_140002467;
          }
          if ((int)(local_a10 + 4) < 0x29) {
            *(undefined *)((longlong)puVar30 + 0x140007920) = 0x44;
            *(undefined *)((longlong)puVar30 + 0x140007922) = 5;
            local_9c0 = &DAT_140007920;
            cVar6 = FUN_1400016a8(param_2,param_1,uVar10,1,4);
            bVar7 = cVar6 * '\b' + 4;
            local_a10 = local_a10 + bVar7;
            ppuVar31 = (ushort **)(ulonglong)local_a10;
            puVar27 = (ushort *)ppuVar22;
            if ((int)local_a10 < 0x29) {
              *(undefined *)((longlong)puVar30 + 0x140007923) = 1;
              goto LAB_140002708;
            }
          }
        }
LAB_14000297e:
        pFVar13 = FUN_140003af8(1);
        DVar8 = 0x2747;
        puVar30 = (ushort *)ppuVar31;
        goto LAB_14000325a;
      }
      puVar30 = (ushort *)ppuVar25;
      local_9e0 = FUN_1400016a8(param_2,param_1,uVar10,1,0xffffffff);
LAB_140002467:
      uVar10 = uVar10 + 1;
      puVar27 = (ushort *)ppuVar22;
      ppuVar31 = (ushort **)puVar30;
    }
LAB_1400028d4:
    ppuVar33 = (ushort **)(local_a00 & 0xffffffff);
    puVar30 = (ushort *)ppuVar31;
LAB_1400028e5:
    ppuVar22 = (ushort **)(ulonglong)(uVar10 + 1);
    if (param_1 <= uVar10 + 1) goto LAB_1400029bd;
    goto LAB_14000235e;
  }
LAB_14000324e:
  pFVar13 = FUN_140003af8(1);
  DVar8 = 0x271e;
LAB_14000325a:
  FUN_1400013cc(pFVar13,DVar8,puVar27,puVar30);
LAB_140003262:
  WSACleanup();
                    /* WARNING: Subroutine does not return */
  exit(uVar26);
LAB_14000296d:
  pFVar13 = FUN_140003af8(1);
  DVar8 = 0x2714;
  puVar30 = (ushort *)ppuVar24;
  goto LAB_14000325a;
LAB_1400029bd:
  if ((uint)local_9f8 == 0) goto LAB_14000324e;
  if ((((int)ppuVar33 != 0) || ((ushort)local_998[0] == 0)) ||
     ((ushort)local_998[0] == DAT_1400076e0)) {
LAB_140002a30:
    uVar10 = (uint)DAT_1400076e0;
    local_9dc = uVar10;
    if (uVar10 == 2) {
      if (bVar4) {
LAB_140002a4e:
        IcmpHandle = (HANDLE)InternalIcmpCreateFileEx();
      }
      else {
        IcmpHandle = IcmpCreateFile();
      }
    }
    else {
      if (bVar4) goto LAB_140002a4e;
      IcmpHandle = (HANDLE)Icmp6CreateFile();
    }
    uVar19 = local_9e8;
    if (IcmpHandle == (HANDLE)0xffffffffffffffff) {
      DVar8 = GetLastError();
      puVar16 = (ushort *)FUN_14000143c((ulonglong)DVar8);
      pFVar13 = FUN_140003af8(1);
      DVar8 = 0x271f;
LAB_14000291c:
      FUN_1400013cc(pFVar13,DVar8,puVar16,puVar30);
    }
    else {
      hMem = (char *)LocalAlloc(0,(ulonglong)local_9e8);
      local_9f8 = hMem;
      if (hMem == (char *)0x0) {
        pFVar13 = FUN_140003af8(1);
        FUN_1400013cc(pFVar13,0x2748,puVar27,puVar30);
        puVar17 = local_9b8;
        uVar26 = 1;
      }
      else {
        uVar26 = 0x1ff8;
        if (0x20 < uVar19) {
          uVar26 = 0x10047;
        }
        local_a00 = (ulonglong)uVar26;
        puVar17 = (undefined4 *)LocalAlloc(0,(ulonglong)uVar26);
        local_9b8 = puVar17;
        if (puVar17 == (undefined4 *)0x0) {
          pFVar13 = FUN_140003af8(1);
          FUN_1400013cc(pFVar13,0x2748,puVar27,puVar30);
          uVar26 = 1;
        }
        else {
          uVar32 = 0;
          uVar15 = uVar32;
          pcVar21 = hMem;
          if (uVar19 != 0) {
            do {
              uVar26 = (int)uVar15 + 1;
              *pcVar21 = (char)uVar15 + (char)(uVar15 / 0x17) * -0x17 + 'a';
              uVar15 = (ulonglong)uVar26;
              pcVar21 = pcVar21 + 1;
            } while (uVar26 < uVar19);
          }
          local_9a8 = local_9c0;
          local_9b0 = (undefined)local_9e4;
          local_9af = (undefined)local_9c8;
          local_9ae = local_a17;
          pFVar13 = (FILE *)0x41;
          local_9ad = cVar2;
          iVar9 = GetNameInfoW(&DAT_1400076e0,DAT_140007760,local_918);
          if (iVar9 != 0) {
                    /* [BAD 1] memset */
            memset(local_918,0,0x82);
          }
          if (local_858[0] == 0) {
            pFVar18 = FUN_140003af8(1);
            FUN_1400013cc(pFVar18,0x274b,local_918,pFVar13);
          }
          else {
            pFVar18 = FUN_140003af8(1);
            pFVar13 = local_918;
            FUN_1400013cc(pFVar18,0x2720,local_858,pFVar13);
          }
          if (((ushort)local_998[0] == 0x17) || ((ushort)local_998[0] == 2)) {
            uVar20 = 0x1c;
            if ((ushort)local_998[0] == 2) {
              uVar20 = 0x10;
            }
            pFVar13 = (FILE *)0x41;
            iVar9 = GetNameInfoW(local_998,uVar20,local_918);
            if (iVar9 != 0) {
                    /* [BAD 1] memset */
              memset(local_918,0,0x82);
            }
            pFVar18 = FUN_140003af8(1);
            FUN_1400013cc(pFVar18,0x2759,local_918,pFVar13);
          }
          pFVar18 = FUN_140003af8(1);
          FUN_1400013cc(pFVar18,0x275a,(ulonglong)uVar19,pFVar13);
          SetConsoleCtrlHandler(FUN_140001e20,1);
          local_a14 = 0;
          if (local_9e0 != 0) {
            uVar26 = local_9e0 - 1;
            do {
              puVar17 = local_9b8;
              uVar19 = (uint)uVar32;
              if (uVar10 == 2) {
                uVar20 = 0;
                pDVar28 = (DWORD *)0x0;
                iVar9 = IcmpSendEcho2Ex();
                DAT_140006690 = DAT_140006690 + 1;
                if (iVar9 == 0) {
                  uVar10 = GetLastError();
                  if (10999 < uVar10) {
                    uVar15 = 0;
                    if (DAT_140006020 != uVar10) {
                      pDVar28 = &DAT_140006020;
                      DVar8 = DAT_140006020;
                      do {
                        if (DVar8 == 0x2b2a) break;
                        uVar15 = (ulonglong)((int)uVar15 + 1);
                        DVar8 = (&DAT_140006020)[uVar15 * 2];
                      } while (DVar8 != uVar10);
                    }
                    goto LAB_1400030b8;
                  }
LAB_140003071:
                  puVar14 = FUN_14000143c((ulonglong)uVar10);
                  pFVar13 = FUN_140003af8(1);
                  FUN_1400013cc(pFVar13,0x2722,puVar14,uVar20);
LAB_1400030d4:
                  local_a14 = uVar19;
                  if (uVar19 < uVar26) {
                    DVar8 = 1000;
                    goto LAB_1400030e2;
                  }
                }
                else {
                  do {
                    puVar23 = puVar17;
                    local_9d0._0_4_ = *puVar23;
                    uVar20 = 0x16;
                    iVar9 = iVar9 + -1;
                    pDVar28 = (DWORD *)InetNtopW(2,&local_9d0,local_888);
                    pFVar13 = FUN_140003af8(1);
                    FUN_1400013cc(pFVar13,0x2723,pDVar28,uVar20);
                    if (puVar23[1] == 0) {
                      DAT_1400066a4 = DAT_1400066a4 + 1;
                      uVar3 = *(ushort *)(puVar23 + 3);
                      pFVar13 = FUN_140003af8(1);
                      uVar15 = (ulonglong)uVar3;
                      FUN_1400013cc(pFVar13,0x273c,uVar15,uVar20);
                      uVar32 = (ulonglong)local_9e8;
                      if (*(ushort *)(puVar23 + 3) == local_9e8) {
                        uVar10 = 0;
                        if (local_9e8 != 0) {
                          uVar15 = *(longlong *)(puVar23 + 4) - (longlong)hMem;
                          pcVar21 = hMem;
                          do {
                            cVar2 = *pcVar21;
                            pcVar1 = pcVar21 + uVar15;
                            pcVar21 = pcVar21 + 1;
                            if (cVar2 != *pcVar1) {
                              pFVar13 = FUN_140003af8(1);
                              DVar8 = 0x2725;
                              goto LAB_140002e67;
                            }
                            uVar10 = uVar10 + 1;
                          } while (uVar10 < local_9e8);
                        }
                      }
                      else {
                        pFVar13 = FUN_140003af8(1);
                        DVar8 = 0x2724;
                        uVar10 = local_9e8;
LAB_140002e67:
                        uVar15 = (ulonglong)uVar10;
                        FUN_1400013cc(pFVar13,DVar8,uVar15,uVar32);
                      }
                      uVar10 = puVar23[2];
                      pFVar13 = FUN_140003af8(1);
                      if (uVar10 == 0) {
                        FUN_1400013cc(pFVar13,0x2727,uVar15,uVar32);
                        DAT_1400060c0 = 0;
                      }
                      else {
                        FUN_1400013cc(pFVar13,0x2726,(ulonglong)uVar10,uVar32);
                        uVar10 = puVar23[2];
                        DAT_1400066a8 = DAT_1400066a8 + uVar10;
                        if (uVar10 < DAT_1400060c0) {
                          DAT_1400060c0 = uVar10;
                        }
                        if (DAT_1400066a0 < uVar10) {
                          DAT_1400066a0 = uVar10;
                        }
                      }
                      bVar7 = *(byte *)(puVar23 + 6);
                      pFVar13 = FUN_140003af8(1);
                      puVar29 = (undefined2 *)(ulonglong)bVar7;
                      FUN_1400013cc(pFVar13,0x2728,puVar29,uVar32);
                      if (*(char *)((longlong)puVar23 + 0x1b) != '\0') {
                        FUN_140001774((longlong)puVar23,local_a16,puVar29,uVar32);
                      }
                    }
                    else {
                      uVar15 = 0;
                      if (DAT_140006020 != 0x2b2a) {
                        pDVar28 = &DAT_140006020;
                        DVar8 = DAT_140006020;
                        do {
                          if (DVar8 == puVar23[1]) break;
                          uVar15 = (ulonglong)((int)uVar15 + 1);
                          DVar8 = (&DAT_140006020)[uVar15 * 2];
                        } while (DVar8 != 0x2b2a);
                      }
                      pFVar13 = FUN_140003af8(1);
                      FUN_1400013cc(pFVar13,(&DAT_140006024)[uVar15 * 2],pDVar28,uVar20);
                    }
                    DAT_140006694 = DAT_140006694 + 1;
                    puVar17 = puVar23 + 10;
                  } while (iVar9 != 0);
                  if ((local_a14 < uVar26) && ((uint)puVar23[2] < 1000)) {
                    Sleep(1000 - puVar23[2]);
                  }
                }
              }
              else {
                uVar20 = 0;
                pDVar28 = (DWORD *)0x0;
                iVar9 = Icmp6SendEcho2();
                DAT_140006690 = DAT_140006690 + 1;
                if (iVar9 == 0) {
                  uVar10 = GetLastError();
                  if (uVar10 < 11000) goto LAB_140003071;
                  uVar15 = 0;
                  if (DAT_140006020 != uVar10) {
                    pDVar28 = &DAT_140006020;
                    DVar8 = DAT_140006020;
                    do {
                      if (DVar8 == 0x2b2a) break;
                      uVar15 = (ulonglong)((int)uVar15 + 1);
                      DVar8 = (&DAT_140006020)[uVar15 * 2];
                    } while (DVar8 != uVar10);
                  }
LAB_1400030b8:
                  pFVar13 = FUN_140003af8(1);
                  FUN_1400013cc(pFVar13,(&DAT_140006024)[uVar15 * 2],pDVar28,uVar20);
                  goto LAB_1400030d4;
                }
                do {
                  puVar23 = puVar17;
                  uVar20 = 0x41;
                  iVar9 = iVar9 + -1;
                  iVar12 = GetNameInfoW(&DAT_1400076e0,DAT_140007760,local_918);
                  if (iVar12 != 0) {
                    /* [BAD 1] memset */
                    memset(local_918,0,0x82);
                  }
                  pFVar18 = FUN_140003af8(1);
                  pFVar13 = local_918;
                  FUN_1400013cc(pFVar18,0x2723,pFVar13,uVar20);
                  uVar15 = 0;
                  DVar8 = DAT_140006020;
                  if (puVar23[7] == 0) {
                    DAT_1400066a4 = DAT_1400066a4 + 1;
                    uVar10 = puVar23[8];
                    pFVar18 = FUN_140003af8(1);
                    if (uVar10 == 0) {
                      FUN_1400013cc(pFVar18,0x2727,pFVar13,uVar20);
                      DAT_1400060c0 = 0;
                    }
                    else {
                      pFVar13 = (FILE *)(ulonglong)uVar10;
                      FUN_1400013cc(pFVar18,0x2726,pFVar13,uVar20);
                      uVar10 = puVar23[8];
                      DAT_1400066a8 = DAT_1400066a8 + uVar10;
                      if (uVar10 < DAT_1400060c0) {
                        DAT_1400060c0 = uVar10;
                      }
                      if (DAT_1400066a0 < uVar10) {
                        DAT_1400066a0 = uVar10;
                      }
                    }
                    DVar8 = 0x273f;
                  }
                  else {
                    while ((DVar8 != 0x2b2a && (DVar8 != puVar23[7]))) {
                      uVar15 = (ulonglong)((int)uVar15 + 1);
                      DVar8 = (&DAT_140006020)[uVar15 * 2];
                    }
                    DVar8 = (&DAT_140006024)[uVar15 * 2];
                  }
                  pFVar18 = FUN_140003af8(1);
                  FUN_1400013cc(pFVar18,DVar8,pFVar13,uVar20);
                  DAT_140006694 = DAT_140006694 + 1;
                  puVar17 = puVar23 + 9;
                } while (iVar9 != 0);
                hMem = local_9f8;
                if ((uVar26 <= local_a14) || (999 < (uint)puVar23[8])) goto LAB_140002f7f;
                DVar8 = 1000 - puVar23[8];
LAB_1400030e2:
                Sleep(DVar8);
              }
LAB_140002f7f:
              local_a14 = local_a14 + 1;
              uVar32 = (ulonglong)local_a14;
              uVar10 = local_9dc;
            } while (local_a14 < local_9e0);
          }
          uVar26 = (uint)(DAT_140006694 == 0);
          FUN_140001ce4();
          puVar17 = local_9b8;
        }
      }
      IcmpCloseHandle(IcmpHandle);
      if (hMem != (char *)0x0) {
        LocalFree(hMem);
      }
      if (puVar17 != (undefined4 *)0x0) {
        LocalFree(puVar17);
      }
    }
    goto LAB_140003262;
  }
  puVar27 = (ushort *)local_998;
  bVar5 = FUN_140001f28((uint)DAT_1400076e0,*(undefined8 *)(param_2 + local_a08 * 8),puVar27);
  if ((int)CONCAT71(extraout_var_00,bVar5) != 0) goto LAB_140002a30;
  puVar27 = &DAT_1400076e0;
  bVar5 = FUN_140001530((uint)(ushort)local_998[0],*(longlong *)(param_2 + (ulonglong)local_9dc * 8)
                        ,&DAT_1400076e0,(longlong)puVar30,local_858,in_stack_fffffffffffff5b0,
                        local_a16);
  if (bVar5) goto LAB_140002a30;
  pFVar13 = FUN_140003af8(1);
  DVar8 = 0x275b;
  goto LAB_14000325a;
}

