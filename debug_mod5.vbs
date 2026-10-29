Option Explicit
Dim shell, fso, pastaAtual
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
pastaAtual = fso.GetParentFolderName(WScript.ScriptFullName)

WScript.Echo "1. Script iniciado"

' Simula CarregarTransporteNao
Dim streamTn, conteudoTn, errTn
Dim totalTranspNao
totalTranspNao = 0
If fso.FileExists(pastaAtual & "\transporte_nao.txt") Then
    Set streamTn = CreateObject("ADODB.Stream")
    streamTn.Open
    streamTn.Type = 2
    streamTn.Charset = "utf-8"
    streamTn.LoadFromFile pastaAtual & "\transporte_nao.txt"
    conteudoTn = streamTn.ReadText
    streamTn.Close
    Dim linhasTn, iTn, linha, partesTn
    linhasTn = Split(conteudoTn, vbLf)
    For iTn = 0 To UBound(linhasTn)
        linha = Trim(linhasTn(iTn))
        If linha <> "" And InStr(linha, "|") > 0 Then
            totalTranspNao = totalTranspNao + 1
        End If
    Next
End If
WScript.Echo "2. totalTranspNao = " & totalTranspNao

' Mostra popup como o modulo 5 faria
WScript.Echo "3. ANTES do popup"
shell.Popup "Conferencia de " & totalTranspNao & " alunos SEM transporte.", 0, "Teste", 64
WScript.Echo "4. DEPOIS do popup (OK clicado)"

' Gera painel HTA
Dim hta, fHTA, arr(330), i
i = 0
arr(i) = "<!DOCTYPE html>" : i = i + 1
arr(i) = "<html>" : i = i + 1
arr(i) = "<head>" : i = i + 1
arr(i) = "<title>Painel Teste</title>" : i = i + 1
arr(i) = "<hta:application id=""app"" showintaskbar=""yes"" />" : i = i + 1
arr(i) = "</head>" : i = i + 1
arr(i) = "<body><h2>Painel de Teste</h2><p>Se voce ve isso, o HTA funciona.</p></body>" : i = i + 1
arr(i) = "</html>" : i = i + 1

Dim linhaHTA
linhaHTA = Join(arr, vbCrLf)
Set fHTA = fso.CreateTextFile(pastaAtual & "\painel_teste.hta", True)
fHTA.Write linhaHTA
fHTA.Close
WScript.Echo "5. HTA criado, executando..."
shell.Run "mshta.exe """ & pastaAtual & "\painel_teste.hta""", 1, False
WScript.Echo "6. HTA executado (janela deve estar visivel)"

WScript.Echo "7. FIM DO TESTE"
