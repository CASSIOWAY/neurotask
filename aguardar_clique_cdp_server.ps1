# Persistent CDP server - handles multiple CPFs with auto-reconnect
$scriptPath = Split-Path $MyInvocation.MyCommand.Path
$cmdFile = Join-Path $scriptPath "cdp_cmd.txt"
$respFile = Join-Path $scriptPath "cdp_resp.txt"
$readyFile = Join-Path $scriptPath "cdp_ready.txt"
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
        f.focus();f.dispatchEvent(new Event('focus',{bubbles:true}));f.dispatchEvent(new Event('mousedown',{bubbles:true}));
        f.value='';f.dispatchEvent(new Event('input',{bubbles:true}));
        f.value=c;f.dispatchEvent(new Event('input',{bubbles:true}));f.dispatchEvent(new Event('change',{bubbles:true}));
        f.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',code:'Enter',bubbles:true,cancelable:true}));
        f.dispatchEvent(new KeyboardEvent('keyup',{key:'Enter',code:'Enter',bubbles:true,cancelable:true}));
    }
    var v=f?f.value.replace(/\D/g,''):'';
    var x=c.replace(/\D/g,'');
    if(v!==x)return JSON.stringify({e:2,t:tries,d:v});
    var r=f.getBoundingClientRect();return JSON.stringify({x:Math.round(r.left+r.width/2),y:Math.round(r.top+r.height/2)});
})();
"@

# JavaScript: scan page for CPF field (for tab discovery)
$jsScanCPF = @"
(function(){var f=document.querySelector('input[name*="cpf" i],input[id*="cpf" i],input[placeholder*="CPF" i]');return f?1:0})()
"@

# JavaScript: check page ready state
$jsPageReady = @"
document.readyState==='complete'
"@

# ---- Helper functions ----
$msgId = 0
function CDP($method, $params) {
    $script:msgId++
    $cmd = '{"id":' + $script:msgId + ',"method":"' + $method + '","params":' + (ConvertTo-Json $params -Compress -Depth 10) + '}'
    return [WS]::Send($script:cdp_ws, $cmd) | ConvertFrom-Json
}

function FindTargetTab {
    param([array]$pages)
    foreach ($p in $pages) {
        $t = $p.title; $u = $p.url
        if ($u -match "inep|educacenso|censo" -or $t -match "INEP|Educacenso|Educa|Censo|censo|DATA|data") { return $p.webSocketDebuggerUrl }
    }
    foreach ($p in $pages) {
        try {
            $tmp = [WS]::Connect($p.webSocketDebuggerUrl)
            $resp = [WS]::Send($tmp, '{"id":1,"method":"Runtime.evaluate","params":{"expression":' + (ConvertTo-Json $jsScanCPF -Compress) + ',"returnByValue":true}}') | ConvertFrom-Json
            [WS]::Close($tmp)
            if ($resp.result.value -eq 1) { return $p.webSocketDebuggerUrl }
        } catch {}
    }
    foreach ($p in $pages) {
        if ($p.url -ne "about:blank" -and $p.url -ne "chrome://newtab/" -and $p.url -ne "chrome://version/") { return $p.webSocketDebuggerUrl }
    }
    return $null
}

function EnsureConnection {
    try {
        if (-not $script:cdp_ws) { throw "no ws" }
        if ($script:cdp_ws.State -ne 1) { throw "not open" }
    } catch {
        try { [WS]::Close($script:cdp_ws) } catch {}
        if (-not $script:wsUrl) { return $false }
        try {
            $script:cdp_ws = [WS]::Connect($script:wsUrl)
            $script:msgId = 0
        } catch { return $false }
    }
    try {
        $pages = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 2 -ErrorAction Stop
        $found = $false
        foreach ($p in $pages) { if ($p.webSocketDebuggerUrl -eq $script:wsUrl) { $found = $true; break } }
        if (-not $found) { throw "tab gone" }
    } catch {
        try { $pages = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 2 -ErrorAction Stop } catch { return $false }
        $newUrl = FindTargetTab $pages
        if (-not $newUrl) { return $false }
        try { [WS]::Close($script:cdp_ws) } catch {}
        try {
            $script:cdp_ws = [WS]::Connect($newUrl)
            $script:wsUrl = $newUrl
            $script:msgId = 0
        } catch { return $false }
    }
    return $true
}

# ---- Initial connection with retry (up to 30s) ----
$wsUrl = $null
for ($attempt = 0; $attempt -lt 30 -and -not $wsUrl; $attempt++) {
    try { $pages = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 2 -ErrorAction Stop } catch { Start-Sleep 1; continue }
    $wsUrl = FindTargetTab $pages
    if (-not $wsUrl) { Start-Sleep 1 }
}
if (-not $wsUrl) { exit 2 }

try { $cdp_ws = [WS]::Connect($wsUrl) } catch { exit 2 }

# Clean up old files
Remove-Item $cmdFile, $respFile, $readyFile, $ctrlOut -Force -ErrorAction SilentlyContinue

# Wait for page to be fully loaded (up to 30s)
for ($loadWait = 0; $loadWait -lt 30; $loadWait++) {
    try {
        $r = CDP "Runtime.evaluate" @{expression = $jsPageReady; returnByValue = $true}
        if ($r.result.value -eq $true) { break }
    } catch {}
    Start-Sleep 1
}

# Signal ready
[System.IO.File]::WriteAllText($readyFile, "1")

# ---- Main command loop ----
while ($true) {
    Start-Sleep -Milliseconds 10
    if (-not (Test-Path $cmdFile)) { continue }

    $cmdData = Get-Content $cmdFile -Raw -Encoding ASCII
    Remove-Item $cmdFile -Force -ErrorAction SilentlyContinue
    $cmdData = ($cmdData -replace "`r|`n", "").Trim()
    if ($cmdData -eq "" -or $cmdData -eq "EXIT") { break }

    Remove-Item $readyFile -Force -ErrorAction SilentlyContinue
    Remove-Item $ctrlOut -Force -ErrorAction SilentlyContinue

    if (-not (EnsureConnection)) {
        [System.IO.File]::WriteAllText($respFile, "-1")
        [System.IO.File]::WriteAllText($readyFile, "1")
        continue
    }

    # Type CPF with auto-retry on failure
    $typeResult = $null
    for ($retry = 0; $retry -lt 3; $retry++) {
        try {
            $typeResult = CDP "Runtime.evaluate" @{expression = "$jsTypeCPF('$cmdData')"; returnByValue = $true}
            if ($typeResult.result.value.x) { break }
            if ($typeResult.result.value.e -eq 2) {
                # Value mismatch - retry
                Start-Sleep -Milliseconds 500
                continue
            }
        } catch {
            try { [WS]::Close($cdp_ws) } catch {}
            try {
                $cdp_ws = [WS]::Connect($wsUrl); $msgId = 0;
                $typeResult = CDP "Runtime.evaluate" @{expression = "$jsTypeCPF('$cmdData')"; returnByValue = $true}
                if ($typeResult.result.value.x) { break }
            } catch {}
        }
    }

    # Monitor for panel response (wait indefinitely for user click)
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

    # Handle Repetir (code 7): retype via CDP
    if ($respCode -eq 7) {
        if (EnsureConnection) {
            for ($retry = 0; $retry -lt 3; $retry++) {
                try {
                    $typeResult = CDP "Runtime.evaluate" @{expression = "$jsTypeCPF('$cmdData')"; returnByValue = $true} | Out-Null
                    if ($typeResult.result.value.x) { break }
                    if ($typeResult.result.value.e -eq 2) { Start-Sleep -Milliseconds 500; continue }
                } catch {}
            }
        }
        $respCode = 7
    }

    # Write response
    [System.IO.File]::WriteAllText($respFile, [string]$respCode)
    [System.IO.File]::WriteAllText($readyFile, "1")
}

[WS]::Close($cdp_ws)
Remove-Item $readyFile, $respFile, $cmdFile -Force -ErrorAction SilentlyContinue
