# CDP script - single-use, fallback when CDP server is down
param($cpfNumero)

$scriptPath = Split-Path $MyInvocation.MyCommand.Path
$ctrlOut = Join-Path $scriptPath "ctrl_out.txt"

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
public class Native {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
public class WS {
    public static ClientWebSocket Connect(string url) {
        var ws = new ClientWebSocket();
        ws.ConnectAsync(new Uri(url), CancellationToken.None).GetAwaiter().GetResult();
        return ws;
    }
    public static string Send(ClientWebSocket ws, string command) {
        byte[] buf = Encoding.UTF8.GetBytes(command);
        ws.SendAsync(new ArraySegment<byte>(buf), WebSocketMessageType.Text, true, CancellationToken.None).GetAwaiter().GetResult();
        var recv = new byte[131072];
        var result = ws.ReceiveAsync(new ArraySegment<byte>(recv), CancellationToken.None).GetAwaiter().GetResult();
        return Encoding.UTF8.GetString(recv, 0, result.Count);
    }
    public static void Close(ClientWebSocket ws) {
        try { ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "", CancellationToken.None).GetAwaiter().GetResult(); } catch {}
    }
}
"@

Add-Type -AssemblyName System.Windows.Forms

# JavaScript: type CPF with verification
$jsTypeCPF = @"
(function(c){
    if(c.length===11)c=c.substring(0,3)+'.'+c.substring(3,6)+'.'+c.substring(6,9)+'-'+c.substring(9,11);
    var tries=0,f=null;
    while(tries<3&&(!f||f.value.replace(/\D/g,'')!==c.replace(/\D/g,''))){
        tries++;f=null;var waits=0;
        while(!f&&waits<50){waits++;
            f=document.querySelector('input[name*="cpf" i],input[id*="cpf" i],input[placeholder*="CPF" i],input[class*="cpf" i]');
            if(!f){var ls=document.querySelectorAll('label,span,div,strong');for(var i=0;i<ls.length;i++){var t=(ls[i].textContent||'').trim().toUpperCase();if(t==='CPF'||t==='CPF:'||t.startsWith('CPF')){var sib=ls[i].nextElementSibling;while(sib){if(sib.tagName==='INPUT'||sib.tagName==='SELECT'||sib.tagName==='TEXTAREA'){f=sib;break}sib=sib.nextElementSibling}if(!f&&ls[i].parentElement){var inp=ls[i].parentElement.querySelectorAll('input,select,textarea');if(inp.length>0)f=inp[0]}if(f)break}}}
            if(!f){var al=document.querySelectorAll('input[type="text"],input:not([type]),input[type="tel"]');for(var i=0;i<al.length;i++){if(al[i].offsetParent!==null&&!al[i].disabled&&!al[i].readOnly){f=al[i];break}}}
            if(!f){var t0=Date.now();while(Date.now()-t0<200){}}
        }
        if(!f)return JSON.stringify({e:1,t:tries});
        f.focus();f.dispatchEvent(new Event('focus',{bubbles:true}));
        f.value='';f.dispatchEvent(new Event('input',{bubbles:true}));
        f.value=c;f.dispatchEvent(new Event('input',{bubbles:true}));f.dispatchEvent(new Event('change',{bubbles:true}));
    }
    var v=f?f.value.replace(/\D/g,''):'';
    var x=c.replace(/\D/g,'');
    if(v!==x)return JSON.stringify({e:2,t:tries,d:v});
    var r=f.getBoundingClientRect();return JSON.stringify({x:Math.round(r.left+r.width/2),y:Math.round(r.top+r.height/2)});
})();
"@

# JS scan for CPF field
$jsScanCPF = @"
(function(){var f=document.querySelector('input[name*="cpf" i],input[id*="cpf" i],input[placeholder*="CPF" i]');return f?1:0})()
"@

# JS page ready check
$jsPageReady = @"
document.readyState==='complete'
"@

# Connect to Chrome with retry (quick check - fallback script)
for ($attempt = 0; $attempt -lt 3; $attempt++) {
    try { $pages = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 2 -ErrorAction Stop; break } catch { Start-Sleep 1 }
    if ($attempt -eq 2) { exit 2 }
}

# Find target tab with retry (quick check)
$wsUrl = $null
for ($attempt = 0; $attempt -lt 3 -and -not $wsUrl; $attempt++) {
    try { $pages = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 2 -ErrorAction Stop } catch { Start-Sleep 1; continue }
    foreach ($p in $pages) {
        $t = $p.title; $u = $p.url
        if ($u -match "inep|educacenso|censo" -or $t -match "INEP|Educacenso|Educa|Censo|censo|DATA|data") { $wsUrl = $p.webSocketDebuggerUrl; break }
    }
    if (-not $wsUrl) {
        foreach ($p in $pages) {
            try {
                $tmp = [WS]::Connect($p.webSocketDebuggerUrl)
                $resp = [WS]::Send($tmp, '{"id":1,"method":"Runtime.evaluate","params":{"expression":' + (ConvertTo-Json $jsScanCPF -Compress) + ',"returnByValue":true}}') | ConvertFrom-Json
                [WS]::Close($tmp)
                if ($resp.result.value -eq 1) { $wsUrl = $p.webSocketDebuggerUrl; break }
            } catch {}
        }
    }
    if (-not $wsUrl) {
        foreach ($p in $pages) { if ($p.url -ne "about:blank" -and $p.url -ne "chrome://newtab/" -and $p.url -ne "chrome://version/") { $wsUrl = $p.webSocketDebuggerUrl; break } }
    }
    if (-not $wsUrl) { Start-Sleep 1 }
}
if (-not $wsUrl) { exit 2 }

$msgId = 0
function CDP($method, $params) {
    $script:msgId++
    $cmd = '{"id":' + $script:msgId + ',"method":"' + $method + '","params":' + (ConvertTo-Json $params -Compress -Depth 10) + '}'
    return [WS]::Send($script:cdp_ws, $cmd) | ConvertFrom-Json
}

try { $cdp_ws = [WS]::Connect($wsUrl) } catch { exit 2 }

# Wait for page to be fully loaded (up to 30s)
for ($loadWait = 0; $loadWait -lt 30; $loadWait++) {
    try {
        $r = CDP "Runtime.evaluate" @{expression = $jsPageReady; returnByValue = $true}
        if ($r.result.value -eq $true) { break }
    } catch {}
    Start-Sleep 1
}

# 1) Focus the CPF field
$jsFocus = @"
(function(){
    var f=document.querySelector('input[name*="cpf" i],input[id*="cpf" i],input[placeholder*="CPF" i],input[class*="cpf" i]');
    if(!f){var ls=document.querySelectorAll('label,span,div,strong');for(var i=0;i<ls.length;i++){var t=(ls[i].textContent||'').trim().toUpperCase();if(t==='CPF'||t==='CPF:'||t.startsWith('CPF')){var sib=ls[i].nextElementSibling;while(sib){if(sib.tagName==='INPUT'||sib.tagName==='SELECT'||sib.tagName==='TEXTAREA'){f=sib;break}sib=sib.nextElementSibling}if(!f&&ls[i].parentElement){var inp=ls[i].parentElement.querySelectorAll('input,select,textarea');if(inp.length>0)f=inp[0]}if(f)break}}}
    if(!f){var al=document.querySelectorAll('input[type="text"],input:not([type]),input[type="tel"]');for(var i=0;i<al.length;i++){if(al[i].offsetParent!==null&&!al[i].disabled&&!al[i].readOnly){f=al[i];break}}}
    if(!f)return JSON.stringify({e:1});
    f.focus();f.dispatchEvent(new Event('focus',{bubbles:true}));
    return JSON.stringify({e:0});
})();
"@
$r1 = CDP "Runtime.evaluate" @{expression = $jsFocus; returnByValue = $true}
if ($r1.result.value.e) { [WS]::Close($cdp_ws); exit 2 }

Start-Sleep -Seconds 2

# 2) Type CPF with auto-retry
for ($retry = 0; $retry -lt 3; $retry++) {
    $typeResult = CDP "Runtime.evaluate" @{expression = "$jsTypeCPF('$cpfNumero')"; returnByValue = $true}
    if ($typeResult.result.value.x) { break }
    if ($typeResult.result.value.e -eq 2) { Start-Sleep -Milliseconds 500; continue }
    Start-Sleep -Milliseconds 300
}

Start-Sleep -Seconds 2

# 3) Press Enter to search
CDP "Input.dispatchKeyEvent" @{type="keyDown"; windowsVirtualKeyCode=0x0D; key="Enter"; code="Enter"} | Out-Null
CDP "Input.dispatchKeyEvent" @{type="keyUp"; windowsVirtualKeyCode=0x0D; key="Enter"; code="Enter"} | Out-Null

# Monitor for panel response (wait indefinitely)
$respCode = -1
while ($respCode -lt 0) {
    Start-Sleep -Milliseconds 100
    if (-not (Test-Path $ctrlOut)) { continue }
    try {
        $d = Get-Content $ctrlOut -Raw -Encoding ASCII
        Remove-Item $ctrlOut -Force -ErrorAction SilentlyContinue
        $d = $d.Trim()
        if ($d -ne "") {
            $p = $d -split '\|'
            if ($p.Count -ge 2) { $respCode = [int]$p[1] }
        }
    } catch {}
}

if ($respCode -eq 7) {
    # Repetir: retype with auto-retry
    $jsFocus2 = @"
(function(){
    var f=document.querySelector('input[name*="cpf" i],input[id*="cpf" i],input[placeholder*="CPF" i],input[class*="cpf" i]');
    if(!f){var ls=document.querySelectorAll('label,span,div,strong');for(var i=0;i<ls.length;i++){var t=(ls[i].textContent||'').trim().toUpperCase();if(t==='CPF'||t==='CPF:'||t.startsWith('CPF')){var sib=ls[i].nextElementSibling;while(sib){if(sib.tagName==='INPUT'||sib.tagName==='SELECT'||sib.tagName==='TEXTAREA'){f=sib;break}sib=sib.nextElementSibling}if(!f&&ls[i].parentElement){var inp=ls[i].parentElement.querySelectorAll('input,select,textarea');if(inp.length>0)f=inp[0]}if(f)break}}}
    if(!f){var al=document.querySelectorAll('input[type="text"],input:not([type]),input[type="tel"]');for(var i=0;i<al.length;i++){if(al[i].offsetParent!==null&&!al[i].disabled&&!al[i].readOnly){f=al[i];break}}}
    if(!f)return;f.focus();f.dispatchEvent(new Event('focus',{bubbles:true}));
})();
"@
    try { CDP "Runtime.evaluate" @{expression = $jsFocus2; returnByValue = $true} | Out-Null } catch {}
    Start-Sleep -Seconds 2
    for ($retry = 0; $retry -lt 3; $retry++) {
        try {
            $typeResult = CDP "Runtime.evaluate" @{expression = "$jsTypeCPF('$cpfNumero')"; returnByValue = $true} | Out-Null
            if ($typeResult.result.value.x) { break }
            if ($typeResult.result.value.e -eq 2) { Start-Sleep -Milliseconds 500; continue }
        } catch {}
    }
    Start-Sleep -Seconds 2
    try {
        CDP "Input.dispatchKeyEvent" @{type="keyDown"; windowsVirtualKeyCode=0x0D; key="Enter"; code="Enter"} | Out-Null
        CDP "Input.dispatchKeyEvent" @{type="keyUp"; windowsVirtualKeyCode=0x0D; key="Enter"; code="Enter"} | Out-Null
    } catch {}
}

[WS]::Close($cdp_ws)
try { $wshell = New-Object -ComObject WScript.Shell; $wshell.AppActivate("Educacenso") } catch {}
exit $respCode
