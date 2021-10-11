program FastAntiAlias;

uses
  Forms,
  FAAlias in 'FAAlias.pas' {AntiAliasForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TAntiAliasForm, AntiAliasForm);
  Application.Run;
end.
