unit unit_9010_DmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, DB, FileUtil, SQLScript;

type

  { TDm_main }

  TDm_main = class(TDataModule)
    conn_DB: TSQLite3Connection;
    ds_muscleDefTypes: TDataSource;
    ds_fitStages: TDataSource;
    qry_fitStages: TSQLQuery;
    qry_muscleDefTypes: TSQLQuery;
    SQLScript_newFile: TSQLScript;
    trans_main: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure SQLScript_newFileDirective(Sender: TObject; Directive,
      Argument: AnsiString; var StopExecution: Boolean);
  private
    function TempDB: string;
    procedure CloseAll;
    procedure OpenAll(const aCreateNewFile: Boolean = False);
    procedure UpdateAllToHD;
  public

  end;

var
  Dm_main: TDm_main;

implementation

uses
  Forms;

{$R *.lfm}

{ TDm_main }

procedure TDm_main.DataModuleCreate(Sender: TObject);
begin
  CloseAll;
  DeleteFile(TempDB);
  conn_DB.DatabaseName := TempDB;
  conn_DB.OpenFlags := [sofCreate, sofReadWrite];
  OpenAll(True);
  // New file on create

end;

procedure TDm_main.DataModuleDestroy(Sender: TObject);
begin
  UpdateAllToHD;
  CloseAll;
  //DeleteFile(TempDB);
end;

procedure TDm_main.SQLScript_newFileDirective(Sender: TObject; Directive,
  Argument: AnsiString; var StopExecution: Boolean);
begin

end;

function TDm_main.TempDB: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'temp.db';
end;

procedure TDm_main.CloseAll;
begin
  trans_main.CloseDataSets;
  conn_DB.CloseTransactions;
  conn_DB.Close(True);
end;

procedure TDm_main.OpenAll(const aCreateNewFile: Boolean);
begin
  conn_DB.Open;
  if aCreateNewFile then
    SQLScript_newFile.ExecuteScript;
  trans_main.Active := True;

  qry_fitStages.Open;
  qry_muscleDefTypes.Open;
end;

procedure TDm_main.UpdateAllToHD;
begin
  qry_fitStages.ApplyUpdates;
end;

end.










