program TexRename;

uses
  SysUtils,
  StrUtils,
  RegExpr;

  procedure ShowHelp;
  begin
    WriteLn('Drag and drop here the files you want to be renamed.');
    WriteLn('Drop only the 6 textures you just created in Photoshop.');
    WriteLn('');
    WriteLn('This isn''t a fancy program. It''s only purpose is to rename');
    WriteLn('those 6 files or correct their names if you made some typo.');
    WriteLn('');
    WriteLn('Read this mod''s help file to know more about do''s and don''ts in here.');
    ReadLn;
  end;

  function DetectRace(const aDir: string): string;
  const
    baseFolder = 'textures\actors\character\Maxick\';
  begin
    if AnsiEndsText(baseFolder + 'Hum', aDir) then
      Result := 'Humanoids (Men/Mer)'
    else if AnsiEndsText(baseFolder + 'Arg', aDir) then
      Result := 'Argonians'
    else if AnsiEndsText(baseFolder + 'Kha', aDir) then
      Result := 'Khajiit'
    else
      Result := '';
  end;

  function AskSex(const aRace: string): string;
  var
    ans: string;
  begin
    Write(Format('You are renaming textures for %s. Are them for females? Y/N ',
      [aRace]));
    ReadLn(ans);

    if AnsiLowerCase(ans) = 'y' then
      Result := 'Fem'
    else
      Result := 'Man';
  end;

  function AskMuscleDefinition: string;
  var
    ans: string;
  begin
    Write('What kind of muscle definition? (F)at, (P)lain or (A)thletic? ');
    ReadLn(ans);
    ans := AnsiLeftStr(AnsiLowerCase(ans), 1);
    if ans = 'f' then
      Result := 'Fat'
    else if ans = 'a' then
      Result := 'Fit'
    else
      Result := 'Meh';
  end;

  function GetNewName(const aDir: string): string;
  var
    knownRace, sex, muscleDef: string;
  begin
    Result := '';
    knownRace := DetectRace(aDir);
    if knownRace <> '' then
    begin
      sex := AskSex(knownRace);
      muscleDef := AskMuscleDefinition;
      Result := Format('%s%s_', [sex, muscleDef]);
    end
    else
    begin
      WriteLn('Your files seem to be located in an incorrect folder.');
      WriteLn('Please move them to their correct location before we can continue.');
    end;
  end;

  // Gets the number of some file based on a regular expression
  function GetFileNumber(aName, aRegex: string): integer;
  var
    r: TRegExpr;
  begin
    Result := -1;     // File number not found
    r := TRegExpr.Create(aRegex);
    if not r.Exec(aName) then
      Exit;
    Result := StrToInt(r.Match[1]);
    r.Free;
  end;

  function RenameByNumber(aOldName, aNewBaseName: string; aNum: integer): string;
  begin
    Result := Format('%s%s%.2d%s', [ExtractFilePath(aOldName),
      aNewBaseName, aNum, ExtractFileExt(aOldName)]);
  end;

  // Attempts to rename a file created by File > Export > Layers to files...
  // in Photoshop.
  // Returns if it was that kind of file.
  function RenamePhotoshop(aOldName, aNewName: string): boolean;
  var
    //r: TRegExpr;
    fileNum: integer;
  begin
    // Does the filename end with 'Frame n'?
    fileNum := GetFileNumber(aOldName, '[Ff]rame.*(\d)\..*$');
    Result := fileNum <> -1;
    //r := TRegExpr.Create('[Ff]rame.*(\d)\..*$');
    //Result := r.Exec(aOldName);
    if not Result then
      Exit;
    //    Generate new name
    //fileNum := StrToInt(r.Match[1]);
    //aNewName := Format('%s%s%.2d%s', [ExtractFilePath(aOldName),
    //  aNewName, fileNum, ExtractFileExt(aOldName)]);
    //RenameFile(aOldName, aNewName);
    RenameFile(aOldName, RenameByNumber(aOldName, aNewName, fileNum));
  end;

  function RenameTypos(aOldName, aNewName: string): boolean;
  var
    fileNum: integer;
  begin
    // Does the filename end with some number?
    fileNum := GetFileNumber(aOldName, '(\d)+\..*$');
    Result := fileNum <> -1;
    if not Result then
      Exit;
    RenameFile(aOldName, RenameByNumber(aOldName, aNewName, fileNum));
  end;

var
  i: integer;
  newName: string;
begin
  if ParamCount < 1 then
  begin
    ShowHelp;
    Exit;
  end;

  newName := GetNewName(ExtractFileDir(ParamStr(1)));

  for i := 1 to ParamCount do
  begin
    if not RenamePhotoshop(ParamStr(i), newName) then;
      RenameTypos(ParamStr(i), newName);
  end;
  WriteLn('Files successfully renamed. Press enter to exit.');
  ReadLn;
end.
