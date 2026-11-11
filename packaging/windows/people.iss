#ifndef AppVersion
  #error AppVersion must be supplied by Build-WindowsRelease.ps1
#endif
#ifndef BundleDirectory
  #error BundleDirectory must be supplied by Build-WindowsRelease.ps1
#endif
#ifndef ReleaseDirectory
  #error ReleaseDirectory must be supplied by Build-WindowsRelease.ps1
#endif

[Setup]
AppId={{6372CB4E-CA8D-4906-92B0-821E3365F071}
AppName=People
AppVersion={#AppVersion}
AppPublisher=People
DefaultDirName={localappdata}\Programs\People
DefaultGroupName=People
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir={#ReleaseDirectory}
OutputBaseFilename=People-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\people.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
DisableProgramGroupPage=yes

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "{#BundleDirectory}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\People"; Filename: "{app}\people.exe"
Name: "{autodesktop}\People"; Filename: "{app}\people.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\people.exe"; Description: "Launch People"; Flags: nowait postinstall skipifsilent
