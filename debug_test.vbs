Option Explicit
Dim shell, fso, pastaAtual
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
pastaAtual = fso.GetParentFolderName(WScript.ScriptFullName)

Dim streamTn, conteudoTn, errTn
Dim totalTranspNao
totalTranspNao = 0

If fso.FileExists(pastaAtual & "\transporte_nao.txt") Then
    On Error Resume Next
    Set streamTn = CreateObject("ADODB.Stream")
    streamTn.Open
    streamTn.Type = 2
    streamTn.Charset = "utf-8"
    streamTn.LoadFromFile pastaAtual & "\transporte_nao.txt"
    conteudoTn = streamTn.ReadText
    errTn = Err.Number
    streamTn.Close
    If errTn <> 0 Then
        WScript.Echo "UTF-8 FAILED err=" & errTn
        Err.Clear
        Set streamTn = CreateObject("ADODB.Stream")
        streamTn.Open
        streamTn.Type = 2
        streamTn.Charset = "unicode"
        streamTn.LoadFromFile pastaAtual & "\transporte_nao.txt"
        conteudoTn = streamTn.ReadText
        errTn = Err.Number
        streamTn.Close
        If errTn <> 0 Then
            WScript.Echo "UNICODE FAILED err=" & errTn
        Else
            WScript.Echo "Loaded via UNICODE"
        End If
    Else
        WScript.Echo "Loaded via UTF-8"
    End If
    On Error GoTo 0

    Dim linhasTn, iTn, linha, partesTn
    linhasTn = Split(conteudoTn, vbLf)
    WScript.Echo "Total lines read: " & UBound(linhasTn) + 1
    For iTn = 0 To UBound(linhasTn)
        linha = Trim(linhasTn(iTn))
        If linha <> "" And InStr(linha, "|") > 0 Then
            totalTranspNao = totalTranspNao + 1
        End If
    Next
    WScript.Echo "TotalTranspNao: " & totalTranspNao
Else
    WScript.Echo "transporte_nao.txt NOT FOUND"
End If

Dim dictCPF
Set dictCPF = CreateObject("Scripting.Dictionary")
Dim caminhoDados, fDados, conteudoArquivo, linhasArquivo
caminhoDados = pastaAtual & "\dados.txt"
If fso.FileExists(caminhoDados) Then
    Set fDados = fso.OpenTextFile(caminhoDados, 1, False, -2)
    conteudoArquivo = fDados.ReadAll
    fDados.Close
    Dim regexCpf
    Set regexCpf = CreateObject("VBScript.RegExp")
    regexCpf.Pattern = "\d{3}[\.\s]?\d{3}[\.\s]?\d{3}[\-\s]?\d{2}"
    regexCpf.Global = False
    regexCpf.IgnoreCase = True
    Dim linhaCPF, partesCPF, nomeCPF, cpfCPF
    Dim iCPF
    linhasArquivo = Split(conteudoArquivo, vbLf)
    WScript.Echo "dados.txt lines: " & UBound(linhasArquivo) + 1
    For iCPF = 0 To UBound(linhasArquivo)
        linhaCPF = Trim(linhasArquivo(iCPF))
        If InStr(linhaCPF, vbTab) > 0 Then
            partesCPF = Split(linhaCPF, vbTab)
            If UBound(partesCPF) >= 3 Then
                If IsNumeric(Trim(partesCPF(0))) And regexCpf.Test(Trim(partesCPF(3))) Then
                    nomeCPF = UCase(Trim(partesCPF(1)))
                    cpfCPF = Trim(partesCPF(3))
                    cpfCPF = Replace(cpfCPF, ".", "")
                    cpfCPF = Replace(cpfCPF, "-", "")
                    cpfCPF = Replace(cpfCPF, " ", "")
                    If Len(cpfCPF) = 11 Then
                        On Error Resume Next
                        dictCPF.Add nomeCPF, cpfCPF
                        On Error GoTo 0
                    End If
                End If
            End If
        End If
    Next
    WScript.Echo "CPFs loaded: " & dictCPF.Count
Else
    WScript.Echo "dados.txt NOT FOUND"
End If

WScript.Echo "DONE"
