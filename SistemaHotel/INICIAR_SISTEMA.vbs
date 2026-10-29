Dim fs, shell, psCmd, scriptDir, logFile
Set fs = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
scriptDir = fs.GetParentFolderName(WScript.ScriptFullName)
logFile = scriptDir & "\erro.log"

psCmd = "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden """ & scriptDir & "\SistemaHotel.ps1"" 2>""" & logFile & """"

shell.Run psCmd, 0, False
