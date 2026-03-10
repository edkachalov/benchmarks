{$mode objfpc}{$H+}
{$Calling Register}

uses stopwatch;

const
	CSize = 1024 * 1024;

type
	TRecShortString = object
	public
		A, B: String[31];
	end;

	TRecAnsiString = object
	public
		A, B: String;
	end;

function SimpleHash(const S: String): Byte;
var
  i: SizeInt;
  hash: Cardinal;
begin
  hash:= 0;

  for i:= 1 to Length(S) do
    hash:= hash + ord(S[i]);

  Result:= hash mod 256;
end;

function SimpleHash(constref S: ShortString): Byte;
var
  i: SizeInt;
  hash: Cardinal;
begin
  hash:= 0;

  for i:= 1 to Length(S) do
    hash:= hash + ord(S[i]);

  Result:= hash mod 256;
end;

function GenString: String;
begin
	SetLength(Result, 15 + Random(15));
end;

var
	i, j: SizeInt;
	S: String;
	SSA: array of TRecShortString;
	ASA: array of TRecAnsiString;
	sw: TStopWatch;

begin
	sw:= TStopWatch.Create;
	SetLength(SSA, CSize);
	SetLength(ASA, CSize);

	for i:= 0 to Pred(CSize) do begin
		S:= GenString;
		SSA[i].A:= S;
		ASA[i].A:= S;
		S:= GenString;
		SSA[i].B:= S;
		ASA[i].B:= S;
	end;

	j:= 0;
	sw.Reset; sw.Start;
	for i:= 0 to Pred(CSize) do
		Inc(j, SimpleHash(SSA[i].A) + SimpleHash(SSA[i].B));
	sw.Stop;
	Writeln('ShortString: ', sw.ElapsedTicks);

	j:= 0;
	sw.Reset; sw.Start;
	for i:= 0 to Pred(CSize) do
		Inc(j, SimpleHash(ASA[i].A) + SimpleHash(ASA[i].B));
	sw.Stop;
	Writeln('Ansi string: ', sw.ElapsedTicks);
end.