' ============================================================================
' SCRIPT EDUCACENSO - AUTOMACAO DE TURMAS E PROFISSIONAIS
' Versao: 6.1 DUAL-MODE - ALUNOS E PROFISSIONAIS ESCOLARES
' Formato de Salvamento recomendado: ANSI
' ============================================================================
Option Explicit

Dim shell, fso, pastaAtual
Dim linha, cpf, nomeAluno, cpfFormatado, fFim
Dim regexCpf
Dim itensFltr(), totalFltr
Dim numTurma, menuTexto, encontrouTurma
Dim stream, conteudoArquivo, linhasArquivo
Dim i, idx, resposta, reqId, tempoEspera, numContagem
Dim caminhoCtrlIn, caminhoCtrlOut
Dim fResp, conteudoResp, partesResp
Dim turmas()
Dim n, tipoOperacao, labelItem, labelPlural, senhaDigitada

Set shell = CreateObject("WScript.Shell")
Set fso   = CreateObject("Scripting.FileSystemObject")

pastaAtual = fso.GetParentFolderName(WScript.ScriptFullName)

On Error Resume Next
shell.Run "powercfg /change standby-timeout-ac 0", 0, False
shell.Run "powercfg /change hibernate-timeout-ac 0", 0, False
On Error Goto 0

Call ExibirTelaSenha
If senhaDigitada <> "22062011" Then WScript.Quit

' Clean stale files from previous runs
On Error Resume Next
fso.DeleteFile pastaAtual & "\cdp_cmd.txt", True
fso.DeleteFile pastaAtual & "\cdp_resp.txt", True
fso.DeleteFile pastaAtual & "\cdp_ready.txt", True
fso.DeleteFile pastaAtual & "\cdp_server.pid", True
On Error GoTo 0

Set regexCpf = CreateObject("VBScript.RegExp")
regexCpf.Pattern = "\d{3}[\.\s]?\d{3}[\.\s]?\d{3}[\-\s]?\d{2}"
regexCpf.Global = False
regexCpf.IgnoreCase = True
caminhoCtrlIn  = pastaAtual & "\ctrl_in.txt"
caminhoCtrlOut = pastaAtual & "\ctrl_out.txt"

Call InicializarTurmas()

If fso.FileExists(pastaAtual & "\assistente_temp.vbs") Then ApagarComRetry pastaAtual & "\assistente_temp.vbs"
If fso.FileExists(caminhoCtrlIn) Then ApagarComRetry caminhoCtrlIn
If fso.FileExists(caminhoCtrlOut) Then ApagarComRetry caminhoCtrlOut
If fso.FileExists(pastaAtual & "\painel_controle.hta") Then ApagarComRetry pastaAtual & "\painel_controle.hta"

If Not fso.FileExists(pastaAtual & "\dados.txt") Then
    shell.Popup "Arquivo dados.txt nao encontrado!", 0, "Erro", 16
    WScript.Quit
End If

Call LerArquivoDados()

' Constroi dicionario nome->CPF (unica consulta, evita buscar a cada CPF)
Call CarregarDictCPF()

' ============================================================================
' SELETOR DE MODULO (ALUNOS OU PROFISSIONAIS)
' ============================================================================
Call GerarSeletorModuloHTA()
Dim caminhoModuloChoice, moduloChoice, fModChoice
caminhoModuloChoice = pastaAtual & "\modulo_choice.txt"
If fso.FileExists(caminhoModuloChoice) Then fso.DeleteFile caminhoModuloChoice
moduloChoice = ""

shell.Run "mshta.exe """ & pastaAtual & "\seletor_modulo.hta""", 1, False

Dim esperaModulo
esperaModulo = 0
Do
    WScript.Sleep 100
    esperaModulo = esperaModulo + 1
    If fso.FileExists(caminhoModuloChoice) Then
        On Error Resume Next
        Set fModChoice = fso.OpenTextFile(caminhoModuloChoice, 1)
        If Err.Number = 0 Then moduloChoice = Trim(fModChoice.ReadAll)
        If IsObject(fModChoice) Then fModChoice.Close
        On Error Goto 0
        If moduloChoice = "1" Or moduloChoice = "2" Or moduloChoice = "3" Or moduloChoice = "4" Or moduloChoice = "5" Then
            tipoOperacao = moduloChoice
            Exit Do
        ElseIf moduloChoice = "x" Then
            WScript.Quit
        End If
    End If
    If Not fso.FileExists(pastaAtual & "\seletor_modulo.hta") Then
        WScript.Quit
    End If
    If esperaModulo > 50 Then WScript.Quit
Loop

Set fModChoice = Nothing
On Error Resume Next
Call ApagarComRetry(pastaAtual & "\seletor_modulo.hta")
Call ApagarComRetry(pastaAtual & "\modulo_choice.txt")
On Error Goto 0

' ============================================================================
' CARREGA ENDERECOS
' ============================================================================
Call CarregarEnderecos()
Call CarregarTransporte()
Call CarregarTransporteNao()
Call CarregarEspeciais()

' ============================================================================
' MODO CONFERENCIA TRANSPORTE (modulo 3)
' ============================================================================
If tipoOperacao = "3" Then
    If totalTransporte = 0 Then
        shell.Popup "Nenhum aluno de transporte carregado. Verifique transporte.txt.", 0, "Erro", 16
        WScript.Quit
    End If
    shell.Popup "Conferencia de " & totalTransporte & " alunos do transporte." & vbCrLf & _
                "Acesse o Educacenso com a lista de alunos exibida" & vbCrLf & _
                "e posicione o mouse sobre o campo CPF do primeiro aluno.", _
                0, "Conferencia Transporte", 64 + 4096
    IniciarCDPServer
    GerarPainelHTA
    shell.Run "mshta.exe """ & pastaAtual & "\painel_controle.hta""", 1, False
    WScript.Sleep 100
    Call ExecutarLoopTransporte
    Set fFim = fso.CreateTextFile(caminhoCtrlIn, True)
    fFim.Write "FIM|" & totalTransporte & "|" & totalTransporte & "||CONFERENCIA TRANSPORTE|aluno(s)|||||"
    fFim.Close
    WScript.Sleep 800
    Set fFim = fso.CreateTextFile(caminhoCtrlIn, True)
    fFim.Write "CLOSE|"
    fFim.Close
    WScript.Quit
End If

' ============================================================================
' MODO CONFERENCIA ALUNOS ESPECIAIS (modulo 4)
' ============================================================================
If tipoOperacao = "4" Then
    If totalEspeciais = 0 Then
        shell.Popup "Nenhum aluno especial carregado. Verifique especiais.txt.", 0, "Erro", 16
        WScript.Quit
    End If
    shell.Popup "Conferencia de " & totalEspeciais & " alunos especiais." & vbCrLf & _
                "Acesse o Educacenso com a lista de alunos exibida" & vbCrLf & _
                "e posicione o mouse sobre o campo CPF do primeiro aluno.", _
                0, "Conferencia Especiais", 64 + 4096
    IniciarCDPServer
    GerarPainelHTA
    shell.Run "mshta.exe """ & pastaAtual & "\painel_controle.hta""", 1, False
    WScript.Sleep 100
    Call ExecutarLoopEspeciais
    Set fFim = fso.CreateTextFile(caminhoCtrlIn, True)
    fFim.Write "FIM|" & totalEspeciais & "|" & totalEspeciais & "||CONFERENCIA ESPECIAIS|aluno(s)|||||"
    fFim.Close
    WScript.Sleep 800
    Set fFim = fso.CreateTextFile(caminhoCtrlIn, True)
    fFim.Write "CLOSE|"
    fFim.Close
    WScript.Quit
End If

' ============================================================================
' MODO CONFERENCIA TRANSPORTE NAO (modulo 5)
' ============================================================================
If tipoOperacao = "5" Then
    If totalTranspNao = 0 Then
        shell.Popup "Nenhum aluno sem transporte carregado. Verifique transporte_nao.txt.", 0, "Erro", 16
        WScript.Quit
    End If
    shell.Popup "Conferencia de " & totalTranspNao & " alunos SEM transporte." & vbCrLf & _
                "Acesse o Educacenso com a lista de alunos exibida" & vbCrLf & _
                "e posicione o mouse sobre o campo CPF do primeiro aluno.", _
                0, "Conferencia Transporte (Nao)", 64 + 4096
    IniciarCDPServer
    GerarPainelHTA
    shell.Run "mshta.exe """ & pastaAtual & "\painel_controle.hta""", 1, False
    WScript.Sleep 100
    Call ExecutarLoopTransporteNao
    Set fFim = fso.CreateTextFile(caminhoCtrlIn, True)
    fFim.Write "FIM|" & totalTranspNao & "|" & totalTranspNao & "||CONFERENCIA TRANSPORTE (NAO)|aluno(s)|||||"
    fFim.Close
    WScript.Sleep 800
    Set fFim = fso.CreateTextFile(caminhoCtrlIn, True)
    fFim.Write "CLOSE|"
    fFim.Close
    WScript.Quit
End If

' ============================================================================
' GERA PAINEL HTA PARA MODULOS 1 E 2 (foi deletado na inicializacao)
' ============================================================================
GerarPainelHTA

' ============================================================================
' LOOP PRINCIPAL - PERCORRE TURMAS SEQUENCIALMENTE
' ============================================================================
Dim saiuPorSair

Do
    saiuPorSair = False

    ' SELETOR DE TURMA
    idx = SelecionarTurmaViaHTA()
    If idx < 1 Or idx > 21 Then Exit Do

    ' Limpa dados de controle anteriores
    If fso.FileExists(caminhoCtrlIn) Then ApagarComRetry caminhoCtrlIn
    If fso.FileExists(caminhoCtrlOut) Then ApagarComRetry caminhoCtrlOut

    ' Define o modo de varredura
    If tipoOperacao = "1" Then
        Call FiltrarTurmaPorCabecalhoReal(idx)
        labelItem = "ALUNO"
        labelPlural = "aluno(s)"
    Else
        Call FiltrarProfissionaisPorTurma(idx)
        labelItem = "PROFISSIONAL"
        labelPlural = "profissional(is)"
    End If

    ' Validacoes de erro e redirecionamentos
    If Not encontrouTurma Then
        shell.Popup "Turma nao encontrada no dados.txt.", 0, "Erro", 16
        WScript.Quit
    End If

    If totalFltr = 0 Then
        If tipoOperacao = "1" Then
            shell.Popup "Turma localizada, mas nenhum ALUNO com CPF valido foi filtrado!", 0, "Aviso", 48
        Else
            shell.Popup "Turma localizada, mas nenhum PROFISSIONAL ESCOLAR com CPF valido foi filtrado!", 0, "Aviso", 48
        End If
        WScript.Quit
    End If

    ' Tenta iniciar CDP server (opcional - se porta 9222 estiver disponivel)
    IniciarCDPServer

    ' Aviso para usuario preparar o navegador (10s, auto-close)
    shell.Popup "Turma: " & turmas(idx, 0) & " (" & totalFltr & " " & labelPlural & " carregados)." & vbCrLf & _
                "Acesse a pagina da turma no Educacenso e posicione o mouse" & vbCrLf & _
                "sobre o campo CPF.", _
                0, "Preparando - Educacenso", 64 + 4096
    WScript.Sleep 500
    shell.Run "mshta.exe """ & pastaAtual & "\painel_controle.hta""", 1, False
    WScript.Sleep 100

    Call ExecutarLoopCPF

    ' Verifica se usuario clicou SAIR (0) para encerrar tudo
    If saiuPorSair Then Exit Do

    ' Sinaliza FIM no painel
    Set fFim = fso.CreateTextFile(caminhoCtrlIn, True)
    fFim.Write "FIM|" & totalFltr & "|" & totalFltr & "||" & turmas(idx, 0) & "|" & labelPlural & "|||||"
    fFim.Close
    WScript.Sleep 800

    ' Fecha painel de fluxo via comando CLOSE
    Set fFim = fso.CreateTextFile(caminhoCtrlIn, True)
    fFim.Write "CLOSE|"
    fFim.Close
    WScript.Sleep 100

    ' Limpa arquivos de controle
    On Error Resume Next
    fso.DeleteFile caminhoCtrlIn, True
    fso.DeleteFile caminhoCtrlOut, True
    On Error GoTo 0

    shell.Popup "Turma concluida! Selecione a proxima turma.", 2, "Concluido", 64
Loop

' Limpeza geral de cache
Call LimparCache

On Error Resume Next
shell.Run "powercfg /change standby-timeout-ac 30", 0, True
shell.Run "powercfg /change hibernate-timeout-ac 30", 0, True
On Error Goto 0

WScript.Quit

' ============================================================================
' FUNCAO PARA ABRIR URL PREFERENCIALMENTE NO GOOGLE CHROME
' ============================================================================
Sub AbrirURLNoChrome(url)
    Dim caminhoChrome, encontrouChrome
    encontrouChrome = False
    
    ' Caminhos comuns de instalacao do Chrome
    Dim caminhosChrome(4)
    caminhosChrome(0) = shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\Google\Chrome\Application\chrome.exe"
    caminhosChrome(1) = shell.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & "\Google\Chrome\Application\chrome.exe"
    caminhosChrome(2) = shell.ExpandEnvironmentStrings("%LocalAppData%") & "\Google\Chrome\Application\chrome.exe"
    caminhosChrome(3) = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    caminhosChrome(4) = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    
    Dim j
    For j = 0 To 4
        If fso.FileExists(caminhosChrome(j)) Then
            caminhoChrome = caminhosChrome(j)
            encontrouChrome = True
            Exit For
        End If
    Next
    
    If encontrouChrome Then
        ' Usa --new-tab para garantir abertura mesmo com Chrome ja aberto
        shell.Run """" & caminhoChrome & """ --new-tab """ & url & """", 1, False
    Else
        On Error Resume Next
        shell.Run "chrome --new-tab """ & url & """", 1, False
        If Err.Number <> 0 Then
            Err.Clear
            ' Ultimo recurso: abre no navegador padrao
            shell.Run url, 1, False
        End If
        On Error GoTo 0
    End If
End Sub

Sub InicializarTurmas()
    ReDim turmas(21, 1)

    turmas(1, 0)  = "1 ANO A MATUTINO"               : turmas(1, 1)  = "1" & ChrW(186) & " ANO A MATUTINO"
    turmas(2, 0)  = "1 ANO B VESPERTINO"             : turmas(2, 1)  = "1" & ChrW(186) & " ANO B"
    turmas(3, 0)  = "2 ANO A MATUTINO"               : turmas(3, 1)  = "2" & ChrW(186) & " ANO A MATUTINO"
    turmas(4, 0)  = "2 ANO B VESPERTINO"             : turmas(4, 1)  = "2" & ChrW(186) & " ANO B"
    turmas(5, 0)  = "3 ANO A MATUTINO"               : turmas(5, 1)  = "3" & ChrW(186) & " ANO A MATUTINO"
    turmas(6, 0)  = "3 ANO B VESPERTINO"             : turmas(6, 1)  = "3" & ChrW(186) & " ANO B"
    turmas(7, 0)  = "4 ANO A MATUTINO"               : turmas(7, 1)  = "4" & ChrW(186) & " ANO A MATUTINO"
    turmas(8, 0)  = "4 ANO B VESPERTINO"             : turmas(8, 1)  = "4" & ChrW(186) & " ANO B"
    turmas(9, 0)  = "5 ANO A MATUTINO"               : turmas(9, 1)  = "5" & ChrW(186) & " ANO A MATUTINO"
    turmas(10, 0) = "5 ANO B VESPERTINO"             : turmas(10, 1) = "5" & ChrW(186) & " ANO B"
    turmas(11, 0) = "6 ANO A MATUTINO"               : turmas(11, 1) = "6" & ChrW(186) & " ANO A MATUTINO"
    turmas(12, 0) = "6 ANO B VESPERTINO"             : turmas(12, 1) = "6" & ChrW(186) & " ANO B"
    turmas(13, 0) = "AEE A MATUTINO"                 : turmas(13, 1) = "AEE A MATUTINO"
    turmas(14, 0) = "AEE B VESPERTINO"               : turmas(14, 1) = "AEE B VESPERTINO"
    turmas(15, 0) = "ETI TURMA A 1 AO 3 MATUTINO"    : turmas(15, 1) = "ETI TURMA A 1 AO"
    turmas(16, 0) = "ETI TURMA B 1 AO 3 VESPERTINO"  : turmas(16, 1) = "ETI TURMA B 1 AO"
    turmas(17, 0) = "ETI TURMA A 4 E 5 MATUTINO"     : turmas(17, 1) = "ETI TURMA A 4 E 5"
    turmas(18, 0) = "ETI TURMA B 4 E 5 VESPERTINO"   : turmas(18, 1) = "ETI TURMA B 4 E 5"
    turmas(19, 0) = "4 PERIODO EJA U I"              : turmas(19, 1) = "4 PERIODO EJA U I"
    turmas(20, 0) = "3 PERIODO EJA U II"             : turmas(20, 1) = "3 PERIODO EJA U II"
    turmas(21, 0) = "4 PERIODO EJA U II"             : turmas(21, 1) = "4 PERIODO EJA U II"
End Sub

Sub LerArquivoDados()
    On Error Resume Next

    Set stream = CreateObject("ADODB.Stream")
    stream.Open
    stream.Type = 2
    stream.Charset = "utf-8"
    stream.LoadFromFile pastaAtual & "\dados.txt"
    conteudoArquivo = stream.ReadText
    stream.Close

    If Err.Number <> 0 Then
        Err.Clear
        Set stream = fso.OpenTextFile(pastaAtual & "\dados.txt", 1, False, -2)
        conteudoArquivo = stream.ReadAll
        stream.Close
    End If

    On Error GoTo 0

    conteudoArquivo = Replace(conteudoArquivo, vbCrLf, vbLf)
    conteudoArquivo = Replace(conteudoArquivo, vbCr, vbLf)
    linhasArquivo = Split(conteudoArquivo, vbLf)
End Sub

Sub FiltrarTurmaPorCabecalhoReal(indiceTurma)
    Dim cabecalhoAlvo, dentroDaTurma
    Dim partesLinha, cpfLinha, nomeLinha, racaLinha, dtNascLinha, iLoop

    encontrouTurma = False
    dentroDaTurma = False
    totalFltr = 0
    ReDim itensFltr(0)

    cabecalhoAlvo = Normalizar(turmas(indiceTurma, 1))

    For iLoop = 0 To UBound(linhasArquivo)
        linha = Trim(linhasArquivo(iLoop))

        If linha <> "" Then
            If InStr(1, Normalizar(linha), "TURMA:", 1) > 0 Then
                If InStr(1, Normalizar(linha), cabecalhoAlvo, 1) > 0 Then
                    encontrouTurma = True
                    dentroDaTurma = True
                ElseIf dentroDaTurma Then
                    Exit For
                End If
            ElseIf dentroDaTurma Then
                If EhLinhaAlunoTabulada(linha) Then
                    partesLinha = Split(linha, vbTab)

                    If UBound(partesLinha) >= 5 Then
                        nomeLinha = Trim(partesLinha(1))
                        racaLinha = Trim(partesLinha(2))
                        cpfLinha = ExtrairCPFNumerico(partesLinha(3))
                        dtNascLinha = Trim(partesLinha(5))

                        If nomeLinha <> "" And Len(cpfLinha) = 11 Then
                            totalFltr = totalFltr + 1
                            ReDim Preserve itensFltr(totalFltr)
                            itensFltr(totalFltr) = nomeLinha & "|" & cpfLinha & "|" & racaLinha & "|" & dtNascLinha
                        End If
                    End If
                End If
            End If
        End If
    Next
End Sub

Sub FiltrarProfissionaisPorTurma(indiceTurma)
    Dim cabecalhoAlvo
    Dim iLoop, L_target, idxTopo, idxFundo
    Dim partesP, col0, col1, extCpf
    
    encontrouTurma = False
    totalFltr = 0
    ReDim itensFltr(0)
    
    cabecalhoAlvo = Normalizar(turmas(indiceTurma, 1))
    
    L_target = -1
    For iLoop = 0 To UBound(linhasArquivo)
        linha = Trim(linhasArquivo(iLoop))
        If InStr(1, Normalizar(linha), "TURMA:", 1) > 0 Then
            If InStr(1, Normalizar(linha), cabecalhoAlvo, 1) > 0 Then
                L_target = iLoop
                encontrouTurma = True
                Exit For
            End If
        End If
    Next
    
    ' Se a turma foi localizada, mapeia o bloco ao redor do cabecalho onde os profissionais ficam
    If L_target <> -1 Then
        idxTopo = L_target - 1
        Do While idxTopo >= 0
            If InStr(1, Normalizar(linhasArquivo(idxTopo)), "TURMA:", 1) > 0 Then Exit Do
            idxTopo = idxTopo - 1
        Loop
        idxTopo = idxTopo + 1
        
        idxFundo = L_target + 1
        Do While idxFundo <= UBound(linhasArquivo)
            If InStr(1, Normalizar(linhasArquivo(idxFundo)), "TURMA:", 1) > 0 Then Exit Do
            idxFundo = idxFundo + 1
        Loop
        idxFundo = idxFundo - 1
        
        ' Itera apenas na area da turma para achar os Profissionais (Coluna 0 = Nome, Coluna 1 = CPF)
        For iLoop = idxTopo To idxFundo
            linha = Trim(linhasArquivo(iLoop))
            If InStr(linha, vbTab) > 0 Then
                partesP = Split(linha, vbTab)
                If UBound(partesP) >= 1 Then
                    col0 = Trim(partesP(0))
                    col1 = Trim(partesP(1))
                    
                    ' Diferencia o Profissional do Aluno pois o Aluno tem numeracao de chamada na col 0 e CPF na col 3
                    If col0 <> "" And Not IsNumeric(col0) Then
                        extCpf = ExtrairCPFNumerico(col1)
                        If Len(extCpf) = 11 Then
                            totalFltr = totalFltr + 1
                            ReDim Preserve itensFltr(totalFltr)
                            itensFltr(totalFltr) = col0 & "|" & extCpf
                        End If
                    End If
                End If
            End If
        Next
    End If
End Sub

Function EhLinhaAlunoTabulada(linhaTeste)
    Dim pTest, ordemTxt, cpfTxt

    EhLinhaAlunoTabulada = False

    If InStr(linhaTeste, vbTab) = 0 Then Exit Function
    pTest = Split(linhaTeste, vbTab)
    If UBound(pTest) < 3 Then Exit Function

    ordemTxt = Trim(pTest(0))
    cpfTxt = Trim(pTest(3))

    If Not IsNumeric(ordemTxt) Then Exit Function
    If Not regexCpf.Test(cpfTxt) Then Exit Function

    EhLinhaAlunoTabulada = True
End Function

Function Normalizar(texto)
    Dim t
    t = UCase(Trim(texto))

    t = Replace(t, ChrW(186), "")
    t = Replace(t, ChrW(170), "")
    t = Replace(t, ChrW(176), "")

    t = Replace(t, ChrW(193), "A")
    t = Replace(t, ChrW(192), "A")
    t = Replace(t, ChrW(194), "A")
    t = Replace(t, ChrW(195), "A")
    t = Replace(t, ChrW(196), "A")

    t = Replace(t, ChrW(201), "E")
    t = Replace(t, ChrW(200), "E")
    t = Replace(t, ChrW(202), "E")
    t = Replace(t, ChrW(203), "E")

    t = Replace(t, ChrW(205), "I")
    t = Replace(t, ChrW(204), "I")
    t = Replace(t, ChrW(206), "I")
    t = Replace(t, ChrW(207), "I")

    t = Replace(t, ChrW(211), "O")
    t = Replace(t, ChrW(210), "O")
    t = Replace(t, ChrW(212), "O")
    t = Replace(t, ChrW(213), "O")
    t = Replace(t, ChrW(214), "O")

    t = Replace(t, ChrW(218), "U")
    t = Replace(t, ChrW(217), "U")
    t = Replace(t, ChrW(219), "U")
    t = Replace(t, ChrW(220), "U")

    t = Replace(t, ChrW(199), "C")

    t = Replace(t, Chr(9), " ")
    t = Replace(t, Chr(160), " ")
    t = Replace(t, "-", " ")
    t = Replace(t, "_", " ")
    t = Replace(t, "/", " ")
    t = Replace(t, "\", " ")
    t = Replace(t, ".", " ")
    t = Replace(t, ",", " ")
    t = Replace(t, ";", " ")
    t = Replace(t, ":", ":")
    t = Replace(t, "(", " ")
    t = Replace(t, ")", " ")
    t = Replace(t, "[", " ")
    t = Replace(t, "]", " ")

    Do While InStr(t, "  ") > 0
        t = Replace(t, "  ", " ")
    Loop

    Normalizar = Trim(t)
End Function

Function FormatarCPF(c)
    If Len(c) = 11 Then
        FormatarCPF = Left(c, 3) & "." & Mid(c, 4, 3) & "." & Mid(c, 7, 3) & "-" & Right(c, 2)
    Else
        FormatarCPF = c
    End If
End Function

Function ExtrairCPFNumerico(texto)
    Dim mt, c
    ExtrairCPFNumerico = ""

    If regexCpf.Test(texto) Then
        Set mt = regexCpf.Execute(texto)
        If mt.Count > 0 Then
            c = mt(0).Value
            c = Replace(c, ".", "")
            c = Replace(c, "-", "")
            c = Replace(c, " ", "")
            ExtrairCPFNumerico = Trim(c)
        End If
    End If
End Function

Sub ApagarComRetry(caminho)
    On Error Resume Next
    fso.DeleteFile caminho, True
    If Err.Number = 0 Then On Error GoTo 0: Exit Sub
    On Error GoTo 0

    Dim tRetry
    tRetry = 0
    Do While fso.FileExists(caminho) And tRetry < 5
        WScript.Sleep 100
        On Error Resume Next
        fso.DeleteFile caminho, True
        On Error GoTo 0
        tRetry = tRetry + 1
    Loop
End Sub

Sub LimparCache()
    Dim cacheFiles
    cacheFiles = Array( _
        "\painel_controle.hta", _
        "\tela_senha.hta", _
        "\senha_resp.txt", _
        "\seletor_modulo.hta", _
        "\seletor_turma.hta", _
        "\modulo_choice.txt", _
        "\sel_turma_resp.txt", _
        "\ctrl_in.txt", _
        "\ctrl_out.txt", _
        "\temp_pos.txt", _
        "\assistente_temp.vbs", _
        "\cpf_click.dll", _
        "\cdp_cmd.txt", _
        "\cdp_resp.txt", _
        "\cdp_ready.txt", _
        "\cdp_server.pid" _
    )
    Dim iFile
    For iFile = 0 To UBound(cacheFiles)
        Call ApagarComRetry(pastaAtual & cacheFiles(iFile))
    Next
End Sub

Function FocarNavegador()
    Dim tentativa
    For tentativa = 1 To 5
        If shell.AppActivate("Educacenso") Then FocarNavegador = True: Exit Function
        If shell.AppActivate("INEP") Then FocarNavegador = True: Exit Function
        If shell.AppActivate("Google Chrome") Then FocarNavegador = True: Exit Function
        If shell.AppActivate("Microsoft Edge") Then FocarNavegador = True: Exit Function
        WScript.Sleep 300
    Next
    FocarNavegador = False
End Function

Function EnviarCPFComEstabilidade(cpfNumero)
    Dim comando
    comando = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
              pastaAtual & "\focar_cpf.ps1"" " & cpfNumero
    shell.Run comando, 0, True
    EnviarCPFComEstabilidade = True
End Function

Dim enderecos()
Dim totalEnderecos
Dim dictTransporte
Dim transportesLista()
Dim totalTransporte
Dim dictCPF
Dim statusTransporte()
Dim dictEspeciais
Dim especiaisLista()
Dim totalEspeciais
Dim statusEspeciais()
Dim deficienciasLista()
Dim recursoLista()
Dim transporteEspecialLista()
Dim aeeLista()
Dim apoioLista()
Dim dictTranspNao
Dim transpNaoLista()
Dim totalTranspNao
Dim statusTranspNao()

Sub CarregarEnderecos()
    Dim caminhoEnd, streamEnd, conteudoEnd, linhasEnd, iEnd
    Dim partesEnd
    totalEnderecos = 0
    ReDim enderecos(0)

    caminhoEnd = pastaAtual & "\enderecos.txt"
    If Not fso.FileExists(caminhoEnd) Then Exit Sub

    On Error Resume Next
    Set streamEnd = CreateObject("ADODB.Stream")
    streamEnd.Open
    streamEnd.Type = 2
    streamEnd.Charset = "utf-8"
    streamEnd.LoadFromFile caminhoEnd
    conteudoEnd = streamEnd.ReadText
    streamEnd.Close
    If Err.Number <> 0 Then
        Err.Clear
        Set streamEnd = fso.OpenTextFile(caminhoEnd, 1, False, -2)
        conteudoEnd = streamEnd.ReadAll
        streamEnd.Close
    End If
    On Error GoTo 0

    conteudoEnd = Replace(conteudoEnd, vbCrLf, vbLf)
    conteudoEnd = Replace(conteudoEnd, vbCr, vbLf)
    linhasEnd = Split(conteudoEnd, vbLf)

    For iEnd = 0 To UBound(linhasEnd)
        linha = Trim(linhasEnd(iEnd))
        If linha <> "" And InStr(linha, "|") > 0 Then
            ' Pula cabeçalho se existir
            If InStr(1, UCase(linha), "TURMA") > 0 And InStr(1, UCase(linha), "NOME") > 0 Then
                ' ignora linha de cabeçalho
            Else
                totalEnderecos = totalEnderecos + 1
                ReDim Preserve enderecos(totalEnderecos)
                enderecos(totalEnderecos) = linha
            End If
        End If
    Next
End Sub

Function BuscarEndereco(turmaAlvo, nomeAlvo)
    Dim iB, partesB, turmaB, nomeB, logr, num, bairro, cidade, uf, cepEnd
    Dim turmaNorm, nomeNorm
    BuscarEndereco = "ENDERE" & ChrW(199) & "O N" & ChrW(195) & "O LOCALIZADO"

    If totalEnderecos = 0 Then Exit Function

    turmaNorm = Normalizar(turmaAlvo)
    nomeNorm = Normalizar(nomeAlvo)

    For iB = 1 To totalEnderecos
        partesB = Split(enderecos(iB), "|")
        If UBound(partesB) >= 8 Then
            turmaB = Normalizar(Trim(partesB(0)))
            nomeB = Normalizar(Trim(partesB(1)))
            If turmaB = turmaNorm And nomeB = nomeNorm Then
                logr = Trim(partesB(3))
                num = Trim(partesB(4))
                bairro = Trim(partesB(5))
                cidade = Trim(partesB(6))
                uf = Trim(partesB(7))
                cepEnd = Trim(partesB(8))
                BuscarEndereco = logr & ", " & num & " - " & bairro & ", " & cidade & "-" & uf
                If cepEnd <> "" Then BuscarEndereco = BuscarEndereco & " CEP: " & cepEnd
                Exit Function
            End If
        End If
    Next
End Function

Sub CarregarDictCPF()
    Dim iCPF, linhaCPF, partesCPF, nomeCPF, cpfCPF
    Set dictCPF = CreateObject("Scripting.Dictionary")
    For iCPF = 0 To UBound(linhasArquivo)
        linhaCPF = Trim(linhasArquivo(iCPF))
        If EhLinhaAlunoTabulada(linhaCPF) Then
            partesCPF = Split(linhaCPF, vbTab)
            If UBound(partesCPF) >= 3 Then
                nomeCPF = Normalizar(Trim(partesCPF(1)))
                cpfCPF = ExtrairCPFNumerico(Trim(partesCPF(3)))
                If nomeCPF <> "" And Len(cpfCPF) = 11 Then
                    On Error Resume Next
                    dictCPF.Add nomeCPF, cpfCPF
                    If Err.Number <> 0 Then Err.Clear
                    On Error GoTo 0
                End If
            End If
        End If
    Next
End Sub

Sub CarregarTransporte()
    Dim caminhoTp, streamTp, conteudoTp, linhasTp, iTp, partesTp, nomeTp, zonaTp
    Set dictTransporte = CreateObject("Scripting.Dictionary")
    totalTransporte = 0
    ReDim transportesLista(0)
    ReDim statusTransporte(0)
    caminhoTp = pastaAtual & "\transporte.txt"
    If Not fso.FileExists(caminhoTp) Then Exit Sub
    On Error Resume Next
    Set streamTp = CreateObject("ADODB.Stream")
    streamTp.Open
    streamTp.Type = 2
    streamTp.Charset = "utf-8"
    streamTp.LoadFromFile caminhoTp
    conteudoTp = streamTp.ReadText
    Dim errTp: errTp = Err.Number
    streamTp.Close
    If errTp <> 0 Then
        Err.Clear
        Set streamTp = CreateObject("ADODB.Stream")
        streamTp.Open
        streamTp.Type = 2
        streamTp.Charset = "unicode"
        streamTp.LoadFromFile caminhoTp
        conteudoTp = streamTp.ReadText
        errTp = Err.Number
        streamTp.Close
        If errTp <> 0 Then
            Err.Clear
            Set streamTp = fso.OpenTextFile(caminhoTp, 1, False, -2)
            conteudoTp = streamTp.ReadAll
            streamTp.Close
        End If
    End If
    On Error GoTo 0
    conteudoTp = Replace(conteudoTp, vbCrLf, vbLf)
    conteudoTp = Replace(conteudoTp, vbCr, vbLf)
    linhasTp = Split(conteudoTp, vbLf)
    For iTp = 0 To UBound(linhasTp)
        linha = Trim(linhasTp(iTp))
        If linha <> "" And InStr(linha, "|") > 0 Then
            partesTp = Split(linha, "|")
            If UBound(partesTp) >= 1 Then
                nomeTp = Normalizar(Trim(partesTp(0)))
                zonaTp = UCase(Trim(partesTp(1)))
                If nomeTp <> "" And (zonaTp = "URBANA" Or zonaTp = "RURAL") Then
                    On Error Resume Next
                    dictTransporte.Add nomeTp, zonaTp
                    If Err.Number <> 0 Then Err.Clear
                    On Error GoTo 0
                    totalTransporte = totalTransporte + 1
                    ReDim Preserve transportesLista(totalTransporte)
                    transportesLista(totalTransporte) = nomeTp & "|" & zonaTp
                    ReDim Preserve statusTransporte(totalTransporte)
                    statusTransporte(totalTransporte) = ""
                End If
            End If
        End If
    Next
End Sub

Sub SalvarStatusTransporte()
    Dim iIdx, fS, partesS, nomeS, zonaS, statusS, streamOut, linhaOut
    If totalTransporte < 1 Then Exit Sub
    On Error Resume Next
    Set streamOut = CreateObject("ADODB.Stream")
    streamOut.Open
    streamOut.Type = 2
    streamOut.Charset = "utf-8"
    For iIdx = 1 To totalTransporte
        partesS = Split(transportesLista(iIdx), "|")
        nomeS = partesS(0)
        zonaS = partesS(1)
        statusS = ""
        statusS = statusTransporte(iIdx)
        If Err.Number <> 0 Then statusS = ""
        Err.Clear
        If statusS = "" Then statusS = "PENDENTE"
        streamOut.WriteText nomeS & "|" & zonaS & "|" & statusS & vbCrLf
    Next
    streamOut.SaveToFile pastaAtual & "\transporte.txt", 2
    streamOut.Close
    On Error GoTo 0
End Sub

Function BuscarTransporte(nomeAlvo)
    Dim nomeNorm
    BuscarTransporte = ""
    If dictTransporte Is Nothing Then Exit Function
    If dictTransporte.Count = 0 Then Exit Function
    nomeNorm = Normalizar(nomeAlvo)
    If dictTransporte.Exists(nomeNorm) Then
        BuscarTransporte = dictTransporte(nomeNorm)
    End If
End Function

Sub CarregarTransporteNao()
    Dim caminhoTn, streamTn, conteudoTn, linhasTn, iTn, partesTn, nomeTn, zonaTn, turmaTn, cpfTn
    Set dictTranspNao = CreateObject("Scripting.Dictionary")
    totalTranspNao = 0
    ReDim transpNaoLista(0)
    ReDim statusTranspNao(0)
    caminhoTn = pastaAtual & "\transporte_nao.txt"
    If Not fso.FileExists(caminhoTn) Then Exit Sub
    On Error Resume Next
    Set streamTn = CreateObject("ADODB.Stream")
    streamTn.Open
    streamTn.Type = 2
    streamTn.Charset = "utf-8"
    streamTn.LoadFromFile caminhoTn
    conteudoTn = streamTn.ReadText
    Dim errTn: errTn = Err.Number
    streamTn.Close
    If errTn <> 0 Then
        Err.Clear
        Set streamTn = CreateObject("ADODB.Stream")
        streamTn.Open
        streamTn.Type = 2
        streamTn.Charset = "unicode"
        streamTn.LoadFromFile caminhoTn
        conteudoTn = streamTn.ReadText
        errTn = Err.Number
        streamTn.Close
        If errTn <> 0 Then
            Err.Clear
            Set streamTn = fso.OpenTextFile(caminhoTn, 1, False, -2)
            conteudoTn = streamTn.ReadAll
            streamTn.Close
        End If
    End If
    On Error GoTo 0
    conteudoTn = Replace(conteudoTn, vbCrLf, vbLf)
    conteudoTn = Replace(conteudoTn, vbCr, vbLf)
    linhasTn = Split(conteudoTn, vbLf)
    For iTn = 0 To UBound(linhasTn)
        linha = Trim(linhasTn(iTn))
        If linha <> "" And InStr(linha, "|") > 0 Then
            partesTn = Split(linha, "|")
            If UBound(partesTn) >= 2 Then
                nomeTn = Normalizar(Trim(partesTn(0)))
                zonaTn = UCase(Trim(partesTn(1)))
                turmaTn = Trim(partesTn(2))
                cpfTn = ""
                If UBound(partesTn) >= 3 Then cpfTn = Trim(partesTn(3))
                If nomeTn <> "" And (zonaTn = "URBANA" Or zonaTn = "RURAL") Then
                    On Error Resume Next
                    dictTranspNao.Add nomeTn, zonaTn & "|" & turmaTn & "|" & cpfTn
                    If Err.Number <> 0 Then Err.Clear
                    On Error GoTo 0
                    totalTranspNao = totalTranspNao + 1
                    ReDim Preserve transpNaoLista(totalTranspNao)
                    transpNaoLista(totalTranspNao) = nomeTn & "|" & zonaTn & "|" & turmaTn & "|" & cpfTn
                    ReDim Preserve statusTranspNao(totalTranspNao)
                    statusTranspNao(totalTranspNao) = ""
                End If
            End If
        End If
    Next
End Sub

Sub SalvarStatusTransporteNao()
    Dim iIdxN, fSN, partesSN, nomeSN, zonaSN, turmaSN, cpfSN, statusSN, streamOutN, linhaOutN
    If totalTranspNao < 1 Then Exit Sub
    On Error Resume Next
    Set streamOutN = CreateObject("ADODB.Stream")
    streamOutN.Open
    streamOutN.Type = 2
    streamOutN.Charset = "utf-8"
    For iIdxN = 1 To totalTranspNao
        partesSN = Split(transpNaoLista(iIdxN), "|")
        nomeSN = partesSN(0)
        zonaSN = partesSN(1)
        turmaSN = partesSN(2)
        cpfSN = ""
        If UBound(partesSN) >= 3 Then cpfSN = partesSN(3)
        statusSN = ""
        statusSN = statusTranspNao(iIdxN)
        If Err.Number <> 0 Then statusSN = ""
        Err.Clear
        If statusSN = "" Then statusSN = "PENDENTE"
        streamOutN.WriteText nomeSN & "|" & zonaSN & "|" & turmaSN & "|" & cpfSN & "|" & statusSN & vbCrLf
    Next
    streamOutN.SaveToFile pastaAtual & "\transporte_nao.txt", 2
    streamOutN.Close
    On Error GoTo 0
End Sub

Sub CarregarEspeciais()
    Dim caminhoEs, streamEs, conteudoEs, linhasEs, iEs, partesEs, nomeEs
    Set dictEspeciais = CreateObject("Scripting.Dictionary")
    totalEspeciais = 0
    ReDim especiaisLista(0)
    ReDim statusEspeciais(0)
    ReDim deficienciasLista(0)
    ReDim recursoLista(0)
    ReDim transporteEspecialLista(0)
    ReDim aeeLista(0)
    ReDim apoioLista(0)
    caminhoEs = pastaAtual & "\especiais.txt"
    If Not fso.FileExists(caminhoEs) Then Exit Sub
    On Error Resume Next
    Set streamEs = CreateObject("ADODB.Stream")
    streamEs.Open
    streamEs.Type = 2
    streamEs.Charset = "utf-8"
    streamEs.LoadFromFile caminhoEs
    conteudoEs = streamEs.ReadText
    Dim errEs: errEs = Err.Number
    streamEs.Close
    If errEs <> 0 Then
        Err.Clear
        Set streamEs = CreateObject("ADODB.Stream")
        streamEs.Open
        streamEs.Type = 2
        streamEs.Charset = "unicode"
        streamEs.LoadFromFile caminhoEs
        conteudoEs = streamEs.ReadText
        errEs = Err.Number
        streamEs.Close
        If errEs <> 0 Then
            Err.Clear
            Set streamEs = fso.OpenTextFile(caminhoEs, 1, False, -2)
            conteudoEs = streamEs.ReadAll
            streamEs.Close
        End If
    End If
    On Error GoTo 0
    conteudoEs = Replace(conteudoEs, vbCrLf, vbLf)
    conteudoEs = Replace(conteudoEs, vbCr, vbLf)
    linhasEs = Split(conteudoEs, vbLf)
    For iEs = 0 To UBound(linhasEs)
        linha = Trim(linhasEs(iEs))
        If linha <> "" And InStr(linha, "|") > 0 Then
            partesEs = Split(linha, "|")
            If UBound(partesEs) >= 1 Then
                nomeEs = Normalizar(Trim(partesEs(0)))
                If nomeEs <> "" Then
                    On Error Resume Next
                    dictEspeciais.Add nomeEs, True
                    If Err.Number <> 0 Then Err.Clear
                    On Error GoTo 0
                    totalEspeciais = totalEspeciais + 1
                    ReDim Preserve especiaisLista(totalEspeciais)
                    ReDim Preserve statusEspeciais(totalEspeciais)
                    ReDim Preserve deficienciasLista(totalEspeciais)
                    ReDim Preserve recursoLista(totalEspeciais)
                    ReDim Preserve transporteEspecialLista(totalEspeciais)
                    ReDim Preserve aeeLista(totalEspeciais)
                    ReDim Preserve apoioLista(totalEspeciais)
                    especiaisLista(totalEspeciais) = nomeEs
                    statusEspeciais(totalEspeciais) = ""
                    If UBound(partesEs) >= 1 Then deficienciasLista(totalEspeciais) = Trim(partesEs(1))
                    If UBound(partesEs) >= 2 Then recursoLista(totalEspeciais) = Trim(partesEs(2))
                    If UBound(partesEs) >= 3 Then transporteEspecialLista(totalEspeciais) = Trim(partesEs(3))
                    If UBound(partesEs) >= 4 Then aeeLista(totalEspeciais) = Trim(partesEs(4))
                    If UBound(partesEs) >= 5 Then apoioLista(totalEspeciais) = Trim(partesEs(5))
                End If
            End If
        End If
    Next
End Sub

Sub SalvarStatusEspeciais()
    Dim iIdxEs, statusSEs, streamOut, linhaOut
    If totalEspeciais < 1 Then Exit Sub
    On Error Resume Next
    Set streamOut = CreateObject("ADODB.Stream")
    streamOut.Open
    streamOut.Type = 2
    streamOut.Charset = "utf-8"
    For iIdxEs = 1 To totalEspeciais
        statusSEs = ""
        statusSEs = statusEspeciais(iIdxEs)
        If Err.Number <> 0 Then statusSEs = ""
        Err.Clear
        If statusSEs = "" Then statusSEs = "PENDENTE"
        streamOut.WriteText especiaisLista(iIdxEs) & "|" & deficienciasLista(iIdxEs) & "|" & recursoLista(iIdxEs) & "|" & transporteEspecialLista(iIdxEs) & "|" & aeeLista(iIdxEs) & "|" & apoioLista(iIdxEs) & "|" & statusSEs & vbCrLf
    Next
    streamOut.SaveToFile pastaAtual & "\especiais.txt", 2
    streamOut.Close
    On Error GoTo 0
End Sub

Function BuscarCPFAluno(nomeAlvo)
    Dim nomeNorm
    BuscarCPFAluno = ""
    If dictCPF Is Nothing Then Exit Function
    If dictCPF.Count = 0 Then Exit Function
    nomeNorm = Normalizar(nomeAlvo)
    If dictCPF.Exists(nomeNorm) Then
        BuscarCPFAluno = dictCPF(nomeNorm)
    End If
End Function

Sub ExecutarLoopTransporte()
    Dim nAluno, reqLocal, respLocal, ultimoReq, repCount, calibCount, comando
    Dim partesLocal, nomeLocal, zonaLocal, cpfLocal, cpfFmtLocal, statusMsg

    repCount = 0
    calibCount = 0
    ultimoReq = ""
    totalFltr = totalTransporte
    ReDim itensFltr(totalFltr)
    For nAluno = 1 To totalFltr
        partesLocal = Split(transportesLista(nAluno), "|")
        nomeLocal = partesLocal(0)
        zonaLocal = partesLocal(1)
        cpfLocal = BuscarCPFAluno(nomeLocal)
        ItensFltr(nAluno) = nomeLocal & "|" & cpfLocal & "|||"
    Next

    nAluno = 1
    Do While nAluno >= 1 And nAluno <= totalFltr
        partesLocal = Split(transportesLista(nAluno), "|")
        nomeLocal = partesLocal(0)
        zonaLocal = partesLocal(1)
        cpfLocal = BuscarCPFAluno(nomeLocal)
        cpfFmtLocal = FormatarCPF(cpfLocal)

        reqLocal = "R" & CStr(nAluno)

        If nAluno = 1 Then
            statusMsg = "Digitando CPF de " & nomeLocal & "..."
        ElseIf nAluno < totalFltr Then
            statusMsg = "Aguardando CPF ser digitado. Apos digitado, navegue ate o proximo e clique Avancar"
        Else
            statusMsg = "Ultimo aluno. Clique Avancar para encerrar."
        End If
        AtualizarPainel reqLocal, nAluno, totalFltr, cpfFmtLocal, "CONFERENCIA TRANSPORTE", nomeLocal, "ALUNO", "", "", "", statusMsg, zonaLocal, "", "", ""
        On Error Resume Next
        shell.AppActivate "Controle de Fluxo"
        On Error GoTo 0

        If cpfLocal = "" Then
            shell.Popup "CPF nao encontrado em dados.txt para: " & nomeLocal, 3, "CPF Ausente", 48
            respLocal = 7
        Else
            respLocal = AguardarCliqueOuPainel(cpfFmtLocal)
        End If

        Do While respLocal = 5
            respLocal = LerRespostaPainel(reqLocal)
            If respLocal = 5 Then respLocal = 7
            If respLocal = 8 Then
                shell.Popup "Posicione o mouse sobre o campo CPF para recalibrar.", 2, "Recalibracao", 64
                CalibrarPosicaoCPF
                respLocal = 5
            End If
        Loop

        If respLocal = 8 Then
            shell.Popup "Posicione o mouse sobre o campo CPF para recalibrar.", 2, "Recalibracao", 64
            CalibrarPosicaoCPF
            respLocal = 7
            repCount = 0
            calibCount = 0
        End If

        ' Atualiza status no banco (memoria)
        On Error Resume Next
        If respLocal = 1 Then statusTransporte(nAluno) = "OK"
        If respLocal = 7 Then statusTransporte(nAluno) = "ERRO"
        Err.Clear
        On Error GoTo 0

        If respLocal = 7 Then
            If reqLocal = ultimoReq Then
                repCount = repCount + 1
            Else
                repCount = 0
            End If
            If repCount >= 6 Then
                If shell.Popup("O robo parece estar digitando no local errado." & vbCrLf & _
                    "Deseja recalibrar a posicao do CPF?", 4 + 32, "Repetindo varias vezes", 48) = 6 Then
                    CalibrarPosicaoCPF
                    repCount = 0
                End If
            End If
        End If

        If respLocal = 9 Then
            If nAluno > 1 Then nAluno = nAluno - 1
        ElseIf respLocal = 0 Then
            saiuPorSair = True
            Call SalvarStatusTransporte()
            Exit Do
        ElseIf respLocal = 7 Then
            ' permanece no mesmo aluno
        Else
            nAluno = nAluno + 1
        End If
        ultimoReq = reqLocal
    Loop
    Call SalvarStatusTransporte()
End Sub

Sub ExecutarLoopTransporteNao()
    Dim nAluno, reqLocal, respLocal, ultimoReq, repCount, comando
    Dim partesLocal, nomeLocal, zonaLocal, turmaLocal, cpfLocal, cpfFmtLocal, statusMsg

    repCount = 0
    ultimoReq = ""
    totalFltr = totalTranspNao
    ReDim itensFltr(totalFltr)
    For nAluno = 1 To totalFltr
        partesLocal = Split(transpNaoLista(nAluno), "|")
        nomeLocal = partesLocal(0)
        cpfLocal = BuscarCPFAluno(nomeLocal)
        If cpfLocal = "" And UBound(partesLocal) >= 3 Then cpfLocal = partesLocal(3)
        ItensFltr(nAluno) = nomeLocal & "|" & cpfLocal & "|||"
    Next

    nAluno = 1
    Do While nAluno >= 1 And nAluno <= totalFltr
        partesLocal = Split(transpNaoLista(nAluno), "|")
        nomeLocal = partesLocal(0)
        zonaLocal = partesLocal(1)
        turmaLocal = partesLocal(2)
        cpfLocal = BuscarCPFAluno(nomeLocal)
        If cpfLocal = "" And UBound(partesLocal) >= 3 Then cpfLocal = partesLocal(3)
        cpfFmtLocal = FormatarCPF(cpfLocal)

        reqLocal = "R" & CStr(nAluno)

        If nAluno = 1 Then
            statusMsg = "Digitando CPF de " & nomeLocal & "..."
        ElseIf nAluno < totalFltr Then
            statusMsg = "Aguardando CPF ser digitado. Apos digitado, navegue ate o proximo e clique Avancar"
        Else
            statusMsg = "Ultimo aluno. Clique Avancar para encerrar."
        End If
        AtualizarPainel reqLocal, nAluno, totalFltr, cpfFmtLocal, "CONFERENCIA TRANSPORTE (NAO)", nomeLocal, "ALUNO", "", "", "", statusMsg, zonaLocal, "", "", ""
        On Error Resume Next
        shell.AppActivate "Controle de Fluxo"
        On Error GoTo 0

        If cpfLocal = "" Then
            shell.Popup "CPF nao encontrado em dados.txt para: " & nomeLocal, 3, "CPF Ausente", 48
            respLocal = 7
        Else
            respLocal = AguardarCliqueOuPainel(cpfFmtLocal)
        End If

        Do While respLocal = 5
            respLocal = LerRespostaPainel(reqLocal)
            If respLocal = 5 Then respLocal = 7
            If respLocal = 8 Then
                shell.Popup "Posicione o mouse sobre o campo CPF para recalibrar.", 2, "Recalibracao", 64
                CalibrarPosicaoCPF
                respLocal = 5
            End If
        Loop

        If respLocal = 8 Then
            shell.Popup "Posicione o mouse sobre o campo CPF para recalibrar.", 2, "Recalibracao", 64
            CalibrarPosicaoCPF
            respLocal = 7
            repCount = 0
        End If

        On Error Resume Next
        If respLocal = 1 Then statusTranspNao(nAluno) = "OK"
        If respLocal = 7 Then statusTranspNao(nAluno) = "ERRO"
        Err.Clear
        On Error GoTo 0

        If respLocal = 7 Then
            If reqLocal = ultimoReq Then
                repCount = repCount + 1
            Else
                repCount = 0
            End If
            If repCount >= 6 Then
                If shell.Popup("O robo parece estar digitando no local errado." & vbCrLf & _
                    "Deseja recalibrar a posicao do CPF?", 4 + 32, "Repetindo varias vezes", 48) = 6 Then
                    CalibrarPosicaoCPF
                    repCount = 0
                End If
            End If
        End If

        If respLocal = 9 Then
            If nAluno > 1 Then nAluno = nAluno - 1
        ElseIf respLocal = 0 Then
            saiuPorSair = True
            Call SalvarStatusTransporteNao()
            Exit Do
        ElseIf respLocal = 7 Then
            ' permanece no mesmo aluno
        Else
            nAluno = nAluno + 1
        End If
        ultimoReq = reqLocal
    Loop
    Call SalvarStatusTransporteNao()
End Sub

Sub ExecutarLoopEspeciais()
    Dim nAluno, reqLocal, respLocal, ultimoReq, repCount
    Dim nomeLocal, cpfLocal, cpfFmtLocal, statusMsg
    Dim defLocal, recLocal, transEsLocal, aeeLocal, apoiLocal

    repCount = 0
    ultimoReq = ""
    totalFltr = totalEspeciais
    ReDim itensFltr(totalFltr)
    For nAluno = 1 To totalFltr
        nomeLocal = especiaisLista(nAluno)
        cpfLocal = BuscarCPFAluno(nomeLocal)
        ItensFltr(nAluno) = nomeLocal & "|" & cpfLocal & "|||"
    Next

    nAluno = 1
    Do While nAluno >= 1 And nAluno <= totalFltr
        nomeLocal = especiaisLista(nAluno)
        cpfLocal = BuscarCPFAluno(nomeLocal)
        cpfFmtLocal = FormatarCPF(cpfLocal)
        defLocal = deficienciasLista(nAluno)
        recLocal = recursoLista(nAluno)
        transEsLocal = transporteEspecialLista(nAluno)
        aeeLocal = aeeLista(nAluno)
        apoiLocal = apoioLista(nAluno)

        reqLocal = "R" & CStr(nAluno)

        If nAluno = 1 Then
            statusMsg = "Digitando CPF de " & nomeLocal & "..."
        ElseIf nAluno < totalFltr Then
            statusMsg = "Aguardando CPF ser digitado. Apos digitado, navegue ate o proximo e clique Avancar"
        Else
            statusMsg = "Ultimo aluno. Clique Avancar para encerrar."
        End If
        AtualizarPainel reqLocal, nAluno, totalFltr, cpfFmtLocal, "CONFERENCIA ESPECIAIS", nomeLocal, "ALUNO", "", "", "", statusMsg, transEsLocal, defLocal, recLocal, apoiLocal
        On Error Resume Next
        shell.AppActivate "Controle de Fluxo"
        On Error GoTo 0

        If cpfLocal = "" Then
            shell.Popup "CPF nao encontrado em dados.txt para: " & nomeLocal, 3, "CPF Ausente", 48
            respLocal = 7
        Else
            respLocal = AguardarCliqueOuPainel(cpfFmtLocal)
        End If

        Do While respLocal = 5
            respLocal = LerRespostaPainel(reqLocal)
            If respLocal = 5 Then respLocal = 7
            If respLocal = 8 Then
                shell.Popup "Posicione o mouse sobre o campo CPF para recalibrar.", 2, "Recalibracao", 64
                CalibrarPosicaoCPF
                respLocal = 5
            End If
        Loop

        If respLocal = 8 Then
            shell.Popup "Posicione o mouse sobre o campo CPF para recalibrar.", 2, "Recalibracao", 64
            CalibrarPosicaoCPF
            respLocal = 7
            repCount = 0
        End If

        On Error Resume Next
        If respLocal = 1 Then statusEspeciais(nAluno) = "OK"
        If respLocal = 7 Then statusEspeciais(nAluno) = "ERRO"
        Err.Clear
        On Error GoTo 0

        If respLocal = 7 Then
            If reqLocal = ultimoReq Then
                repCount = repCount + 1
            Else
                repCount = 0
            End If
            If repCount >= 6 Then
                If shell.Popup("O robo parece estar digitando no local errado." & vbCrLf & _
                    "Deseja recalibrar a posicao do CPF?", 4 + 32, "Repetindo varias vezes", 48) = 6 Then
                    CalibrarPosicaoCPF
                    repCount = 0
                End If
            End If
        End If

        If respLocal = 9 Then
            If nAluno > 1 Then nAluno = nAluno - 1
        ElseIf respLocal = 0 Then
            saiuPorSair = True
            Call SalvarStatusEspeciais()
            Exit Do
        ElseIf respLocal = 7 Then
            ' permanece no mesmo aluno
        Else
            nAluno = nAluno + 1
        End If
        ultimoReq = reqLocal
    Loop
    Call SalvarStatusEspeciais()
End Sub

Sub AtualizarPainel(req, atual, total, cpfPainel, turmaPainel, alunoPainel, labelTipo, racaPainel, dtNascPainel, enderecoPainel, statusPainel, transportePainel, deficienciasPainel, recursoPainel, apoioPainel)
    On Error Resume Next
    Dim fPane
    Set fPane = fso.CreateTextFile(caminhoCtrlIn, True)
    fPane.Write req & "|" & atual & "|" & total & "|" & cpfPainel & "|" & turmaPainel & "|" & alunoPainel & "|" & labelTipo & "|" & racaPainel & "|" & dtNascPainel & "|" & enderecoPainel & "|" & statusPainel & "|" & transportePainel & "|" & deficienciasPainel & "|" & recursoPainel & "|" & apoioPainel
    fPane.Close
    On Error GoTo 0
End Sub

Sub AtualizarStatusPainel(texto)
    On Error Resume Next
    Dim fS
    Set fS = fso.CreateTextFile(caminhoCtrlIn, True)
    fS.Write "STATUS|" & texto
    fS.Close
    On Error GoTo 0
End Sub

Function LerRespostaPainel(reqEsperado)
    Dim respostaLocal, partesL, tRead
    respostaLocal = -1
    tempoEspera = 0

    Do While respostaLocal < 0
        WScript.Sleep 100
        tempoEspera = tempoEspera + 200

        If fso.FileExists(caminhoCtrlOut) Then
            tRead = 0
            Do While tRead < 10 And respostaLocal < 0
                On Error Resume Next
                Set fResp = fso.OpenTextFile(caminhoCtrlOut, 1)
                If Err.Number = 0 Then
                    conteudoResp = fResp.ReadAll
                    If Err.Number = 0 Then
                        fResp.Close
                        ApagarComRetry caminhoCtrlOut

                        partesL = Split(conteudoResp, "|")
                        If UBound(partesL) >= 1 Then
                            If Trim(partesL(0)) = reqEsperado Then
                                respostaLocal = CInt(Trim(partesL(1)))
                            End If
                        End If
                    Else
                        fResp.Close
                    End If
                End If
                On Error GoTo 0
                If respostaLocal < 0 Then
                    WScript.Sleep 100
                    tRead = tRead + 1
                End If
            Loop
        End If

        If tempoEspera > 600000 Then WScript.Quit
    Loop

    LerRespostaPainel = respostaLocal
End Function

Function AguardarPainelComTimeout(reqEsperado, maxSegundos)
    Dim respLocal, tMax, tAtual
    respLocal = -1
    tMax = maxSegundos * 5
    tAtual = 0
    Do While respLocal < 0 And tAtual < tMax
        WScript.Sleep 100
        tAtual = tAtual + 1
        If fso.FileExists(caminhoCtrlOut) Then
            On Error Resume Next
            Set fResp = fso.OpenTextFile(caminhoCtrlOut, 1)
            If Err.Number = 0 Then
                conteudoResp = fResp.ReadAll
                If Err.Number = 0 Then
                    fResp.Close
                    ApagarComRetry caminhoCtrlOut
                    Dim partesA
                    partesA = Split(conteudoResp, "|")
                    If UBound(partesA) >= 1 Then
                        If Trim(partesA(0)) = reqEsperado Then
                            respLocal = CInt(Trim(partesA(1)))
                        End If
                    End If
                Else
                    fResp.Close
                End If
            End If
            On Error GoTo 0
        End If
    Loop
    If respLocal < 0 Then respLocal = 6
    AguardarPainelComTimeout = respLocal
End Function

Sub CalibrarPosicaoCPF()
    ' Try automatic methods; if all fail, keep existing coordinates
    If Not CalibrarUsarOCR() Then
        Dim caminhoPos, fPos, cmdGetPos, outputPos
        caminhoPos = pastaAtual & "\cpf_pos.txt"
        If Not fso.FileExists(caminhoPos) Then
            shell.Popup "CALIBRACAO - POSICIONE O MOUSE SOBRE O CAMPO CPF" & vbCrLf & vbCrLf & _
                        "Apos posicionar, clique em OK. O robo aguardara 3 segundos.", _
                        0, "Calibracao - Campo CPF", 64
            cmdGetPos = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
                        pastaAtual & "\get_cursor_pos.ps1"" """ & pastaAtual & "\temp_pos.txt"""
            On Error Resume Next
            shell.Run cmdGetPos, 0, True
            If fso.FileExists(pastaAtual & "\temp_pos.txt") Then
                Set fPos = fso.OpenTextFile(pastaAtual & "\temp_pos.txt", 1)
                outputPos = fPos.ReadAll()
                fPos.Close
                fso.DeleteFile pastaAtual & "\temp_pos.txt"
                Set fPos = fso.CreateTextFile(caminhoPos, True)
                fPos.Write Trim(outputPos)
                fPos.Close
            End If
            On Error Goto 0
    WScript.Sleep 3000
        End If
    End If
End Sub

Sub CalibrarPosicaoCPFAuto()
    ' Try OCR first; if fails, silently capture cursor position
    If Not CalibrarUsarOCR() Then
        Dim fPos, cmdGetPos, outputPos, caminhoPos
        caminhoPos = pastaAtual & "\cpf_pos.txt"
        cmdGetPos = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
                    pastaAtual & "\get_cursor_pos.ps1"" """ & pastaAtual & "\temp_pos.txt"""
        On Error Resume Next
        shell.Run cmdGetPos, 0, True
        If fso.FileExists(pastaAtual & "\temp_pos.txt") Then
            Set fPos = fso.OpenTextFile(pastaAtual & "\temp_pos.txt", 1)
            outputPos = fPos.ReadAll()
            fPos.Close
            fso.DeleteFile pastaAtual & "\temp_pos.txt"
            Set fPos = fso.CreateTextFile(caminhoPos, True)
            fPos.Write Trim(outputPos)
            fPos.Close
        End If
        On Error Goto 0
    End If
End Sub

Function CalibrarUsarOCR()
    ' 1) HTML via UIA (acessibilidade do Chrome) — sem reiniciar Chrome
    If CalibrarUsarUIA() Then
        CalibrarUsarOCR = True
        Exit Function
    End If

    ' 2) HTML via CDP (Chrome DevTools) — precisa porta 9222
    If CalibrarUsarCDP() Then
        CalibrarUsarOCR = True
        Exit Function
    End If

    ' 3) Fallback: Google Cloud Vision OCR
    Dim cmdOCR, caminhoPos, fPos, outputPos
    caminhoPos = pastaAtual & "\cpf_pos.txt"
    cmdOCR = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
             pastaAtual & "\localizar_cpf_ocr.ps1"" """ & pastaAtual & "\temp_pos.txt"""
    On Error Resume Next
    shell.Run cmdOCR, 0, True
    If fso.FileExists(pastaAtual & "\temp_pos.txt") Then
        Set fPos = fso.OpenTextFile(pastaAtual & "\temp_pos.txt", 1)
        outputPos = fPos.ReadAll()
        fPos.Close
        fso.DeleteFile pastaAtual & "\temp_pos.txt"
        Set fPos = fso.CreateTextFile(caminhoPos, True)
        fPos.Write Trim(outputPos)
        fPos.Close
        CalibrarUsarOCR = True
    Else
        CalibrarUsarOCR = False
    End If
    On Error Goto 0
End Function

Function CalibrarUsarUIA()
    Dim cmdUIA, caminhoPos, fPos, outputPos
    caminhoPos = pastaAtual & "\cpf_pos.txt"
    cmdUIA = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
             pastaAtual & "\localizar_cpf_uia.ps1"" """ & pastaAtual & "\temp_pos.txt"""
    On Error Resume Next
    shell.Run cmdUIA, 0, True
    If fso.FileExists(pastaAtual & "\temp_pos.txt") Then
        Set fPos = fso.OpenTextFile(pastaAtual & "\temp_pos.txt", 1)
        outputPos = fPos.ReadAll()
        fPos.Close
        fso.DeleteFile pastaAtual & "\temp_pos.txt"
        Set fPos = fso.CreateTextFile(caminhoPos, True)
        fPos.Write Trim(outputPos)
        fPos.Close
        CalibrarUsarUIA = True
    Else
        CalibrarUsarUIA = False
    End If
    On Error Goto 0
End Function

Function CalibrarUsarCDP()
    Dim cmdCDP, caminhoPos, fPos, outputPos
    caminhoPos = pastaAtual & "\cpf_pos.txt"
    cmdCDP = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
             pastaAtual & "\localizar_cpf_cdp.ps1"" """ & pastaAtual & "\temp_pos.txt"""
    On Error Resume Next
    shell.Run cmdCDP, 0, True
    If fso.FileExists(pastaAtual & "\temp_pos.txt") Then
        Set fPos = fso.OpenTextFile(pastaAtual & "\temp_pos.txt", 1)
        outputPos = fPos.ReadAll()
        fPos.Close
        fso.DeleteFile pastaAtual & "\temp_pos.txt"
        Set fPos = fso.CreateTextFile(caminhoPos, True)
        fPos.Write Trim(outputPos)
        fPos.Close
        CalibrarUsarCDP = True
    Else
        CalibrarUsarCDP = False
    End If
    On Error Goto 0
End Function

Sub IniciarCDPServer()
    If fso.FileExists(pastaAtual & "\cdp_server.pid") Then Exit Sub
    ' Clean stale files from previous crashes
    On Error Resume Next
    fso.DeleteFile pastaAtual & "\cdp_cmd.txt", True
    fso.DeleteFile pastaAtual & "\cdp_resp.txt", True
    fso.DeleteFile pastaAtual & "\cdp_ready.txt", True
    On Error GoTo 0
    Dim comando

    ' Start CDP server in background (returns immediately)
    ' The CDP server itself will fail gracefully if port 9222 is not available
    comando = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
              pastaAtual & "\aguardar_clique_cdp_server.ps1"""
    shell.Run comando, 0, False
End Sub

Sub AguardarCDPServer()
    Dim tWait, fPid
    tWait = 0
    Do While Not fso.FileExists(pastaAtual & "\cdp_ready.txt") And tWait < 300
        WScript.Sleep 100: tWait = tWait + 1
    Loop

    If fso.FileExists(pastaAtual & "\cdp_ready.txt") Then
        Set fPid = fso.CreateTextFile(pastaAtual & "\cdp_server.pid", True)
        fPid.Close
    End If
End Sub

Sub PararCDPServer()
    On Error Resume Next
    Dim cmdPath, fCmd
    cmdPath = pastaAtual & "\cdp_cmd.txt"
    Set fCmd = fso.CreateTextFile(cmdPath, True)
    fCmd.Write "EXIT": fCmd.Close
    WScript.Sleep 100
    fso.DeleteFile cmdPath, True
    fso.DeleteFile pastaAtual & "\cdp_ready.txt", True
    fso.DeleteFile pastaAtual & "\cdp_resp.txt", True
    fso.DeleteFile pastaAtual & "\cdp_server.pid", True
    On Error GoTo 0
End Sub

Function AguardarViaCDPServer(cpfNumero)
    Dim respPath, readyPath, linResp, fResp, fCmd, ctrlInPath, partesCtrl
    respPath = pastaAtual & "\cdp_resp.txt"
    readyPath = pastaAtual & "\cdp_ready.txt"
    ctrlInPath = pastaAtual & "\ctrl_out.txt"
    On Error Resume Next
    If Not fso.FileExists(readyPath) Then AguardarViaCDPServer = -1: Exit Function
    fso.DeleteFile readyPath, True
    ' Limpa resposta antiga antes de enviar novo comando
    fso.DeleteFile respPath, True
    Set fCmd = fso.CreateTextFile(pastaAtual & "\cdp_cmd.txt", True)
    fCmd.Write cpfNumero: fCmd.Close
    ' Aguarda CDP server responder OU usuario clicar no painel
    Do While Not fso.FileExists(respPath)
        WScript.Sleep 100
        If fso.FileExists(ctrlInPath) Then
            ' Usuario clicou - usa a resposta diretamente
            Set fResp = fso.OpenTextFile(ctrlInPath, 1)
            linResp = Trim(fResp.ReadAll): fResp.Close
            fso.DeleteFile ctrlInPath, True
            partesCtrl = Split(linResp, "|")
            If UBound(partesCtrl) >= 1 Then
                AguardarViaCDPServer = CInt(Trim(partesCtrl(1)))
            Else
                AguardarViaCDPServer = -1
            End If
            On Error GoTo 0
            Exit Function
        End If
    Loop
    If fso.FileExists(respPath) Then
        Set fResp = fso.OpenTextFile(respPath, 1)
        linResp = Trim(fResp.ReadAll): fResp.Close
        fso.DeleteFile respPath, True
        AguardarViaCDPServer = CInt(linResp)
    Else
        AguardarViaCDPServer = -1
    End If
    On Error GoTo 0
End Function

Function AguardarCliqueOuPainel(cpfNumero)
    ' Try CDP server first (persistent - no process restart)
    ' Aguarda ate 5s pelo cdp_ready.txt para dar tempo do servidor CDP conectar
    Dim tCdp, readyPath
    readyPath = pastaAtual & "\cdp_ready.txt"
    tCdp = 0
    Do While Not fso.FileExists(readyPath) And tCdp < 50
        WScript.Sleep 100: tCdp = tCdp + 1
    Loop
    If fso.FileExists(readyPath) Then
        Dim respServ: respServ = AguardarViaCDPServer(cpfNumero)
        If respServ >= 0 Then
            AguardarCliqueOuPainel = respServ
            If respServ < 0 Or respServ > 9 Then AguardarCliqueOuPainel = 6
            Exit Function
        End If
    End If
    ' Fallback: SendKeys (quando nao ha porta de depuracao)
    Dim comando, exitCode
    ApagarComRetry caminhoCtrlOut
    comando = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
              pastaAtual & "\aguardar_clique_cpf.ps1"" " & cpfNumero
    exitCode = shell.Run(comando, 0, True)
    AguardarCliqueOuPainel = exitCode
    If exitCode < 0 Or exitCode > 9 Then AguardarCliqueOuPainel = 6
End Function

Sub ExecutarLoopCPF()
    Dim nAluno, reqLocal, respLocal, ultimoReq, repCount, calibCount, comando
    Dim partesLocal, nomeLocal, cpfLocal, cpfFmtLocal, racaLocal, dtNascLocal, enderecoLocal

    repCount = 0
    calibCount = 0
    ultimoReq = ""
    nAluno = 1
    Do While nAluno >= 1 And nAluno <= totalFltr
        partesLocal = Split(itensFltr(nAluno), "|")
        nomeLocal = partesLocal(0)
        cpfLocal = partesLocal(1)
        cpfFmtLocal = FormatarCPF(cpfLocal)
        racaLocal = ""
        dtNascLocal = ""
        If UBound(partesLocal) >= 2 Then racaLocal = partesLocal(2)
        If UBound(partesLocal) >= 3 Then dtNascLocal = partesLocal(3)

        reqLocal = "R" & CStr(nAluno)
        enderecoLocal = BuscarEndereco(turmas(idx, 0), nomeLocal)

        Dim transporteInfoLocal
        transporteInfoLocal = BuscarTransporte(nomeLocal)

        ' --- PASSO 1: Mostra aluno no painel com status (unica escrita em ctrl_in.txt) ---
        Dim statusMsg
        If nAluno = 1 Then
            statusMsg = "Digitando CPF de " & nomeLocal & "..."
        ElseIf nAluno < totalFltr Then
            statusMsg = "Aguardando CPF ser digitado. Apos digitado, navegue ate o proximo e clique Avancar"
        Else
            statusMsg = "Ultimo aluno. Clique Avancar para encerrar."
        End If
        AtualizarPainel reqLocal, nAluno, totalFltr, cpfFmtLocal, turmas(idx, 0), nomeLocal, labelItem, racaLocal, dtNascLocal, enderecoLocal, statusMsg, transporteInfoLocal, "", "", ""
        On Error Resume Next
        shell.AppActivate "Controle de Fluxo"
        On Error GoTo 0

        ' --- PASSO 2: Digita CPF e aguarda o usuario navegar + clicar (unico wait) ---
        respLocal = AguardarCliqueOuPainel(cpfFmtLocal)

        ' --- Pausa: enquanto estiver pausado, usa LerRespostaPainel (unico lugar que precisa) ---
        Do While respLocal = 5
            respLocal = LerRespostaPainel(reqLocal)
            If respLocal = 5 Then respLocal = 7
            If respLocal = 8 Then
                shell.Popup "Posicione o mouse sobre o campo CPF para recalibrar.", 2, "Recalibracao", 64
                CalibrarPosicaoCPF
                respLocal = 5
            End If
        Loop

        If respLocal = 8 Then
            shell.Popup "Posicione o mouse sobre o campo CPF para recalibrar.", 2, "Recalibracao", 64
            CalibrarPosicaoCPF
            respLocal = 7
            repCount = 0
            calibCount = 0
        End If

        If respLocal = 7 Then
            If reqLocal = ultimoReq Then
                repCount = repCount + 1
            Else
                repCount = 0
            End If
            If repCount >= 6 Then
                If shell.Popup("O robo parece estar digitando no local errado." & vbCrLf & _
                               "Deseja recalibrar a posicao do campo CPF?", _
                               0, "Alerta - Recalibracao", 4 + 48) = 6 Then
                    CalibrarPosicaoCPF
                End If
                repCount = 0
            End If
            WScript.Sleep 50
        ElseIf respLocal = 9 Then
            If nAluno > 1 Then nAluno = nAluno - 1
        ElseIf respLocal = 0 Then
            saiuPorSair = True
            Exit Do
        Else
            nAluno = nAluno + 1
            calibCount = calibCount + 1
            If calibCount >= 3 Then
                calibCount = 0
                CalibrarPosicaoCPFAuto
            End If
        End If
        ultimoReq = reqLocal
    Loop

    On Error Resume Next
    PararCDPServer
    On Error GoTo 0
End Sub

Sub ExibirTelaSenha()
    Dim htaSenha, fSenha, caminhoSenhaResp, fSenhaResp
    caminhoSenhaResp = pastaAtual & "\senha_resp.txt"
    If fso.FileExists(caminhoSenhaResp) Then fso.DeleteFile caminhoSenhaResp

    htaSenha = ""
    htaSenha = htaSenha & "<!DOCTYPE html>" & vbCrLf
    htaSenha = htaSenha & "<html>" & vbCrLf
    htaSenha = htaSenha & "<head>" & vbCrLf
    htaSenha = htaSenha & "    <meta charset=""utf-8"" />" & vbCrLf
    htaSenha = htaSenha & "    <title>Acesso ao Sistema</title>" & vbCrLf
    htaSenha = htaSenha & "    <hta:application id=""app"" applicationname=""Acesso"" border=""thin"" caption=""yes"" sysmenu=""yes"" maximizebutton=""no"" minimizebutton=""no"" showintaskbar=""yes"" scroll=""no"" singleinstance=""yes"" windowstate=""normal"" />" & vbCrLf
    htaSenha = htaSenha & "    <script language=""VBScript"">" & vbCrLf
    htaSenha = htaSenha & "    Option Explicit" & vbCrLf
    htaSenha = htaSenha & "    Dim fso, pastaAtual, caminhoResp, fechando" & vbCrLf
    htaSenha = htaSenha & "    Sub Window_OnLoad" & vbCrLf
    htaSenha = htaSenha & "        fechando = False" & vbCrLf
    htaSenha = htaSenha & "        Set fso = CreateObject(""Scripting.FileSystemObject"")" & vbCrLf
    htaSenha = htaSenha & "        pastaAtual = Replace(document.location.pathname, ""/"", ""\\"")" & vbCrLf
    htaSenha = htaSenha & "        If Left(pastaAtual, 1) = ""\"" Then pastaAtual = Mid(pastaAtual, 2)" & vbCrLf
    htaSenha = htaSenha & "        pastaAtual = Replace(pastaAtual, ""%20"", "" "")" & vbCrLf
    htaSenha = htaSenha & "        pastaAtual = fso.GetParentFolderName(pastaAtual)" & vbCrLf
    htaSenha = htaSenha & "        caminhoResp = pastaAtual & ""\senha_resp.txt""" & vbCrLf
    htaSenha = htaSenha & "        window.resizeTo 380, 240" & vbCrLf
    htaSenha = htaSenha & "        window.moveTo (screen.width-380)/2, (screen.height-240)/2" & vbCrLf
    htaSenha = htaSenha & "        window.focus" & vbCrLf
    htaSenha = htaSenha & "        txtSenha.focus" & vbCrLf
    htaSenha = htaSenha & "    End Sub" & vbCrLf
    htaSenha = htaSenha & "    Sub Entrar" & vbCrLf
    htaSenha = htaSenha & "        fechando = True" & vbCrLf
    htaSenha = htaSenha & "        Dim fOut" & vbCrLf
    htaSenha = htaSenha & "        Set fOut = fso.CreateTextFile(caminhoResp, True)" & vbCrLf
    htaSenha = htaSenha & "        fOut.Write txtSenha.value" & vbCrLf
    htaSenha = htaSenha & "        fOut.Close" & vbCrLf
    htaSenha = htaSenha & "        window.close" & vbCrLf
    htaSenha = htaSenha & "    End Sub" & vbCrLf
    htaSenha = htaSenha & "    Sub document_OnKeyDown" & vbCrLf
    htaSenha = htaSenha & "        If window.event.keyCode = 13 Then Entrar" & vbCrLf
    htaSenha = htaSenha & "        If window.event.keyCode = 27 Then window.close" & vbCrLf
    htaSenha = htaSenha & "    End Sub" & vbCrLf
    htaSenha = htaSenha & "    Sub Window_OnBeforeUnload" & vbCrLf
    htaSenha = htaSenha & "        If Not fechando Then" & vbCrLf
    htaSenha = htaSenha & "            Dim fOut" & vbCrLf
    htaSenha = htaSenha & "            Set fOut = fso.CreateTextFile(caminhoResp, True)" & vbCrLf
    htaSenha = htaSenha & "            fOut.Write """"" & vbCrLf
    htaSenha = htaSenha & "            fOut.Close" & vbCrLf
    htaSenha = htaSenha & "        End If" & vbCrLf
    htaSenha = htaSenha & "    End Sub" & vbCrLf
    htaSenha = htaSenha & "    </script>" & vbCrLf
    htaSenha = htaSenha & "<style>" & vbCrLf
    htaSenha = htaSenha & "    body { margin:0; padding:40px 20px; text-align:center; font-family:Segoe UI,Arial,sans-serif; background:#e8ecf4; color:#333; font-size:14px; }" & vbCrLf
    htaSenha = htaSenha & "    .icone { font-size:40px; margin-bottom:10px; color:#4b7bec; }" & vbCrLf
    htaSenha = htaSenha & "    .titulo { font-size:16px; font-weight:700; color:#2c3e7a; margin-bottom:4px; }" & vbCrLf
    htaSenha = htaSenha & "    .subtitulo { font-size:12px; color:#555; margin-bottom:18px; }" & vbCrLf
    htaSenha = htaSenha & "    input[type=password] { width:220px; height:36px; border:2px solid #b0b8cc; padding:0 14px; font-size:16px; letter-spacing:6px; text-align:center; }" & vbCrLf
    htaSenha = htaSenha & "    .btn { width:110px; height:34px; border:0; background:#4b7bec; color:#fff; font-weight:600; font-size:13px; cursor:pointer; margin-top:14px; }" & vbCrLf
    htaSenha = htaSenha & "    .btn:hover { background:#2d5bd6; }" & vbCrLf
    htaSenha = htaSenha & "    .btn-cancel { width:110px; height:34px; border:1px solid #999; background:#f0f0f0; color:#555; font-weight:600; font-size:13px; cursor:pointer; margin-top:14px; margin-left:8px; }" & vbCrLf
    htaSenha = htaSenha & "    .btn-cancel:hover { background:#e0e0e0; }" & vbCrLf
    htaSenha = htaSenha & "</style>" & vbCrLf
    htaSenha = htaSenha & "</head>" & vbCrLf
    htaSenha = htaSenha & "<body>" & vbCrLf
    htaSenha = htaSenha & "    <div class=""container"">" & vbCrLf
    htaSenha = htaSenha & "        <div class=""icone"">&#128274;</div>" & vbCrLf
    htaSenha = htaSenha & "        <div class=""titulo"">Acesso ao Sistema</div>" & vbCrLf
    htaSenha = htaSenha & "        <div class=""subtitulo"">Digite a senha para continuar</div>" & vbCrLf
    htaSenha = htaSenha & "        <input type=""password"" id=""txtSenha"" />" & vbCrLf
    htaSenha = htaSenha & "        <br><input class=""btn"" type=""button"" value=""ENTRAR"" onclick=""Entrar"" />" & vbCrLf
    htaSenha = htaSenha & "        <input class=""btn-cancel"" type=""button"" value=""CANCELAR"" onclick=""window.close"" />" & vbCrLf
    htaSenha = htaSenha & "    </div>" & vbCrLf
    htaSenha = htaSenha & "</body>" & vbCrLf
    htaSenha = htaSenha & "</html>" & vbCrLf

    On Error Resume Next
    Call ApagarComRetry(pastaAtual & "\tela_senha.hta")
    Set fSenha = fso.CreateTextFile(pastaAtual & "\tela_senha.hta", True)
    fSenha.Write htaSenha
    fSenha.Close
    On Error Goto 0

    shell.Run "mshta.exe """ & pastaAtual & "\tela_senha.hta""", 1, False

    Dim esperaSenha
    esperaSenha = 0
    Do
        WScript.Sleep 100
        esperaSenha = esperaSenha + 1
        If fso.FileExists(caminhoSenhaResp) Then
            On Error Resume Next
            Set fSenhaResp = fso.OpenTextFile(caminhoSenhaResp, 1)
            If Err.Number = 0 Then
                senhaDigitada = Trim(fSenhaResp.ReadAll)
                If Err.Number <> 0 Then senhaDigitada = ""
            Else
                senhaDigitada = ""
            End If
            If IsObject(fSenhaResp) Then fSenhaResp.Close
            On Error Goto 0
            Exit Do
        End If
        If Not fso.FileExists(pastaAtual & "\tela_senha.hta") Then
            senhaDigitada = ""
            Exit Do
        End If
        If esperaSenha > 50 Then
            senhaDigitada = ""
            Exit Do
        End If
    Loop

    Set fSenhaResp = Nothing
    On Error Resume Next
    Call ApagarComRetry(pastaAtual & "\tela_senha.hta")
    Call ApagarComRetry(pastaAtual & "\senha_resp.txt")
    On Error Goto 0
End Sub

Sub GerarSeletorModuloHTA()
    Dim hta, fHTA, modPath
    hta = ""
    hta = hta & "<!DOCTYPE html>" & vbCrLf
    hta = hta & "<html>" & vbCrLf
    hta = hta & "<head>" & vbCrLf
    hta = hta & "    <meta charset=""utf-8"" />" & vbCrLf
    hta = hta & "    <title>Seletor de Modulo</title>" & vbCrLf
    hta = hta & "    <hta:application id=""app"" applicationname=""Seletor"" border=""thin"" />" & vbCrLf
    hta = hta & "    <style>" & vbCrLf
    hta = hta & "        body { margin:0; padding:40px 20px; text-align:center; font-family:Segoe UI,Arial,sans-serif; }" & vbCrLf
    hta = hta & "        h2 { margin:0 0 8px 0; color:#1a2b6b; font-size:20px; }" & vbCrLf
    hta = hta & "        .sub { color:#555; font-size:13px; margin-bottom:28px; }" & vbCrLf
    hta = hta & "        .btns { display:inline-block; }" & vbCrLf
    hta = hta & "        input { width:160px; height:54px; margin:0 8px; font-size:15px; font-weight:700; border:2px solid #1a3d9e; border-radius:8px; background:#eef4ff; color:#000; cursor:pointer; }" & vbCrLf
    hta = hta & "        input:hover { background:#dce8ff; }" & vbCrLf
    hta = hta & "        .prof { border-color:#5c2c8a; background:#f5eeff; }" & vbCrLf
    hta = hta & "        .prof:hover { background:#ede0ff; }" & vbCrLf
    hta = hta & "    </style>" & vbCrLf
    hta = hta & "    <script language=""VBScript"">" & vbCrLf
    hta = hta & "    Dim escolheu" & vbCrLf
    hta = hta & "    Sub Window_OnLoad" & vbCrLf
    hta = hta & "        escolheu = False" & vbCrLf
    hta = hta & "        window.resizeTo 460, 420" & vbCrLf
    hta = hta & "        window.moveTo (screen.width-460)/2, (screen.height-420)/2" & vbCrLf
    hta = hta & "        window.focus" & vbCrLf
    hta = hta & "    End Sub" & vbCrLf
    hta = hta & "    Sub Escolher(v)" & vbCrLf
    hta = hta & "        escolheu = True" & vbCrLf
    hta = hta & "        Dim fso, fOut, pastaAtual, caminhoChoice" & vbCrLf
    hta = hta & "        Set fso = CreateObject(""Scripting.FileSystemObject"")" & vbCrLf
    hta = hta & "        pastaAtual = Replace(document.location.pathname, ""/"", ""\\"")" & vbCrLf
    hta = hta & "        If Left(pastaAtual, 1) = ""\"" Then pastaAtual = Mid(pastaAtual, 2)" & vbCrLf
    hta = hta & "        pastaAtual = Replace(pastaAtual, ""%20"", "" "")" & vbCrLf
    hta = hta & "        pastaAtual = fso.GetParentFolderName(pastaAtual)" & vbCrLf
    hta = hta & "        caminhoChoice = pastaAtual & ""\modulo_choice.txt""" & vbCrLf
    hta = hta & "        Set fOut = fso.CreateTextFile(caminhoChoice, True)" & vbCrLf
    hta = hta & "        fOut.Write v" & vbCrLf
    hta = hta & "        fOut.Close" & vbCrLf
    hta = hta & "        window.close" & vbCrLf
    hta = hta & "    End Sub" & vbCrLf
    hta = hta & "    Sub Window_OnBeforeUnload" & vbCrLf
    hta = hta & "        If Not escolheu Then" & vbCrLf
    hta = hta & "            Dim fso2, fOut2, pastaAtual2, caminhoChoice2" & vbCrLf
    hta = hta & "            Set fso2 = CreateObject(""Scripting.FileSystemObject"")" & vbCrLf
    hta = hta & "            pastaAtual2 = Replace(document.location.pathname, ""/"", ""\\"")" & vbCrLf
    hta = hta & "            If Left(pastaAtual2, 1) = ""\"" Then pastaAtual2 = Mid(pastaAtual2, 2)" & vbCrLf
    hta = hta & "            pastaAtual2 = Replace(pastaAtual2, ""%20"", "" "")" & vbCrLf
    hta = hta & "            pastaAtual2 = fso2.GetParentFolderName(pastaAtual2)" & vbCrLf
    hta = hta & "            caminhoChoice2 = pastaAtual2 & ""\modulo_choice.txt""" & vbCrLf
    hta = hta & "            Set fOut2 = fso2.CreateTextFile(caminhoChoice2, True)" & vbCrLf
    hta = hta & "            fOut2.Write ""x""" & vbCrLf
    hta = hta & "            fOut2.Close" & vbCrLf
    hta = hta & "        End If" & vbCrLf
    hta = hta & "    End Sub" & vbCrLf
    hta = hta & "    </script>" & vbCrLf
    hta = hta & "</head>" & vbCrLf
    hta = hta & "<body>" & vbCrLf
    hta = hta & "    <h2>ESCOLA MUNICIPAL ZECA BARROS</h2>" & vbCrLf
    hta = hta & "    <div class=""sub"">Selecione o modulo de preenchimento</div>" & vbCrLf
    hta = hta & "    <div class=""btns"">" & vbCrLf
    hta = hta & "        <input type=""button"" value=""ALUNOS"" onclick=""Escolher('1')"" />" & vbCrLf
    hta = hta & "        <input type=""button"" class=""prof"" value=""PROFISSIONAIS"" onclick=""Escolher('2')"" />" & vbCrLf
    hta = hta & "    </div>" & vbCrLf
    hta = hta & "    <div style=""margin-top:24px;"">" & vbCrLf
    hta = hta & "        <input type=""button"" style=""width:320px;border-color:#2d7d46;background:#edf7f0;"" value=""CONFERENCIA ALUNOS TRANSPORTE"" onclick=""Escolher('3')"" />" & vbCrLf
    hta = hta & "    </div>" & vbCrLf
    hta = hta & "    <div style=""margin-top:8px;"">" & vbCrLf
    hta = hta & "        <input type=""button"" style=""width:320px;border-color:#b5651d;background:#fef2e0;"" value=""CONFERENCIA ALUNOS ESPECIAIS"" onclick=""Escolher('4')"" />" & vbCrLf
    hta = hta & "    </div>" & vbCrLf
    hta = hta & "    <div style=""margin-top:8px;"">" & vbCrLf
    hta = hta & "        <input type=""button"" style=""width:320px;border-color:#c0392b;background:#fdecea;"" value=""CONFERENCIA TRANSPORTE (NAO)"" onclick=""Escolher('5')"" />" & vbCrLf
    hta = hta & "    </div>" & vbCrLf
    hta = hta & "</body>" & vbCrLf
    hta = hta & "</html>" & vbCrLf

    modPath = pastaAtual & "\seletor_modulo.hta"
    Set fHTA = fso.CreateTextFile(modPath, True, True)
    fHTA.Write hta
    fHTA.Close
End Sub

Sub GerarPainelHTA()
    Dim hta, fHTA, arr, i
    ReDim arr(330)
    i = 0

    arr(i) = "<!DOCTYPE html>": i = i + 1
    arr(i) = "<html>": i = i + 1
    arr(i) = "<head>": i = i + 1
    arr(i) = "    <meta charset=""utf-8"" />": i = i + 1
    arr(i) = "    <title>Controle de Fluxo - Educacenso</title>": i = i + 1
    arr(i) = "    <hta:application id=""app"" applicationname=""Controle de Fluxo - Educacenso"" border=""thin"" caption=""yes"" sysmenu=""yes"" maximizebutton=""no"" minimizebutton=""yes"" showintaskbar=""yes"" scroll=""no"" singleinstance=""yes"" windowstate=""normal"" />": i = i + 1
    arr(i) = "    <script language=""VBScript"">": i = i + 1
    arr(i) = "    Option Explicit": i = i + 1
    arr(i) = "    Dim fso, pastaAtual, caminhoCtrlIn, caminhoCtrlOut": i = i + 1
    arr(i) = "    Dim idReqAtual, numAlunoAtual, totalTurmaAtual, cpfAtual, turmaAtual, nomeAtual, labelTipoAtual, racaAtual, dtNascAtual, enderecoAtual, statusTexto, transporteAtual, deficienciasAtual, recursoAtual, apoioAtual": i = i + 1
    arr(i) = "    Dim fechando": i = i + 1
    arr(i) = "    Sub Window_OnLoad": i = i + 1
    arr(i) = "        Set fso = CreateObject(""Scripting.FileSystemObject"")": i = i + 1
    arr(i) = "        pastaAtual = Replace(document.location.pathname, ""/"", ""\\"")": i = i + 1
    arr(i) = "        If Left(pastaAtual, 1) = ""\"" Then pastaAtual = Mid(pastaAtual, 2)": i = i + 1
    arr(i) = "        pastaAtual = Replace(pastaAtual, ""%20"", "" "")": i = i + 1
    arr(i) = "        pastaAtual = fso.GetParentFolderName(pastaAtual)": i = i + 1
    arr(i) = "        caminhoCtrlIn = pastaAtual & ""\ctrl_in.txt""": i = i + 1
    arr(i) = "        caminhoCtrlOut = pastaAtual & ""\ctrl_out.txt""": i = i + 1
    arr(i) = "        window.resizeTo 700, 490": i = i + 1
    arr(i) = "        window.moveTo (screen.width-700)/2, (screen.height-400)/2": i = i + 1
    arr(i) = "        idReqAtual = """"": i = i + 1
    arr(i) = "        fechando = False": i = i + 1
    arr(i) = "        numAlunoAtual = 0": i = i + 1
    arr(i) = "        totalTurmaAtual = 0": i = i + 1
    arr(i) = "        cpfAtual = """"": i = i + 1
    arr(i) = "        turmaAtual = """"": i = i + 1
    arr(i) = "        nomeAtual = """"": i = i + 1
    arr(i) = "        labelTipoAtual = ""REGISTRO""": i = i + 1
    arr(i) = "        enderecoAtual = """"": i = i + 1
    arr(i) = "        AtualizarPainelInicial": i = i + 1
    arr(i) = "        window.focus": i = i + 1
    arr(i) = "        IniciarLoopLeitura": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub AtualizarPainelInicial": i = i + 1
    arr(i) = "        On Error Resume Next": i = i + 1
    arr(i) = "        lblCabecalho.innerText = ""EDUCACENSO""": i = i + 1
    arr(i) = "        lblTurma.innerText = """"": i = i + 1
    arr(i) = "        lblAluno.innerText = ""0 de 0""": i = i + 1
    arr(i) = "        lblNome.innerText = """"": i = i + 1
    arr(i) = "        lblCpf.innerText = """"": i = i + 1
    arr(i) = "        lblRaca.innerText = """"": i = i + 1
    arr(i) = "        lblDtNasc.innerText = """"": i = i + 1
    arr(i) = "        lblEndereco.innerText = """"": i = i + 1
    arr(i) = "        lblTransporte.innerText = """"": i = i + 1
    arr(i) = "        lblDeficiencias.innerText = """"": i = i + 1
    arr(i) = "        lblRecurso.innerText = """"": i = i + 1
    arr(i) = "        lblApoio.innerText = """"": i = i + 1
    arr(i) = "        lblProgresso.innerText = ""Aguardando...""": i = i + 1
    arr(i) = "        lblPercentual.innerText = ""0%""": i = i + 1
    arr(i) = "        barra.style.width = ""0%""": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub IniciarLoopLeitura": i = i + 1
    arr(i) = "        window.setTimeout ""VerificarEntrada"", 80": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub VerificarEntrada": i = i + 1
    arr(i) = "        On Error Resume Next": i = i + 1
    arr(i) = "        If fso.FileExists(caminhoCtrlIn) Then": i = i + 1
    arr(i) = "            Dim fIn, linhaHTA, p": i = i + 1
    arr(i) = "            Set fIn = fso.OpenTextFile(caminhoCtrlIn, 1)": i = i + 1
    arr(i) = "            linhaHTA = Trim(fIn.ReadAll)": i = i + 1
    arr(i) = "            fIn.Close": i = i + 1
    arr(i) = "            fso.DeleteFile caminhoCtrlIn": i = i + 1
    arr(i) = "            If linhaHTA <> """" Then": i = i + 1
    arr(i) = "                p = Split(linhaHTA, ""|"")": i = i + 1
    arr(i) = "                If UCase(p(0)) = ""FIM"" Then": i = i + 1
    arr(i) = "                    lblProgresso.innerText = ""Processo concluido: "" & p(2) & "" "" & p(5) & "" na "" & p(4)": i = i + 1
    arr(i) = "                    lblPercentual.innerText = ""100%""": i = i + 1
    arr(i) = "                    barra.style.width = ""100%""": i = i + 1
    arr(i) = "                ElseIf UCase(p(0)) = ""CLOSE"" Then": i = i + 1
    arr(i) = "                    window.close": i = i + 1
    arr(i) = "                ElseIf UCase(p(0)) = ""STATUS"" Then": i = i + 1
    arr(i) = "                    If UBound(p) >= 1 Then lblProgresso.innerText = p(1)": i = i + 1
    arr(i) = "                Else": i = i + 1
    arr(i) = "                    idReqAtual = p(0)": i = i + 1
    arr(i) = "                    numAlunoAtual = CInt(p(1))": i = i + 1
    arr(i) = "                    totalTurmaAtual = CInt(p(2))": i = i + 1
    arr(i) = "                    cpfAtual = p(3)": i = i + 1
    arr(i) = "                    turmaAtual = p(4)": i = i + 1
    arr(i) = "                    nomeAtual = p(5)": i = i + 1
    arr(i) = "                    If UBound(p) >= 6 Then labelTipoAtual = p(6) Else labelTipoAtual = ""REGISTRO""": i = i + 1
    arr(i) = "                    If UBound(p) >= 8 Then racaAtual = p(7) Else racaAtual = """"": i = i + 1
    arr(i) = "                    If UBound(p) >= 8 Then dtNascAtual = p(8) Else dtNascAtual = """"": i = i + 1
    arr(i) = "                    If UBound(p) >= 9 Then enderecoAtual = p(9) Else enderecoAtual = """"": i = i + 1
    arr(i) = "                    If UBound(p) >= 10 Then statusTexto = p(10) Else statusTexto = """"": i = i + 1
    arr(i) = "                    If UBound(p) >= 11 Then transporteAtual = p(11) Else transporteAtual = """"": i = i + 1
    arr(i) = "                    If UBound(p) >= 12 Then deficienciasAtual = p(12) Else deficienciasAtual = """"": i = i + 1
    arr(i) = "                    If UBound(p) >= 13 Then recursoAtual = p(13) Else recursoAtual = """"": i = i + 1
    arr(i) = "                    If UBound(p) >= 14 Then apoioAtual = p(14) Else apoioAtual = """"": i = i + 1
    arr(i) = "                    AtualizarPainelAluno": i = i + 1
    arr(i) = "                    window.blur": i = i + 1
    arr(i) = "                End If": i = i + 1
    arr(i) = "            End If": i = i + 1
    arr(i) = "        End If": i = i + 1
    arr(i) = "        IniciarLoopLeitura": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub AtualizarPainelAluno": i = i + 1
    arr(i) = "        Dim perc, ehEspeciais": i = i + 1
    arr(i) = "        On Error Resume Next": i = i + 1
    arr(i) = "        ehEspeciais = (turmaAtual = ""CONFERENCIA ESPECIAIS"")": i = i + 1
    arr(i) = "        lblCabecalho.innerText = ""EDUCACENSO""": i = i + 1
    arr(i) = "        lblTurma.innerText = ""Turma: "" & turmaAtual": i = i + 1
    arr(i) = "        lblAluno.innerText = numAlunoAtual & "" de "" & totalTurmaAtual": i = i + 1
    arr(i) = "        lblNome.innerText = nomeAtual": i = i + 1
    arr(i) = "        lblCpf.innerText = cpfAtual": i = i + 1
    arr(i) = "        If ehEspeciais Then": i = i + 1
    arr(i) = "            lblRaca.innerText = """" : lblRaca.style.display = ""none""": i = i + 1
    arr(i) = "            lblEndereco.innerText = """" : lblEndereco.style.display = ""none""": i = i + 1
    arr(i) = "            lblDtNasc.innerText = """" : lblDtNasc.style.display = ""none""": i = i + 1
    arr(i) = "            lblDeficiencias.innerText = deficienciasAtual : lblDeficiencias.style.display = """"": i = i + 1
    arr(i) = "            lblRecurso.innerText = recursoAtual : lblRecurso.style.display = """"": i = i + 1
    arr(i) = "            lblApoio.innerText = apoioAtual : lblApoio.style.display = """"": i = i + 1
    arr(i) = "        Else": i = i + 1
    arr(i) = "            lblRaca.innerText = racaAtual : lblRaca.style.display = """"": i = i + 1
    arr(i) = "            lblEndereco.innerText = enderecoAtual : lblEndereco.style.display = """"": i = i + 1
    arr(i) = "            lblDtNasc.innerText = dtNascAtual : lblDtNasc.style.display = """"": i = i + 1
    arr(i) = "            lblDeficiencias.innerText = """" : lblDeficiencias.style.display = ""none""": i = i + 1
    arr(i) = "            lblRecurso.innerText = """" : lblRecurso.style.display = ""none""": i = i + 1
    arr(i) = "            lblApoio.innerText = """" : lblApoio.style.display = ""none""": i = i + 1
    arr(i) = "        End If": i = i + 1
    arr(i) = "        If transporteAtual <> """" Then lblTransporte.innerText = ""Transporte: "" & transporteAtual : lblTransporte.style.color = ""#2d7d46"" : If transporteAtual = ""RURAL"" Then lblTransporte.style.color = ""#c06a1b""": i = i + 1
    arr(i) = "        If transporteAtual = """" Then lblTransporte.innerText = ""Nao utiliza transporte"" : lblTransporte.style.color = ""#999""": i = i + 1
    arr(i) = "        If statusTexto <> """" Then": i = i + 1
    arr(i) = "            lblProgresso.innerText = statusTexto": i = i + 1
    arr(i) = "        Else": i = i + 1
    arr(i) = "            If totalTurmaAtual > 0 Then": i = i + 1
    arr(i) = "                perc = CInt((numAlunoAtual / totalTurmaAtual) * 100)": i = i + 1
    arr(i) = "                If perc < 0 Then perc = 0": i = i + 1
    arr(i) = "                If perc > 100 Then perc = 100": i = i + 1
    arr(i) = "                lblProgresso.innerText = perc & ""% concluido""": i = i + 1
    arr(i) = "                lblPercentual.innerText = perc & ""%""": i = i + 1
    arr(i) = "                barra.style.width = perc & ""%""": i = i + 1
    arr(i) = "            Else": i = i + 1
    arr(i) = "                lblProgresso.innerText = ""Aguardando...""": i = i + 1
    arr(i) = "                lblPercentual.innerText = ""0%""": i = i + 1
    arr(i) = "                barra.style.width = ""0%""": i = i + 1
    arr(i) = "            End If": i = i + 1
    arr(i) = "        End If": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub EnviarResposta(codigo)": i = i + 1
    arr(i) = "        If idReqAtual = """" Then Exit Sub": i = i + 1
    arr(i) = "        Dim fOut": i = i + 1
    arr(i) = "        Set fOut = fso.CreateTextFile(caminhoCtrlOut, True)": i = i + 1
    arr(i) = "        fOut.Write idReqAtual & ""|"" & CStr(codigo)": i = i + 1
    arr(i) = "        fOut.Close": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub btnAvancar_OnClick": i = i + 1
    arr(i) = "        EnviarResposta 6": i = i + 1
    arr(i) = "        btnAvancar.style.background=""#d0d8f0""": i = i + 1
    arr(i) = "        window.blur()": i = i + 1
    arr(i) = "        CreateObject(""WScript.Shell"").AppActivate ""Educacenso""": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub btnRepetir_OnClick": i = i + 1
    arr(i) = "        EnviarResposta 7": i = i + 1
    arr(i) = "        btnRepetir.style.background=""#d0d8f0""": i = i + 1
    arr(i) = "        window.blur()": i = i + 1
    arr(i) = "        CreateObject(""WScript.Shell"").AppActivate ""Educacenso""": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub btnVoltar_OnClick": i = i + 1
    arr(i) = "        EnviarResposta 9": i = i + 1
    arr(i) = "        btnVoltar.style.background=""#d0d8f0""": i = i + 1
    arr(i) = "        window.blur()": i = i + 1
    arr(i) = "        CreateObject(""WScript.Shell"").AppActivate ""Educacenso""": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub btnSair_OnClick": i = i + 1
    arr(i) = "        fechando = True": i = i + 1
    arr(i) = "        EnviarResposta 0": i = i + 1
    arr(i) = "        btnSair.style.background=""#f0d0d0""": i = i + 1
    arr(i) = "        window.close": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub Window_OnBeforeUnload": i = i + 1
    arr(i) = "        If Not fechando Then": i = i + 1
    arr(i) = "            Dim fso2, fOut2, pastaAtual2, caminhoCtrlOut2": i = i + 1
    arr(i) = "            Set fso2 = CreateObject(""Scripting.FileSystemObject"")": i = i + 1
    arr(i) = "            pastaAtual2 = Replace(document.location.pathname, ""/"", ""\\"")": i = i + 1
    arr(i) = "            If Left(pastaAtual2, 1) = ""\"" Then pastaAtual2 = Mid(pastaAtual2, 2)": i = i + 1
    arr(i) = "            pastaAtual2 = Replace(pastaAtual2, ""%20"", "" "")": i = i + 1
    arr(i) = "            pastaAtual2 = fso2.GetParentFolderName(pastaAtual2)": i = i + 1
    arr(i) = "            caminhoCtrlOut2 = pastaAtual2 & ""\ctrl_out.txt""": i = i + 1
    arr(i) = "            Set fOut2 = fso2.CreateTextFile(caminhoCtrlOut2, True)": i = i + 1
    arr(i) = "            fOut2.Write ""|0""": i = i + 1
    arr(i) = "            fOut2.Close": i = i + 1
    arr(i) = "        End If": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub btnCalibrar_OnClick": i = i + 1
    arr(i) = "        EnviarResposta 8": i = i + 1
    arr(i) = "        btnCalibrar.style.background=""#d0d8f0""": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub btnPausar_OnClick": i = i + 1
    arr(i) = "        If btnPausar.value = ""Pausar"" Then": i = i + 1
    arr(i) = "            EnviarResposta 5": i = i + 1
    arr(i) = "            btnPausar.value = ""Continuar""": i = i + 1
    arr(i) = "            btnPausar.style.borderColor=""#e67e22""": i = i + 1
    arr(i) = "            lblProgresso.innerText = ""*** PAUSADO ***""": i = i + 1
    arr(i) = "        Else": i = i + 1
    arr(i) = "            EnviarResposta 7": i = i + 1
    arr(i) = "            btnPausar.value = ""Pausar""": i = i + 1
    arr(i) = "            btnPausar.style.borderColor=" & Chr(34) & Chr(34): i = i + 1
    arr(i) = "            window.blur()": i = i + 1
    arr(i) = "            CreateObject(""WScript.Shell"").AppActivate ""Educacenso""": i = i + 1
    arr(i) = "        End If": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    Sub document_OnKeyDown": i = i + 1
    arr(i) = "        Dim k": i = i + 1
    arr(i) = "        k = window.event.keyCode": i = i + 1
    arr(i) = "        If window.event.ctrlKey Or window.event.altKey Or window.event.shiftKey Then Exit Sub": i = i + 1
    arr(i) = "        If k = 39 Then btnAvancar_OnClick  ' Seta Direita": i = i + 1
    arr(i) = "        If k = 37 Then btnVoltar_OnClick    ' Seta Esquerda": i = i + 1
    arr(i) = "        If k = 13 Then btnAvancar_OnClick    ' Enter": i = i + 1
    arr(i) = "        If k = 82 Then btnRepetir_OnClick    ' R": i = i + 1
    arr(i) = "        If k = 67 Then btnCalibrar_OnClick    ' C": i = i + 1
    arr(i) = "        If k = 27 Then btnSair_OnClick       ' Esc": i = i + 1
    arr(i) = "        If k = 80 Then btnPausar_OnClick     ' P": i = i + 1
    arr(i) = "    End Sub": i = i + 1
    arr(i) = "    </script>": i = i + 1
    arr(i) = "<style>": i = i + 1
    arr(i) = "    * { margin:0; padding:0; box-sizing:border-box; }": i = i + 1
    arr(i) = "    body { margin:0; font-family:Segoe UI,Arial,sans-serif; background:#dce0e8; color:#333333; font-size:13px; }": i = i + 1
    arr(i) = "    .container { padding:10px 14px 8px; background:#eceff5; min-height:100%; }": i = i + 1
    arr(i) = "    .topo { display:flex; align-items:center; justify-content:space-between; margin-bottom:10px; }": i = i + 1
    arr(i) = "    .topo-titulo { font-weight:700; font-size:16px; color:#4a5ab8; letter-spacing:1px; }": i = i + 1
    arr(i) = "    .topo-turma { font-size:13px; color:#666666; }": i = i + 1
    arr(i) = "    .cartao { background:#ffffff; border:1px solid #d0d5e0; border-radius:10px; padding:10px 14px; margin-bottom:10px; box-shadow:0 1px 4px rgba(0,0,0,0.06); }": i = i + 1
    arr(i) = "    .cartao-linha { display:flex; align-items:center; justify-content:space-between; }": i = i + 1
    arr(i) = "    .rotulo { font-size:11px; color:#888888; text-transform:uppercase; letter-spacing:0.5px; }": i = i + 1
    arr(i) = "    .valor { font-weight:600; color:#222222; }": i = i + 1
    arr(i) = "    .valor-nome { font-size:18px; font-weight:700; line-height:24px; color:#111111; }": i = i + 1
    arr(i) = "    .valor-cpf { font-size:16px; color:#555555; font-family:Consolas,monospace; letter-spacing:1px; }": i = i + 1
    arr(i) = "    .progresso-area { margin-top:10px; }": i = i + 1
    arr(i) = "    .progresso-info { display:flex; justify-content:space-between; font-size:11px; color:#888888; margin-bottom:4px; }": i = i + 1
    arr(i) = "    .barra-fundo { width:100%; height:14px; background:#e0e4ec; border-radius:7px; overflow:hidden; }": i = i + 1
    arr(i) = "    .barra-preenchimento { height:100%; width:0%; background:linear-gradient(90deg,#4b7bec,#6c5ce7); border-radius:7px; transition:width 0.3s; }": i = i + 1
    arr(i) = "    .botoes { display:flex; gap:6px; margin-top:10px; }": i = i + 1
    arr(i) = "    .botoes input { flex:1; min-width:80px; height:32px; border:2px solid #b0b8cc; border-radius:16px; background:#ffffff; color:#444444; font-size:12px; font-weight:600; cursor:pointer; outline:none; padding:0 8px; }": i = i + 1
    arr(i) = "    .botoes input:hover { background:#f0f4ff; border-color:#4b7bec; color:#4b7bec; }": i = i + 1
    arr(i) = "    .botoes input:active { background:#e0e8f8; }": i = i + 1
    arr(i) = "    .botoes .sair { border-color:#cc99a8; color:#c0392b; }": i = i + 1
    arr(i) = "    .botoes .sair:hover { background:#fff0f0; border-color:#c0392b; color:#c0392b; }": i = i + 1
    arr(i) = "    .rodape { text-align:center; font-size:9px; color:#aaaaaa; margin-top:4px; }": i = i + 1
    arr(i) = "</style>": i = i + 1
    arr(i) = "</head>": i = i + 1
    arr(i) = "<body>": i = i + 1
    arr(i) = "    <div class=""container"">": i = i + 1
    arr(i) = "        <div class=""topo"">": i = i + 1
    arr(i) = "            <span class=""topo-titulo"" id=""lblCabecalho"">EDUCACENSO</span>": i = i + 1
    arr(i) = "            <span class=""topo-turma"" id=""lblTurma""></span>": i = i + 1
    arr(i) = "        </div>": i = i + 1
    arr(i) = "        <div class=""cartao"">": i = i + 1
    arr(i) = "            <div class=""cartao-linha"">": i = i + 1
    arr(i) = "                <span class=""rotulo"">Registro</span>": i = i + 1
    arr(i) = "                <span class=""valor"" id=""lblAluno"">0 de 0</span>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "            <div style=""margin-top:6px;"">": i = i + 1
    arr(i) = "                <span class=""rotulo"">Aluno</span>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "            <div class=""valor-nome"" id=""lblNome""></div>": i = i + 1
    arr(i) = "            <div style=""margin-top:6px;"">": i = i + 1
    arr(i) = "                <span class=""rotulo"">CPF</span>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "            <div class=""valor-cpf"" id=""lblCpf""></div>": i = i + 1
    arr(i) = "            <div style=""margin-top:8px;display:flex;gap:20px;"">": i = i + 1
    arr(i) = "                <div>": i = i + 1
    arr(i) = "                    <span class=""rotulo"">Raça / Cor</span>": i = i + 1
    arr(i) = "                    <div style=""font-size:14px;font-weight:600;color:#444444;margin-top:2px;"" id=""lblRaca""></div>": i = i + 1
    arr(i) = "                </div>": i = i + 1
    arr(i) = "                <div>": i = i + 1
    arr(i) = "                    <span class=""rotulo"">Data Nasc.</span>": i = i + 1
    arr(i) = "                    <div style=""font-size:14px;font-weight:600;color:#444444;margin-top:2px;"" id=""lblDtNasc""></div>": i = i + 1
    arr(i) = "                </div>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "            <div style=""margin-top:6px;"">": i = i + 1
    arr(i) = "                <span class=""rotulo"">Endere&ccedil;o</span>": i = i + 1
    arr(i) = "                <div style=""font-size:13px;font-weight:500;color:#555555;margin-top:2px;"" id=""lblEndereco""></div>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "            <div style=""margin-top:4px;"">": i = i + 1
    arr(i) = "                <span class=""rotulo"">Transporte</span>": i = i + 1
    arr(i) = "                <div style=""font-size:13px;font-weight:700;margin-top:2px;"" id=""lblTransporte""></div>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "            <div style=""margin-top:4px;"" id=""divDeficiencias"">": i = i + 1
    arr(i) = "                <span class=""rotulo text-danger"">Defici&ecirc;ncias</span>": i = i + 1
    arr(i) = "                <div style=""font-size:13px;font-weight:600;color:#c0392b;margin-top:2px;"" id=""lblDeficiencias""></div>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "            <div style=""margin-top:4px;display:flex;gap:20px;"">": i = i + 1
    arr(i) = "                <div id=""divRecurso"">": i = i + 1
    arr(i) = "                    <span class=""rotulo"">Recurso</span>": i = i + 1
    arr(i) = "                    <div style=""font-size:14px;font-weight:600;color:#444444;margin-top:2px;"" id=""lblRecurso""></div>": i = i + 1
    arr(i) = "                </div>": i = i + 1
    arr(i) = "                <div id=""divApoio"">": i = i + 1
    arr(i) = "                    <span class=""rotulo"">Apoio</span>": i = i + 1
    arr(i) = "                    <div style=""font-size:14px;font-weight:600;color:#444444;margin-top:2px;"" id=""lblApoio""></div>": i = i + 1
    arr(i) = "                </div>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "            <div class=""progresso-area"">": i = i + 1
    arr(i) = "                <div class=""progresso-info"">": i = i + 1
    arr(i) = "                    <span id=""lblProgresso"">Aguardando...</span>": i = i + 1
    arr(i) = "                    <span id=""lblPercentual"">0%</span>": i = i + 1
    arr(i) = "                </div>": i = i + 1
    arr(i) = "                <div class=""barra-fundo"">": i = i + 1
    arr(i) = "                    <div class=""barra-preenchimento"" id=""barra""></div>": i = i + 1
    arr(i) = "                </div>": i = i + 1
    arr(i) = "                </div>": i = i + 1
    arr(i) = "            </div>": i = i + 1
    arr(i) = "        <div class=""botoes"">": i = i + 1
    arr(i) = "            <input type=""button"" id=""btnVoltar"" value=""< Retroceder"" onclick=""btnVoltar_OnClick"">": i = i + 1
    arr(i) = "            <input type=""button"" id=""btnAvancar"" value=""Avançar >"" onclick=""btnAvancar_OnClick"">": i = i + 1
    arr(i) = "            <input type=""button"" id=""btnRepetir"" value=""Repetir CPF"" onclick=""btnRepetir_OnClick"">": i = i + 1
    arr(i) = "            <input type=""button"" id=""btnPausar"" value=""Pausar"" onclick=""btnPausar_OnClick"">": i = i + 1
    arr(i) = "            <input type=""button"" id=""btnCalibrar"" value=""Calibrar"" onclick=""btnCalibrar_OnClick"">": i = i + 1
    arr(i) = "            <input type=""button"" id=""btnSair"" value=""Sair"" onclick=""btnSair_OnClick"" class=""sair"">": i = i + 1
    arr(i) = "        </div>": i = i + 1
    arr(i) = "        <div style=""text-align:center;font-size:10px;color:#999999;margin:4px 0 0;"">1&ordm; CPF: popup + OK. Demais: navegue at&eacute; o aluno no navegador e clique Avan&ccedil;ar</div>": i = i + 1
    arr(i) = "        <div class=""rodape"">": i = i + 1
    arr(i) = "            <span style=""color:#999;"">&larr; Voltar</span>": i = i + 1
    arr(i) = "            <span style=""color:#ccc;margin:0 4px;"">|</span>": i = i + 1
    arr(i) = "            <span style=""color:#999;"">&rarr; ou Enter = Avan&ccedil;ar</span>": i = i + 1
    arr(i) = "            <span style=""color:#ccc;margin:0 4px;"">|</span>": i = i + 1
    arr(i) = "            <span style=""color:#999;"">R = Repetir</span>": i = i + 1
    arr(i) = "            <span style=""color:#ccc;margin:0 4px;"">|</span>": i = i + 1
    arr(i) = "            <span style=""color:#999;"">P = Pausar</span>": i = i + 1
    arr(i) = "            <span style=""color:#ccc;margin:0 4px;"">|</span>": i = i + 1
    arr(i) = "            <span style=""color:#999;"">C = Calibrar</span>": i = i + 1
    arr(i) = "            <span style=""color:#ccc;margin:0 4px;"">|</span>": i = i + 1
    arr(i) = "            <span style=""color:#999;"">Esc = Sair</span>": i = i + 1
    arr(i) = "        </div>": i = i + 1
    arr(i) = "    </div>": i = i + 1
    arr(i) = "</body>": i = i + 1
    arr(i) = "</html>": i = i + 1

    hta = Join(arr, vbCrLf)
    Set fHTA = fso.CreateTextFile(pastaAtual & "\painel_controle.hta", True)
    fHTA.Write hta
    fHTA.Close
End Sub

' ============================================================================
Function SelecionarTurmaViaHTA()
    Dim hta, fHTA, caminhoResp, resp, grupos, g, inicios, fins, espera, fResp, tentativaFocus
    caminhoResp = pastaAtual & "\sel_turma_resp.txt"
    If fso.FileExists(caminhoResp) Then fso.DeleteFile caminhoResp

    hta = "<hta:application id=""oApp"" showintaskbar=""yes"" sysmenu=""no"" border=""dialog"" maximizebutton=""no"" minimizebutton=""no"" navigable=""no"" scroll=""auto"" />" & vbCrLf
    hta = hta & "<script language=""VBScript""> window.resizeTo 420,640 : window.moveTo (screen.width-420)/2, (screen.height-640)/2 </script>" & vbCrLf
    hta = hta & "<html style=""margin:0;padding:0;"">" & vbCrLf
    hta = hta & "<head>" & vbCrLf
    hta = hta & "<meta http-equiv=""X-UA-Compatible"" content=""IE=edge"">" & vbCrLf
    hta = hta & "<title>Seletor de Turma</title>" & vbCrLf
    hta = hta & "<style>" & vbCrLf
    hta = hta & "    * { margin:0; padding:0; box-sizing:border-box; }" & vbCrLf
    hta = hta & "    body { font-family:Segoe UI,Tahoma,sans-serif; font-size:12px; background:#f0f2f5; padding:6px 10px; }" & vbCrLf
    hta = hta & "    .cabecalho { font-size:14px; font-weight:700; color:#2c3e50; margin-bottom:6px; text-align:center; }" & vbCrLf
    hta = hta & "    .grupo { margin-bottom:4px; }" & vbCrLf
    hta = hta & "    .grupo-titulo { font-weight:700; font-size:11px; color:#4b7bec; padding:2px 0; border-bottom:1px solid #d0d5e0; margin-bottom:1px; }" & vbCrLf
    hta = hta & "    .turma-item { display:block; padding:2px 6px; cursor:pointer; font-size:11px; color:#333; border-bottom:1px solid #f0f0f0; }" & vbCrLf
    hta = hta & "    .turma-item:hover { background:#e8f0fe; color:#4b7bec; }" & vbCrLf
    hta = hta & "    .turma-item:active { background:#d0e0fc; }" & vbCrLf
    hta = hta & "    .turma-num { font-weight:700; color:#4b7bec; margin-right:3px; }" & vbCrLf
    hta = hta & "    .area-digitacao { display:flex; gap:4px; margin-top:6px; align-items:center; }" & vbCrLf
    hta = hta & "    .area-digitacao input { flex:1; height:28px; border:2px solid #b0b8cc; border-radius:14px; padding:0 10px; font-size:12px; font-weight:600; text-align:center; outline:none; }" & vbCrLf
    hta = hta & "    .area-digitacao input:focus { border-color:#4b7bec; }" & vbCrLf
    hta = hta & "    .area-digitacao button { height:28px; border:2px solid #4b7bec; border-radius:14px; background:#4b7bec; color:#fff; font-size:11px; font-weight:700; cursor:pointer; padding:0 12px; }" & vbCrLf
    hta = hta & "    .area-digitacao button:hover { background:#3a6bdc; }" & vbCrLf
    hta = hta & "    .rodape { display:flex; justify-content:space-between; margin-top:4px; font-size:10px; color:#999; align-items:center; }" & vbCrLf
    hta = hta & "    .rodape a { color:#c0392b; cursor:pointer; text-decoration:none; font-weight:600; }" & vbCrLf
    hta = hta & "</style>" & vbCrLf
    hta = hta & "<script language=""VBScript"">" & vbCrLf
    hta = hta & "    Sub Window_OnLoad" & vbCrLf
    hta = hta & "        window.focus" & vbCrLf
    hta = hta & "        txtNumero.focus" & vbCrLf
    hta = hta & "    End Sub" & vbCrLf
    hta = hta & "    Sub Selecionar(n)" & vbCrLf
    hta = hta & "        Dim f" & vbCrLf
    hta = hta & "        Set f = CreateObject(""Scripting.FileSystemObject"").CreateTextFile(""" & caminhoResp & """, True)" & vbCrLf
    hta = hta & "        f.Write CStr(n)" & vbCrLf
    hta = hta & "        f.Close" & vbCrLf
    hta = hta & "        window.Close" & vbCrLf
    hta = hta & "    End Sub" & vbCrLf
    hta = hta & "    Sub IrParaNumero" & vbCrLf
    hta = hta & "        Dim val, n" & vbCrLf
    hta = hta & "        val = Trim(txtNumero.value)" & vbCrLf
    hta = hta & "        If IsNumeric(val) Then" & vbCrLf
    hta = hta & "            n = CInt(val)" & vbCrLf
    hta = hta & "            If n >= 1 And n <= 21 Then" & vbCrLf
    hta = hta & "                Selecionar n" & vbCrLf
    hta = hta & "            Else" & vbCrLf
    hta = hta & "                MsgBox ""Digite um numero entre 1 e 21."", 48, ""Numero Invalido""" & vbCrLf
    hta = hta & "            End If" & vbCrLf
    hta = hta & "        Else" & vbCrLf
    hta = hta & "            MsgBox ""Digite um numero valido."", 48, ""Numero Invalido""" & vbCrLf
    hta = hta & "        End If" & vbCrLf
    hta = hta & "    End Sub" & vbCrLf
    hta = hta & "    Sub Sair" & vbCrLf
    hta = hta & "        Dim f" & vbCrLf
    hta = hta & "        Set f = CreateObject(""Scripting.FileSystemObject"").CreateTextFile(""" & caminhoResp & """, True)" & vbCrLf
    hta = hta & "        f.Write ""0""" & vbCrLf
    hta = hta & "        f.Close" & vbCrLf
    hta = hta & "        window.Close" & vbCrLf
    hta = hta & "    End Sub" & vbCrLf
    hta = hta & "    Sub txtNumero_OnKeyPress" & vbCrLf
    hta = hta & "        If window.event.keyCode = 13 Then IrParaNumero" & vbCrLf
    hta = hta & "    End Sub" & vbCrLf
    hta = hta & "</script>" & vbCrLf
    hta = hta & "</head>" & vbCrLf
    hta = hta & "<body>" & vbCrLf
    hta = hta & "    <div class=""cabecalho"">SELECIONE A TURMA</div>" & vbCrLf

    grupos = Array("ANOS INICIAIS (1 ao 6)", "AEE", "ETI", "EJA")
    inicios = Array(1, 13, 15, 19)
    fins = Array(12, 14, 18, 21)

    For g = 0 To 3
        hta = hta & "    <div class=""grupo"">" & vbCrLf
        hta = hta & "        <div class=""grupo-titulo"">" & grupos(g) & "</div>" & vbCrLf
        For i = inicios(g) To fins(g)
            hta = hta & "        <div class=""turma-item"" onclick=""Selecionar(" & i & ")""><span class=""turma-num"">[" & i & "]</span> " & turmas(i, 0) & "</div>" & vbCrLf
        Next
        hta = hta & "    </div>" & vbCrLf
    Next

    hta = hta & "    <div class=""area-digitacao"">" & vbCrLf
    hta = hta & "        <input type=""text"" id=""txtNumero"" placeholder=""Digite o numero..."">" & vbCrLf
    hta = hta & "        <button onclick=""IrParaNumero"">IR</button>" & vbCrLf
    hta = hta & "    </div>" & vbCrLf
    hta = hta & "    <div class=""rodape""><span>Digite o numero e Enter | Clique na turma</span><span><a onclick=""Sair"">[Fechar]</a></span></div>" & vbCrLf
    hta = hta & "</body>" & vbCrLf
    hta = hta & "</html>" & vbCrLf

    On Error Resume Next
    Call ApagarComRetry(pastaAtual & "\seletor_turma.hta")
    Set fHTA = fso.CreateTextFile(pastaAtual & "\seletor_turma.hta", True)
    fHTA.Write hta
    fHTA.Close
    On Error Goto 0

    shell.Run "mshta.exe """ & pastaAtual & "\seletor_turma.hta""", 1, False
    For tentativaFocus = 1 To 10
            WScript.Sleep 600
        If shell.AppActivate("Seletor de Turma") Then Exit For
    Next

    espera = 0
    Do While Not fso.FileExists(caminhoResp) And espera < 300
        WScript.Sleep 100
        espera = espera + 1
    Loop

    If fso.FileExists(caminhoResp) Then
        Set fResp = fso.OpenTextFile(caminhoResp, 1)
        resp = Trim(fResp.ReadAll)
        fResp.Close
        fso.DeleteFile caminhoResp
    Else
        resp = "0"
    End If

    Set fResp = Nothing
    Call ApagarComRetry(pastaAtual & "\seletor_turma.hta")

    SelecionarTurmaViaHTA = CInt(resp)
End Function