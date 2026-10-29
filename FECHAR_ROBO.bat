@echo off
title Fechar Robo Educacenso
echo Fechando robo do Educacenso...
taskkill /f /im wscript.exe >nul 2>&1
taskkill /f /im mshta.exe >nul 2>&1
taskkill /f /im powershell.exe >nul 2>&1
echo Robo encerrado.
timeout /t 2 >nul