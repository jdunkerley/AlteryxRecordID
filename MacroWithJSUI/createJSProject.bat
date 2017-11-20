pushd %~dp0
PowerShell -C "Remove-Item ./GroupedRecordIDJS -Force"
PowerShell -C "../Scripts/CreateMacroJSTool.ps1 ../Macro/GroupedRecordID.yxmc ."