Set sh = CreateObject("WScript.Shell")
WScript.Sleep 200
If sh.AppActivate("Controle de Fluxo - Educacenso") Then
    WScript.Sleep 100
    sh.SendKeys "% n"
End If
