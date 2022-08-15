__int64 sub_7FF7A06B39F0(char *a1, __int64 a2, char *a3, ...)
{
  unsigned __int64 v4; // rbx
  unsigned int v5; // edi
  int v6; // eax
  __int64 result; // rax
  va_list Args; // [rsp+58h] [rbp+20h] BYREF

  va_start(Args, a3);
  if ( (unsigned __int64)(a2 - 1) > 0x7FFFFFFE )
  {
    result = 2147942487i64;
    if ( a2 )
      *(_WORD *)a1 = 0;
  }
  else
  {
    v4 = a2 - 1;
    v5 = 0;
    v6 = vsnwprintf(a1, a2 - 1, a3, Args);
    if ( v6 < 0 || v6 > v4 )
    {
      *(_WORD *)&a1[2 * v4] = 0;
      return (unsigned int)-2147024774;
    }
    else if ( v6 == v4 )
    {
      *(_WORD *)&a1[2 * v4] = 0;
    }
    return v5;
  }
  return result;
}
