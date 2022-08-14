
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 FUN_140003290(void)

{
  int iVar1;
  longlong lVar2;
  
  if ((IMAGE_DOS_HEADER_140000000.e_magic == 0x5a4d) &&
     (lVar2 = (longlong)(int)IMAGE_DOS_HEADER_140000000.e_lfanew,
     *(int *)(IMAGE_DOS_HEADER_140000000.e_magic + lVar2) == 0x4550)) {
    if (*(short *)((longlong)IMAGE_DOS_HEADER_140000000.e_res_4_ + lVar2 + -4) == 0x10b) {
      _DAT_140006100 = 0;
      if (*(uint *)(IMAGE_DOS_HEADER_140000000.e_program + lVar2 + 0x34) < 0xf) goto LAB_1400032f9;
      iVar1 = *(int *)(&UNK_1400000e8 + lVar2);
    }
    else {
      if (*(short *)((longlong)IMAGE_DOS_HEADER_140000000.e_res_4_ + lVar2 + -4) != 0x20b)
      goto LAB_1400032a2;
      _DAT_140006100 = 0;
      if (*(uint *)(&UNK_140000080.field_0x4 + lVar2) < 0xf) goto LAB_1400032f9;
      iVar1 = *(int *)(IMAGE_NT_HEADERS64_1400000f0.Signature + lVar2 + 8);
    }
    _DAT_140006100 = (uint)(iVar1 != 0);
  }
  else {
LAB_1400032a2:
    _DAT_140006100 = 0;
  }
LAB_1400032f9:
  iVar1 = FUN_140003888(1);
  __set_app_type(iVar1);
  _DAT_1400076b0 = 0xffffffffffffffff;
  _DAT_1400076b8 = 0xffffffffffffffff;
  *(undefined4 *)_fmode_exref = DAT_14000668c;
  *(undefined4 *)_commode_exref = DAT_140006680;
  FUN_1400038e0();
  if (_DAT_140006000 == 0) {
    __setusermatherr(FUN_140003ab0);
  }
  return 0;
}

