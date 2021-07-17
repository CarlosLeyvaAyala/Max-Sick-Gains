program TexRename;

uses
  SysUtils,
  StrUtils,
  RegExpr;

  procedure ShowHelp;
  begin
    WriteLn('Drag and drop here the files you want to be renamed.');
    WriteLn('Drop only the textures you just created in Photoshop.');
    WriteLn('');
    WriteLn('This isn''t a fancy program. It''s only purpose is to rename');
    WriteLn('those files or correct their names if you made some typo.');
    WriteLn('');
    WriteLn('Try not to do odd things when working with this, no?');
    ReadLn;
  end;

  procedure ShowIncorrectPrompt;
  begin
    WriteLn('Your files seem to be located in an incorrect folder.');
    WriteLn('They should be at:');
    WriteLn('textures\actors\character\Maxick\<Race>');
    WriteLn('');
    WriteLn('Please move them to their correct location before we can continue.');
    ReadLn;
  end;

  procedure ShowNotPhotoshopGenerated(aFileName: string);
  begin
    WriteLn('You seem to have named your textures by hand.');
    WriteLn(Format('I can''t get a valid number from "%s"', [aFileName]));
    WriteLn('Since I don''t know which texture number this is, I''ll just');
    WriteLn('add a long number; hoping it doesn''t collide with any other filename.');
    WriteLn('You need to correctly rename this by hand.');
    WriteLn('');
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

  function RenameByNumber(aOldName, aNewBaseName: string; aNum: integer;
    aDigits: integer = 2): string;
  begin
    Result := Format('%s%s%.*d%s', [ExtractFilePath(aOldName),
      aNewBaseName, aDigits, aNum, ExtractFileExt(aOldName)]);
  end;

  // Attemps to rename a file that ends with a number.
  function RenameNumbered(aOldName, aNewName: string): boolean;
  var
    fileNum: integer;
  begin
    // Does the filename end with some number?
    fileNum := GetFileNumber(aOldName, '(\d+)\..*$');
    Result := fileNum <> -1;
    if not Result then
      Exit;
    RenameFile(aOldName, RenameByNumber(aOldName, aNewName, fileNum));
  end;

  procedure RenameByFileStamp(aOldName, aNewName: string);
  var
    lastModified: longint;
  begin
    lastModified := FileAge(aOldName);
    RenameFile(aOldName, RenameByNumber(aOldName, aNewName, lastModified, 0));
  end;

  procedure DoRename(aNewName: string);
  var
    i: integer;
  begin
    for i := 1 to ParamCount do
      if not RenameNumbered(ParamStr(i), aNewName) then
      begin
        ShowNotPhotoshopGenerated(ExtractFileName(ParamStr(i)));
        RenameByFileStamp(ParamStr(i), aNewName);
      end;
  end;

var
  newName: string;

{$R *.res}

begin
  if ParamCount < 1 then
  begin
    ShowHelp;
    Exit;
  end;

  newName := GetNewName(ExtractFileDir(ParamStr(1)));
  if newName = '' then
  begin
    ShowIncorrectPrompt;
    Exit;
  end;

  WriteLn('');
  DoRename(newName);
  WriteLn('');
  WriteLn('Files successfully renamed. Press enter to exit.');
  ReadLn;
end.
