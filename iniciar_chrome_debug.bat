@echo off
title Iniciar Chrome do Robo
echo Verificando se Chrome com debug ja esta rodando...
powershell -NoProfile -Command "try { $r=Invoke-RestMethod 'http://127.0.0.1:9222/json' -TimeoutSec 2 -ErrorAction Stop; Write-Host 'OK - Chrome ja rodando ('$r.Count' abas)'; exit 0 } catch { exit 1 }"
if %errorlevel% equ 0 goto :fim

echo Iniciando Chrome do robo (perfil separado, nao mexe no seu Chrome)...
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --remote-allow-origins=* --no-first-run --user-data-dir="%LOCALAPPDATA%\Chrome_Robot_Profile" --new-window https://educacenso.inep.gov.br/
echo Aguardando 5 segundos...
timeout /t 5 /nobreak >nul

echo.
echo Chrome do robo iniciado. Faca login no Educacenso nesta janela.
echo Depois, inicie o executar_censo.vbs normalmente.
pause
exit /b

:fim
echo Chrome do robo ja esta rodando. Inicie o executar_censo.vbs.
timeout /t 3 /nobreak >nul
