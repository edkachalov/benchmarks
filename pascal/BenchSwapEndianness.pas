{$mode objfpc}{$H+}
{$inline on}
{$If Defined(CPU386) OR Defined(CPUX64)}
  {$ASMMODE intel}
{$EndIf}
{$SMARTLINK ON}
{$Calling Register}
{$CodeAlign proc=32}
{$CodeAlign loop=32}

uses stopwatch;

procedure SwapEndianSimple(var Buf: LongInt; Count: SizeUInt);
var
  aBuf: array [Byte] of LongInt absolute Buf;
  i: SizeUInt;
begin
  for i:= 1 to Count do
    aBuf[i]:= SwapEndian(aBuf[i]);
end;

procedure SwapEndianUnroll(var Buf: LongInt; Count: SizeUInt);
var
  aBuf: array [Byte] of LongInt absolute Buf;
  i, Top: SizeUInt;
begin
  Top:= Count and -4;
  i:= Low(aBuf);

  while i < Top do begin
    aBuf[i]:= SwapEndian(aBuf[i]);
    aBuf[i+1]:= SwapEndian(aBuf[i+1]);
    aBuf[i+2]:= SwapEndian(aBuf[i+2]);
    aBuf[i+3]:= SwapEndian(aBuf[i+3]);
    Inc(i, 4);
  end;

  if (Count and 2) <> 0 then begin
    aBuf[i]:= SwapEndian(aBuf[i]);
    aBuf[i+1]:= SwapEndian(aBuf[i+1]);
    Inc(i, 2);
  end;

  if (Count and 1) <> 0 then begin
    aBuf[i]:= SwapEndian(aBuf[i]);
  end;
end;

procedure SwapEndianBswap(var Buf: LongInt; Count: SizeUInt);assembler;nostackframe;
asm
  jmp   @Check

  align 16
@LP0:
{$IfDef Windows}
  mov   eax,[Buf+4*RDX]
  bswap eax
  mov   dword ptr [Buf+4*RDX],eax
{$Else}
  mov   eax,[Buf+4*RSI]
  bswap eax
  mov   dword ptr [Buf+4*RSI],eax
{$EndIf}

@Check:
  sub   Count, 1
  jnc   @LP0
end;

procedure SwapEndianBswapx2(var Buf: LongInt; Count: SizeUInt);assembler;nostackframe;
asm
  test  Count,1
  jz    @Check
  
{$IfDef Windows}
  mov   eax,[Buf+4*RDX]
  bswap eax
  mov   dword ptr [Buf+4*RDX],eax
{$Else}{UNIX}
  mov   eax,[Buf+4*RSI]
  bswap eax
  mov   dword ptr [Buf+4*RSI],eax
{$EndIf}
  dec   Count
  jmp   @Check

  align 16
@LP0:
{$IfDef Windows}
  mov   rax,[Buf+4*RDX]
  bswap rax
  ror   rax, 32
  mov   dword ptr [Buf+4*RDX],rax
{$Else}{UNIX}
  mov   rax,[Buf+4*RSI]
  bswap rax
  ror   rax, 32
  mov   dword ptr [Buf+4*RSI],rax
{$EndIf}

@Check:
  sub   Count, 2
  jnc   @LP0
end;

procedure SwapEndianSSSE3(var Buf: LongInt; Count: SizeUInt);assembler;nostackframe;
const
  CSwapOrder: array [0..15] of Byte = (3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12);
asm
{$If Defined(Windows)}
movuPS xmm4,rip[CSwapOrder]
cmp Count,16
 jb @LB08

align 32
@Big:
@LP0:
 movuPS xmm0,[Buf]
 movuPS xmm1,[Buf+16]
 movuPS xmm2,[Buf+32]
 movuPS xmm3,[Buf+48]
 pshufB xmm0,xmm4
 pshufB xmm1,xmm4
 pshufB xmm2,xmm4
 pshufB xmm3,xmm4
 movuPS [Buf],xmm0
 movuPS [Buf+16],xmm1
 movuPS [Buf+32],xmm2
 movuPS [Buf+48],xmm3
 sub Count,16
 add Buf,64
 cmp Count,16
  jae @LP0

@LB08:
test dl,8
 jz @LB04
movuPS xmm0,[Buf]
movuPS xmm1,[Buf+16]
pshufB xmm0,xmm4
pshufB xmm1,xmm4
movuPS [Buf],xmm0
movuPS [Buf+16],xmm1
add Buf,32

@LB04:
test dl,4
 jz @LB02
movuPS xmm0,[Buf]
pshufB xmm0,xmm4
movuPS [Buf],xmm0
add Buf,16

@LB02:
test dl,2
 jz @LB01
movQ xmm0,[Buf]
pshufB xmm0,xmm4
movQ [Buf],xmm0
add Buf,8

@LB01:
test dl,1
 jz @LB00
mov edi,dword ptr[Buf]
bswap edi
mov dword ptr[Buf],edi
@LB00:

@Fin:
{$Else}{UNIX}
movuPS xmm4,rip[CSwapOrder]
cmp Count,16
 jb @LB08

align 32
@Big:
@LP0:
 movuPS xmm0,[Buf]
 movuPS xmm1,[Buf+16]
 movuPS xmm2,[Buf+32]
 movuPS xmm3,[Buf+48]
 pshufB xmm0,xmm4
 pshufB xmm1,xmm4
 pshufB xmm2,xmm4
 pshufB xmm3,xmm4
 movuPS [Buf],xmm0
 movuPS [Buf+16],xmm1
 movuPS [Buf+32],xmm2
 movuPS [Buf+48],xmm3
 sub Count,16
 add Buf,64
 cmp Count,16
  jae @LP0

@LB08:
test si,8
 jz @LB04
movuPS xmm0,[Buf]
movuPS xmm1,[Buf+16]
pshufB xmm0,xmm4
pshufB xmm1,xmm4
movuPS [Buf],xmm0
movuPS [Buf+16],xmm1
add Buf,32

@LB04:
test si,4
 jz @LB02
movuPS xmm0,[Buf]
pshufB xmm0,xmm4
movuPS [Buf],xmm0
add Buf,16

@LB02:
test si,2
 jz @LB01
movQ xmm0,[Buf]
pshufB xmm0,xmm4
movQ [Buf],xmm0
add Buf,8

@LB01:
test si,1
 jz @LB00
mov eax,dword ptr[Buf]
bswap eax
mov dword ptr[Buf],eax
@LB00:

@Fin:
{$EndIf}
end;

procedure SwapEndianAVX2(var Buf: LongInt; Count: SizeUInt);assembler;nostackframe;
const
  CSwapOrder: array [0..31] of Byte =
  (3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12,
  19, 18, 17, 16, 23, 22, 21, 20, 27, 26, 25, 24, 31, 30, 29, 28);
asm
{$If Defined(Windows)}
vmovuPS ymm2,rip[CSwapOrder]
cmp Count,16
 jb @LB08

align 32
@Big:
@LP0:
 vmovuPS ymm0,[Buf]
 vmovuPS ymm1,[Buf+32]
 vpshufB ymm0,ymm0,ymm2
 vpshufB ymm1,ymm1,ymm2
 vmovuPS [Buf],ymm0
 vmovuPS [Buf+32],ymm1
 sub Count,16
 add Buf,64
 cmp Count,16
  jae @LP0

@LB08:
test dl,8
 jz @LB04
vmovuPS ymm0,[Buf]
vpshufB ymm0,ymm0,ymm2
vmovuPS [Buf],ymm0
add Buf,32

@LB04:
vzeroupper
test dl,4
 jz @LB02
movuPS xmm0,[Buf]
pshufB xmm0,xmm2
movuPS [Buf],xmm0
add Buf,16

@LB02:
test dl,2
 jz @LB01
movQ xmm0,[Buf]
pshufB xmm0,xmm2
movQ [Buf],xmm0
add Buf,8

@LB01:
test dl,1
 jz @LB00
mov edi,dword ptr[Buf]
bswap edi
mov dword ptr[Buf],edi
@LB00:

@Fin:
{$Else}{UNIX}
vmovuPS ymm2,rip[CSwapOrder]
cmp Count,16
 jb @LB08

align 32
@Big:
@LP0:
 vmovuPS ymm0,[Buf]
 vmovuPS ymm1,[Buf+32]
 vpshufB ymm0,ymm0,ymm2
 vpshufB ymm1,ymm1,ymm2
 vmovuPS [Buf],ymm0
 vmovuPS [Buf+32],ymm1
 sub Count,16
 add Buf,64
 cmp Count,16
  jae @LP0

@LB08:
test si,8
 jz @LB04
vmovuPS ymm0,[Buf]
vpshufB ymm0,ymm0,ymm2
vmovuPS [Buf],ymm0
add Buf,32

@LB04:
vzeroupper
test si,4
 jz @LB02
movuPS xmm0,[Buf]
pshufB xmm0,xmm2
movuPS [Buf],xmm0
add Buf,16

@LB02:
test si,2
 jz @LB01
movQ xmm0,[Buf]
pshufB xmm0,xmm2
movQ [Buf],xmm0
add Buf,8

@LB01:
test si,1
 jz @LB00
mov eax,dword ptr[Buf]
bswap eax
mov dword ptr[Buf],eax
@LB00:

@Fin:
{$EndIf}
end;

procedure SwapEndianAVX2x2(var Buf: LongInt; Count: SizeUInt);assembler;nostackframe;
const
  CSwapOrder: array [0..31] of Byte =
  (3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12,
  19, 18, 17, 16, 23, 22, 21, 20, 27, 26, 25, 24, 31, 30, 29, 28);
asm
vmovuPS ymm4,rip[CSwapOrder]
cmp Count,32
 jb @LB16

align 32
@LP0:
 vmovuPS ymm0,[Buf]
 vmovuPS ymm1,[Buf+32]
 vmovuPS ymm2,[Buf+64]
 vmovuPS ymm3,[Buf+96]
 vpshufB ymm0,ymm0,ymm4
 vpshufB ymm1,ymm1,ymm4
 vpshufB ymm2,ymm2,ymm4
 vpshufB ymm3,ymm3,ymm4
 vmovuPS [Buf],ymm0
 vmovuPS [Buf+32],ymm1
 vmovuPS [Buf+64],ymm2
 vmovuPS [Buf+96],ymm3
 sub Count,32
 add Buf,128
 cmp Count,32
  jae @LP0

@LB16:
test Count,16
 jz @LB08
vmovuPS ymm0,[Buf]
vmovuPS ymm1,[Buf+32]
vpshufB ymm0,ymm0,ymm4
vpshufB ymm1,ymm1,ymm4
vmovuPS [Buf],ymm0
vmovuPS [Buf+32],ymm1
add Buf,64

@LB08:
test Count,8
 jz @LB04
vmovuPS ymm0,[Buf]
vpshufB ymm0,ymm0,ymm4
vmovuPS [Buf],ymm0
add Buf,32

@LB04:
vzeroupper
test Count,4
 jz @LB02
movuPS xmm0,[Buf]
pshufB xmm0,xmm4
movuPS [Buf],xmm0
add Buf,16

@LB02:
test Count,2
 jz @LB01
movQ xmm0,[Buf]
pshufB xmm0,xmm4
movQ [Buf],xmm0
add Buf,8

@LB01:
test Count,1
 jz @LB00
mov edi,dword ptr[Buf]
bswap edi
mov dword ptr[Buf],edi
@LB00:

@Fin:
end;

const
  CSize = 1024 * 1024;
  {elements in L1 cache line}
  CCacheSize = (32 * 1024) div SizeOf(LongInt);
  CLoopItersSmall = 100;
  CLoopItersBig = 4;
var
  i: SizeInt;
  sw: TStopWatch;
  pL: PLongInt;
begin
  sw:= TStopWatch.Create;

  pL:= GetMem(CSize * SizeOf(LongInt));

  Writeln(CCacheSize, ' ELEMENTS BY ', CLoopItersSmall, ' RESULTS');

  FillDWord(pL^, CCacheSize, $01020304);{warm up the cache}

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    SwapEndianSimple(pL^, CCacheSize);
  sw.Stop;
  Writeln('Simple    : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    SwapEndianUnroll(pL^, CCacheSize);
  sw.Stop;
  Writeln('Unroll    : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    SwapEndianBswap(pL^, CCacheSize);
  sw.Stop;
  Writeln('Bswap     : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    SwapEndianBswapx2(pL^, CCacheSize);
  sw.Stop;
  Writeln('Bswapx2   : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    SwapEndianSSSE3(pL^, CCacheSize);
  sw.Stop;
  Writeln('SSSE3     : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    SwapEndianAVX2(pL^, CCacheSize);
  sw.Stop;
  Writeln('AVX2      : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    SwapEndianAVX2x2(pL^, CCacheSize);
  sw.Stop;
  Writeln('AVX2x2    : ', sw.ElapsedTicks);


  Writeln(CSize, ' ELEMENTS BY ', CLoopItersBig, ' RESULTS');

  FillDWord(pL^, CSize, $01020304);{warm up the cache}

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    SwapEndianSimple(pL^, CSize);
  sw.Stop;
  Writeln('Simple    : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    SwapEndianUnroll(pL^, CSize);
  sw.Stop;
  Writeln('Unroll    : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    SwapEndianBswap(pL^, CSize);
  sw.Stop;
  Writeln('Bswap     : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    SwapEndianBswapx2(pL^, CSize);
  sw.Stop;
  Writeln('Bswapx2   : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    SwapEndianSSSE3(pL^, CSize);
  sw.Stop;
  Writeln('SSSE3     : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    SwapEndianAVX2(pL^, CSize);
  sw.Stop;
  Writeln('AVX2      : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    SwapEndianAVX2x2(pL^, CSize);
  sw.Stop;
  Writeln('AVX2x2    : ', sw.ElapsedTicks);
end.