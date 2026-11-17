param($outFile)

$scriptPath = Split-Path $MyInvocation.MyCommand.Path

# Try to connect to Chrome DevTools
$ws = $null
try {
    $resp = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 3 -ErrorAction Stop
} catch { exit 1 }

# Find the Educacenso/INEP tab
$targetUrl = ""
$wsUrl = ""
foreach ($page in $resp) {
    if ($page.title -match "INEP|Educacenso|Educa" -or $page.url -match "inep|educacenso") {
        $wsUrl = $page.webSocketDebuggerUrl
        $targetUrl = $page.url
        break
    }
}
if ([string]::IsNullOrEmpty($wsUrl)) { exit 1 }

# Connect via WebSocket and execute JS to find CPF field
Add-Type @"
using System;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Runtime.InteropServices;
public class CDP {
    public static string SendAndReceive(string wsUrl, string command) {
        var ws = new ClientWebSocket();
        ws.ConnectAsync(new Uri(wsUrl), CancellationToken.None).GetAwaiter().GetResult();
        byte[] buf = Encoding.UTF8.GetBytes(command);
        ws.SendAsync(new ArraySegment<byte>(buf), WebSocketMessageType.Text, true, CancellationToken.None).GetAwaiter().GetResult();
        var recv = new byte[65536];
        var result = ws.ReceiveAsync(new ArraySegment<byte>(recv), CancellationToken.None).GetAwaiter().GetResult();
        ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "", CancellationToken.None).GetAwaiter().GetResult();
        return Encoding.UTF8.GetString(recv, 0, result.Count);
    }
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}
public struct RECT { public int left; public int top; public int right; public int bottom; }
"@

# Step 1: Find the CPF input field via JS
$js1 = @"
(function() {
    // Look for input fields near "CPF" label
    var labels = document.querySelectorAll('label, span, div, strong');
    var cpfField = null;
    for (var i = 0; i < labels.length; i++) {
        var txt = (labels[i].textContent || '').trim().toUpperCase();
        if (txt === 'CPF' || txt === 'CPF:' || txt === 'CPF :' || txt.startsWith('CPF')) {
            // Look for the nearest input/select after this label
            var el = labels[i];
            // Check siblings first
            var sib = el.nextElementSibling;
            while (sib) {
                if (sib.tagName === 'INPUT' || sib.tagName === 'SELECT' || sib.tagName === 'TEXTAREA') {
                    cpfField = sib; break;
                }
                sib = sib.nextElementSibling;
            }
            if (!cpfField) {
                // Check parent's children
                var parent = el.parentElement;
                if (parent) {
                    var inputs = parent.querySelectorAll('input, select, textarea');
                    if (inputs.length > 0) { cpfField = inputs[0]; }
                }
            }
            if (!cpfField) {
                // Try following::input XPath equivalent via DOM
                var walk = el;
                while (walk && walk.nextSibling) {
                    walk = walk.nextSibling;
                    if (walk.nodeType === 1 && (walk.tagName === 'INPUT' || walk.tagName === 'SELECT' || walk.tagName === 'TEXTAREA')) {
                        cpfField = walk; break;
                    }
                }
            }
            if (cpfField) break;
        }
    }
    // Fallback: look for input with name/id containing "cpf"
    if (!cpfField) {
        cpfField = document.querySelector('input[name*="cpf" i], input[id*="cpf" i], input[class*="cpf" i]');
    }
    if (!cpfField) {
        // Last resort: find the first visible text input
        var allInputs = document.querySelectorAll('input[type="text"], input:not([type])');
        for (var i = 0; i < allInputs.length; i++) {
            if (allInputs[i].offsetParent !== null) { cpfField = allInputs[i]; break; }
        }
    }
    if (!cpfField) return JSON.stringify({error: 'CPF field not found'});
    var rect = cpfField.getBoundingClientRect();
    return JSON.stringify({
        x: Math.round(rect.left + rect.width / 2),
        y: Math.round(rect.top + rect.height / 2),
        width: rect.width,
        height: rect.height
    });
})();
"@

$cmd1 = @"
{"id":1,"method":"Runtime.evaluate","params":{"expression":$(ConvertTo-Json $js1 -Compress),"returnByValue":true}}
"@

try {
    $result1 = [CDP]::SendAndReceive($wsUrl, $cmd1)
    $json1 = $result1 | ConvertFrom-Json
    $value = $json1.result.value
    if ($value.error) { exit 1 }
    $relX = [int]$value.x
    $relY = [int]$value.y
} catch { exit 1 }

# Step 2: Get Chrome window position for absolute coords
$hwnd = [IntPtr]::Zero
$procs = Get-Process chrome -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    if ($p.MainWindowTitle -match "INEP|Educacenso") { $hwnd = $p.MainWindowHandle; break }
}
if ($hwnd -eq [IntPtr]::Zero) {
    $procs = Get-Process msedge -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        if ($p.MainWindowTitle -match "INEP|Educacenso") { $hwnd = $p.MainWindowHandle; break }
    }
}
if ($hwnd -eq [IntPtr]::Zero) { exit 1 }

$rc = New-Object RECT
[CDP]::GetWindowRect($hwnd, [ref]$rc)

# Output in same format as get_cursor_pos.ps1
"$relX|$relY|$rc.left|$rc.top" | Out-File -FilePath $outFile -Encoding ASCII -NoNewline
exit 0
