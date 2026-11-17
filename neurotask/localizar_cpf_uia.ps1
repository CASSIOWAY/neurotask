param($outFile)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindowEx(IntPtr hWndParent, IntPtr hWndChildAfter, string lpszClass, string lpszWindow);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
public struct RECT { public int left; public int top; public int right; public int bottom; }
"@

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# Find Chrome window by title
$hwnd = [IntPtr]::Zero
$procs = Get-Process chrome -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    if ($p.MainWindowTitle -match "INEP|Educacenso|SIG.*Aluno|Cadastro.*Aluno") {
        $hwnd = $p.MainWindowHandle; break
    }
}
if ($hwnd -eq [IntPtr]::Zero) { exit 1 }

$chromeRect = New-Object RECT
[Win32]::GetWindowRect($hwnd, [ref]$chromeRect)

# Find the Chrome_RenderWidgetHostHWND child (contains the web page)
$renderHwnd = [Win32]::FindWindowEx($hwnd, [IntPtr]::Zero, "Chrome_RenderWidgetHostHWND", $null)
if ($renderHwnd -eq [IntPtr]::Zero) {
    # Try deeper: some newer Chrome versions nest it
    $child = [Win32]::FindWindowEx($hwnd, [IntPtr]::Zero, "Chrome_WidgetWin_1", $null)
    while ($child -ne [IntPtr]::Zero) {
        $renderHwnd = [Win32]::FindWindowEx($child, [IntPtr]::Zero, "Chrome_RenderWidgetHostHWND", $null)
        if ($renderHwnd -ne [IntPtr]::Zero) { break }
        $child = [Win32]::FindWindowEx($hwnd, $child, "Chrome_WidgetWin_1", $null)
    }
}

# Use the main window if render widget not found
$targetHwnd = $hwnd
if ($renderHwnd -ne [IntPtr]::Zero) { $targetHwnd = $renderHwnd }

$element = [System.Windows.Automation.AutomationElement]::FromHandle($targetHwnd)
if ($element -eq $null) { exit 1 }

# Search for "CPF" in the accessibility tree
$all = $element.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
if ($all -eq $null -or $all.Count -eq 0) { exit 1 }

$found = $false
$cpfRect = $null

for ($i = 0; $i -lt $all.Count; $i++) {
    $name = ""
    $ctrlType = ""
    try {
        $name = $all[$i].Current.Name
        $ctrlType = $all[$i].Current.ControlType.ProgrammaticName
    } catch { continue }
    
    if ($name -eq "" -or $name -eq $null) { continue }
    $upper = $name.ToUpperInvariant()
    
    # Found a label containing "CPF"
    if (($upper -eq "CPF" -or $upper -eq "CPF:" -or $upper.StartsWith("CPF")) -or
        ($upper -match "CPF" -and $ctrlType -ne "Edit")) {
        $rect = $all[$i].Current.BoundingRectangle
        if ($rect.Width -gt 0 -and $rect.Height -gt 0) {
            $cpfRect = $rect
            $found = $true
            break
        }
    }
    
    # Also catch if the input field itself has "cpf" in its name
    if ($ctrlType -eq "Edit" -and $upper -match "CPF") {
        $rect = $all[$i].Current.BoundingRectangle
        if ($rect.Width -gt 0 -and $rect.Height -gt 0) {
            $cpfRect = $rect
            $found = $true
            break
        }
    }
}

if (-not $found) { exit 1 }

# Input field is to the right of the CPF label
$relX = [int]($cpfRect.Left + $cpfRect.Width + 8)
$relY = [int]($cpfRect.Top + $cpfRect.Height / 2)

# Fallback: if the found element IS the input, click its center
if ($all | Where-Object { 
    $_.Current.ControlType.ProgrammaticName -eq "Edit" -and 
    $_.Current.BoundingRectangle.Left -eq $cpfRect.Left
}) {
    $relX = [int]($cpfRect.Left + $cpfRect.Width / 2)
    $relY = [int]($cpfRect.Top + $cpfRect.Height / 2)
}

# Convert to absolute and verify within Chrome window
$absX = $relX + $chromeRect.left
$absY = $relY + $chromeRect.top
if ($absX -lt $chromeRect.left -or $absX -gt $chromeRect.right -or
    $absY -lt $chromeRect.top -or $absY -gt $chromeRect.bottom) { exit 1 }

"$relX|$relY|$($chromeRect.left)|$($chromeRect.top)" | Out-File -FilePath $outFile -Encoding ASCII -NoNewline
exit 0
