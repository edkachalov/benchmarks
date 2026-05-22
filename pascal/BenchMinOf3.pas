{$mode objfpc}{$H+}
{$inline on}
{$If Defined(CPU386) OR Defined(CPUX64)}
  {$ASMMODE intel}
{$EndIf}
{$SMARTLINK ON}
{$Calling Register}
{$CODEALIGN PROC=32}
{$CODEALIGN LOOP=32}

uses stopwatch;

function MinRegular(A, B, C: Integer): Integer;
begin
  Result := A;
  if B < Result then
    Result := B;
  if C < Result then
    Result := C;
end;

function MinInline(A, B, C: Integer): Integer;inline;
begin
  Result := A;
  if B < Result then
    Result := B;
  if C < Result then
    Result := C;
end;

function MinSIMD(A, B, C: Integer): Integer;assembler;nostackframe;
asm
  movD xmm0,A
  movD xmm1,B
  movD xmm2,C
  pminSD xmm0,xmm1
  pminSD xmm0,xmm2
  movD eax,xmm0
end;

function crMinInline(constref A, B, C: Integer): Integer;inline;
begin
  Result := A;
  if B < Result then
    Result := B;
  if C < Result then
    Result := C;
end;

function crMinSIMD(constref A, B, C: Integer): Integer;assembler;nostackframe;
asm
  movD xmm0,dword ptr[A]
  movD xmm1,dword ptr[B]
  movD xmm2,dword ptr[C]
  pminSD xmm0,xmm1
  pminSD xmm0,xmm2
  movD eax,xmm0
end;

const
  CSize = 1024 * 1024;
var
  i: SizeInt;
  sw: TStopWatch;
  pL: PLongInt;
  L: LongInt;
begin
  sw:= TStopWatch.Create;

	RandSeed:= 42;

  pL:= GetMem(CSize * SizeOf(LongInt));

  for i:= 0 to CSize - 1 do
    pL[i]:= Random(10) - 5;

  sw.Reset; sw.Start;
  for i:= 0 to CSize - 3 do
    L:= MinRegular(pL[i], pL[i+1], pL[i+2]);
  sw.Stop;
  Writeln('Regular    : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 0 to CSize - 3 do
    L:= MinInline(pL[i], pL[i+1], pL[i+2]);
  sw.Stop;
  Writeln('Inline     : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 0 to CSize - 3 do
    L:= MinSIMD(pL[i], pL[i+1], pL[i+2]);
  sw.Stop;
  Writeln('SIMD       : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 0 to CSize - 3 do
    L:= crMinInline(pL[i], pL[i+1], pL[i+2]);
  sw.Stop;
  Writeln('crInline   : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 0 to CSize - 3 do
    L:= crMinSIMD(pL[i], pL[i+1], pL[i+2]);
  sw.Stop;
  Writeln('crSIMD     : ', sw.ElapsedTicks);
end.