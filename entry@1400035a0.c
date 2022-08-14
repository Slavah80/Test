
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

ulonglong entry(void)

{
  bool bVar1;
  int iVar2;
  BOOL BVar3;
  ulonglong uVar4;
  longlong *plVar5;
  longlong in_GS_OFFSET;
  bool bVar6;
  
  FUN_1400039d4();
  uVar4 = *(ulonglong *)(*(longlong *)(in_GS_OFFSET + 0x30) + 8);
  bVar1 = false;
  do {
    iVar2 = DAT_1400076c8;
    LOCK();
    bVar6 = DAT_1400076c0 == 0;
    DAT_1400076c0 = DAT_1400076c0 ^ (ulonglong)bVar6 * (DAT_1400076c0 ^ uVar4);
    if (bVar6) {
LAB_140003411:
      if (DAT_1400076c8 == 1) {
        _amsg_exit(0x1f);
      }
      else if (DAT_1400076c8 == 0) {
        DAT_1400076c8 = 1;
        for (plVar5 = &DAT_140004458; plVar5 < &DAT_140004470; plVar5 = plVar5 + 1) {
          if (iVar2 != 0) {
            return 0xff;
          }
          if (*plVar5 != 0) {
            iVar2 = (*(code *)PTR__guard_dispatch_icall_140004430)();
          }
        }
        if (iVar2 != 0) {
          return 0xff;
        }
      }
      else {
        _DAT_1400060e4 = 1;
      }
      if (DAT_1400076c8 == 1) {
        _initterm(&DAT_140004440,&DAT_140004450);
        DAT_1400076c8 = 2;
      }
      if (!bVar1) {
        DAT_1400076c0 = 0;
      }
      if ((DAT_1400076d0 != 0) &&
         (BVar3 = _IsNonwritableInCurrentImage((PBYTE)&DAT_1400076d0), BVar3 != 0)) {
        (*(code *)PTR__guard_dispatch_icall_140004430)(0,2);
      }
      uVar4 = FUN_140002000(DAT_1400060e8,DAT_1400060f0);
      DAT_1400060e0 = (uint)uVar4;
      if (_DAT_140006100 == 0) {
                    /* WARNING: Subroutine does not return */
        exit(DAT_1400060e0);
      }
      if (_DAT_1400060e4 == 0) {
        _cexit();
        uVar4 = (ulonglong)DAT_1400060e0;
      }
      return uVar4;
    }
    if (!bVar6 * DAT_1400076c0 == uVar4) {
      bVar1 = true;
      goto LAB_140003411;
    }
    Sleep(1000);
  } while( true );
}

