' Mata robo Educacenso completamente (script, painel e powershell)
CreateObject("WScript.Shell").Run "taskkill /f /im wscript.exe", 0, False
CreateObject("WScript.Shell").Run "taskkill /f /im mshta.exe", 0, False
CreateObject("WScript.Shell").Run "taskkill /f /im powershell.exe", 0, False
