pushd %~dp0
PowerShell -C "Remove-Item ./GroupedRecordIDJS.yxi -Force"
PowerShell -C "../Scripts/CreateYXI.ps1 -folder ./GroupedRecordIDJS -version 1.0.0 -imagePath ./GroupedRecordIDJS/logo.png"
