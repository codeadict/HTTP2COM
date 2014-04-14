BrandingText "IGPython HTTP2COM Service"

; Passed in from command line:
!define  CONFIG_VERSION "0.0.1"

!define CONFIG_PROJECT_URL "http://www.igpython.co.uk/"
!define CONFIG_SHORT_APP_NAME "HTTP2COM"
!define CONFIG_LONG_APP_NAME  "IGPython Http2Com"
!define CONFIG_PUBLISHER "IGPython"
!define CONFIG_ICON "logo.ico"
!define CONFIG_EXECUTABLE "IGPythonService.exe"
!define CONFIG_OUTPUT_FILE "IGPythonServiceSetup.exe"

!define INST_KEY "Software\${CONFIG_PUBLISHER}\${CONFIG_LONG_APP_NAME}"
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${CONFIG_LONG_APP_NAME}"

!define UNINSTALL_SHORTCUT "Uninstall ${CONFIG_LONG_APP_NAME}.lnk"
!define MUI_ICON "${CONFIG_ICON}"
!define MUI_UNICON "${CONFIG_ICON}"

;INCLUDES
!addplugindir "${CONFIG_PLUGIN_DIR}"
!addincludedir "${CONFIG_PLUGIN_DIR}"

!include "MUI2.nsh"
!include InstallOptions.nsh

!define PRODUCT_NAME "${CONFIG_LONG_APP_NAME}"

;GENERAL SETTINGS
Name "${CONFIG_LONG_APP_NAME}"
OutFile "${CONFIG_OUTPUT_FILE}"
InstallDir "$PROGRAMFILES\${CONFIG_PUBLISHER}\${CONFIG_LONG_APP_NAME}"
InstallDirRegKey HKLM "${INST_KEY}" "Install_Dir"
SetCompressor lzma

SetOverwrite on
CRCCheck on
XPStyle on

Icon "${CONFIG_ICON}"

ReserveFile "configuration.ini"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function LaunchService
  SetShellVarContext all
  SimpleSC::InstallService "IGPython HTTP2COM" "IGPython HTTP2COM" "16" "2" "$INSTDIR\${CONFIG_EXECUTABLE}" "" "" ""
  Pop $0
  SimpleSC::StartService "IGPython HTTP2COM" "" 30
  Pop $0
FunctionEnd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sections                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Page Custom ServiceConfigPage

Function .onInit
    InitPluginsDir
    File /oname=$PLUGINSDIR\configuration.ini "configuration.ini"
FunctionEnd

Section "-${CONFIG_LONG_APP_NAME}" COM2
  SectionIn RO
  ClearErrors
  SetShellVarContext all

  SetOutPath "$INSTDIR"

  File ${CONFIG_ICON}
  File *.pyd
  File *.dll
  File w9xpopen.exe
  File ${CONFIG_EXECUTABLE}
  SetOutPath "$INSTDIR\config"
  File /r config\*.*
  IfErrors 0 files_ok

  MessageBox MB_OK|MB_ICONEXCLAMATION "Installation failed.  An error occured writing to the ${CONFIG_LONG_APP_NAME} Folder."
  Quit
files_ok:
  CreateDirectory "$SMPROGRAMS\${CONFIG_LONG_APP_NAME}"
  CreateShortCut "$SMPROGRAMS\${CONFIG_LONG_APP_NAME}\${UNINSTALL_SHORTCUT}" \
    "$INSTDIR\uninstall.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${INST_KEY}" "InstallDir" $INSTDIR
  WriteRegStr HKLM "${INST_KEY}" "Version" "${CONFIG_VERSION}"
  WriteRegStr HKLM "${INST_KEY}" "" "$INSTDIR\${CONFIG_EXECUTABLE}"

  WriteRegStr HKLM "${UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr HKLM "${UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\${CONFIG_EXECUTABLE}"
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayVersion" "${CONFIG_VERSION}"
  WriteRegStr HKLM "${UNINST_KEY}" "URLInfoAbout" "${CONFIG_PROJECT_URL}"
  WriteRegStr HKLM "${UNINST_KEY}" "Publisher" "${CONFIG_PUBLISHER}"

SectionEnd

Section "Uninstall" SEC91

  SetShellVarContext all
  SimpleSC::StopService "IGPython HTTP2COM" 1 30
  Pop $0
  SimpleSC::RemoveService "IGPython HTTP2COM"
  Pop $0
  Delete "$INSTDIR\uninstall.exe"
  Delete "$INSTDIR\${CONFIG_ICON}"
  Delete "$INSTDIR\*.pyd"
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\${CONFIG_EXECUTABLE}"
  Delete "$INSTDIR\w9xpopen.exe"
  Delete "$INSTDIR\config\*.*"
  RMDir "$INSTDIR\config"
  RMDir "$INSTDIR"
  RMDIR "$PROGRAMFILES\${CONFIG_PUBLISHER}"

  RMDir "$PROGRAMFILES\${CONFIG_PUBLISHER}"

  ; Remove Start Menu shortcuts
  Delete "$SMPROGRAMS\${CONFIG_LONG_APP_NAME}\${UNINSTALL_SHORTCUT}"
  RMDir "$SMPROGRAMS\${CONFIG_LONG_APP_NAME}"

  SetAutoClose true
SectionEnd

;PAGE SETUP
!define MUI_ABORTWARNING ;a confirmation message should be displayed if the user clicks cancel

!define MUI_WELCOMEFINISHPAGE_BITMAP "modern-wizard.bmp"
!insertmacro MUI_PAGE_WELCOME ;welcome page
!insertmacro MUI_PAGE_INSTFILES ;install files page

Function ServiceConfigPage
  !insertmacro MUI_HEADER_TEXT "Service Settings" "Serial Port and Server configurations - please fill all elements"
  !insertmacro INSTALLOPTIONS_DISPLAY "configuration.ini"
FunctionEnd

; Finish page
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_TITLE "${CONFIG_LONG_APP_NAME} has been installed!"
!define MUI_FINISHPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_RUN_TEXT "Run ${CONFIG_LONG_APP_NAME}"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchService"
!define MUI_FINISHPAGE_LINK "${CONFIG_PUBLISHER} homepage."
!define MUI_FINISHPAGE_LINK_LOCATION "${CONFIG_PROJECT_URL}"
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM

!insertmacro MUI_UNPAGE_INSTFILES
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "modern-wizard.bmp"
!insertmacro MUI_UNPAGE_FINISH

;LANGUAGE FILES
!define MUI_LANGSTRINGS
!insertmacro MUI_LANGUAGE "English"
