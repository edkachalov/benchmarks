{$MODE objfpc}{$H+}
{$INLINE on}
{$If Defined(CPU386) OR Defined(CPUX64)}
  {$ASMMODE intel}
{$EndIf}
{$SMARTLINK ON}
{$Calling Register}
{$CodeAlign proc=32}
{$CodeAlign loop=32}

uses stopwatch;

type
  TAlignedRec = packed record
    Q: QWord;
    D: DWord;
    W: Word;
    _padding: Word;
  end;

  TUnAlignedRec = packed record
    Q: QWord;
    D: DWord;
    W: Word;
  end;

procedure Swap(var A, B: DWord);inline;
var
  T: DWord;
begin
  T:= A;
  A:= B;
  B:= T;
end;

function SimulateRead(constref R: TAlignedRec): SizeUInt;inline;
begin
  Result:= R.Q + R.D + R.W;
end;

function SimulateRead(constref R: TUnAlignedRec): SizeUInt;inline;
begin
  Result:= R.Q + R.D + R.W;
end;

procedure SimulateWrite(var R: TAlignedRec);inline;
begin
  R.Q:= 1;
  R.D:= 2;
  R.W:= 3;
end;

procedure SimulateWrite(var R: TUnAlignedRec);inline;
begin
  R.Q:= 1;
  R.D:= 2;
  R.W:= 3;
end;

function ProceedBufferR(constref Buffer: TAlignedRec; Count: SizeUInt): SizeUInt;
var
  aBuffer: array [Byte] of TAlignedRec absolute Buffer;
begin
  Result:= 0;
  if Count = 0 then
    Exit;

  for Count:= 0 to Count - 1 do
    Inc(Result, SimulateRead( aBuffer[Count] ));
end;

function ProceedBufferR(constref Buffer: TUnAlignedRec; Count: SizeUInt): SizeUInt;
var
  aBuffer: array [Byte] of TUnAlignedRec absolute Buffer;
begin
  Result:= 0;
  if Count = 0 then
    Exit;

  for Count:= 0 to Count - 1 do
    Inc(Result, SimulateRead( aBuffer[Count] ));
end;

function ProceedBufferW(var Buffer: TAlignedRec; Count: SizeUInt): SizeUInt;
var
  aBuffer: array [Byte] of TAlignedRec absolute Buffer;
begin
  Result:= 0;
  if Count = 0 then
    Exit;

  for Count:= 0 to Count - 1 do
    SimulateWrite( aBuffer[Count] );
end;

function ProceedBufferW(var Buffer: TUnAlignedRec; Count: SizeUInt): SizeUInt;
var
  aBuffer: array [Byte] of TUnAlignedRec absolute Buffer;
begin
  Result:= 0;
  if Count = 0 then
    Exit;

  for Count:= 0 to Count - 1 do
    SimulateWrite( aBuffer[Count] );
end;

const
  CSize = 1024 * 1024;
  {elements in L1 cache line}
  CCacheSize = (32 * 1024) div SizeOf(TAlignedRec);
  CLoopItersSmall = 100;
  CLoopItersBig = 4;
var
  i, j, k: SizeInt;
  R: SizeUInt;
  ArrA: array of TAlignedRec;
  ArrU: array of TUnAlignedRec;
  Indexes: array of DWord;
  sw: TStopWatch;
begin
  sw:= TStopWatch.Create;
  SetLength(ArrA, CSize);
  SetLength(ArrU, CSize);
  SetLength(Indexes, CSize);

  RandSeed:= 42;

  Writeln(CCacheSize, ' ELEMENTS BY ', CLoopItersSmall, ' RESULTS');

  FillByte(ArrA[0], CCacheSize * SizeOf(TAlignedRec), 0);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    R:= ProceedBufferR(ArrA[0], CCacheSize);
  sw.Stop;
  Writeln('R Aligned   : ', sw.ElapsedTicks);

  FillByte(ArrU[0], CCacheSize * SizeOf(TUnAlignedRec), 0);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    R:= ProceedBufferR(ArrU[0], CCacheSize);
  sw.Stop;
  Writeln('R Unaligned : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    R:= ProceedBufferW(ArrA[0], CCacheSize);
  sw.Stop;
  Writeln('W Aligned   : ', sw.ElapsedTicks);

  FillByte(ArrU[0], CCacheSize * SizeOf(TUnAlignedRec), 0);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersSmall do
    R:= ProceedBufferW(ArrU[0], CCacheSize);
  sw.Stop;
  Writeln('W Unaligned : ', sw.ElapsedTicks);


  Writeln(CSize, ' ELEMENTS BY ', CLoopItersBig, ' RESULTS');

  FillByte(ArrA[0], Length(ArrA) * SizeOf(TAlignedRec), 0);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    R:= ProceedBufferR(ArrA[0], Length(ArrA));
  sw.Stop;
  Writeln('R Aligned   : ', sw.ElapsedTicks);

  FillByte(ArrU[0], Length(ArrU) * SizeOf(TUnAlignedRec), 0);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    R:= ProceedBufferR(ArrU[0], Length(ArrU));
  sw.Stop;
  Writeln('R Unaligned : ', sw.ElapsedTicks);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    R:= ProceedBufferW(ArrA[0], Length(ArrA));
  sw.Stop;
  Writeln('W Aligned   : ', sw.ElapsedTicks);

  FillByte(ArrU[0], Length(ArrU) * SizeOf(TUnAlignedRec), 0);

  sw.Reset; sw.Start;
  for i:= 1 to CLoopItersBig do
    R:= ProceedBufferW(ArrU[0], Length(ArrU));
  sw.Stop;
  Writeln('W Unaligned : ', sw.ElapsedTicks);

  Writeln('TESTING RANDOM ACCESS');
  i:= 2;
  while (i * CCacheSize) < CSize do begin
    Writeln('ELEMENTS ', i * CCacheSize);
    
    for j:= 0 to i * CCacheSize - 1 do
      Indexes[j]:= j;
    {shuffle array content}
    for j:= i * CCacheSize - 1 downto 1 do begin
      k:= Random(i * CCacheSize);
      Swap(Indexes[j], Indexes[k]);
    end;

    FillByte(ArrA[0], i * CCacheSize * SizeOf(TAlignedRec), 0);

    sw.Reset; sw.Start;
    for k:= 1 to CLoopItersBig do
      for j:= 0 to i * CCacheSize - 1 do
        Inc(R, SimulateRead(ArrA[Indexes[j]]));
    sw.Stop;
    Writeln('R Aligned   ', ((sw.ElapsedTicks) / (i * CCacheSize)):6:3);

    FillByte(ArrU[0], i * CCacheSize * SizeOf(TUnAlignedRec), 0);

    sw.Reset; sw.Start;
    for k:= 1 to CLoopItersBig do
      for j:= 0 to i * CCacheSize - 1 do
        Inc(R, SimulateRead(ArrU[Indexes[j]]));
    sw.Stop;
    Writeln('R Unaligned ', ((sw.ElapsedTicks) / (i * CCacheSize)):6:3);

    FillByte(ArrA[0], i * CCacheSize * SizeOf(TAlignedRec), 0);

    sw.Reset; sw.Start;
    for k:= 1 to CLoopItersBig do
      for j:= 0 to i * CCacheSize - 1 do
        SimulateWrite(ArrA[Indexes[j]]);
    sw.Stop;
    Writeln('W Aligned   ', ((sw.ElapsedTicks) / (i * CCacheSize)):6:3);

    FillByte(ArrU[0], i * CCacheSize * SizeOf(TUnAlignedRec), 0);

    sw.Reset; sw.Start;
    for k:= 1 to CLoopItersBig do
      for j:= 0 to i * CCacheSize - 1 do
        SimulateWrite(ArrU[Indexes[j]]);
    sw.Stop;
    Writeln('W Unaligned ', ((sw.ElapsedTicks) / (i * CCacheSize)):6:3);

    Inc(i, 4);{increase this to reduce the benchmark time}
  end;
end.