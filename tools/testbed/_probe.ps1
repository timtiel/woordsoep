# Hulpscript voor het testbed: screenshot maken van, klikken of slepen in het venster.
# Gebruik:
#   powershell -ExecutionPolicy Bypass -File tools\testbed\_probe.ps1 -Action info
#   powershell -ExecutionPolicy Bypass -File tools\testbed\_probe.ps1 -Action shot [-Out pad.png]
#   powershell -ExecutionPolicy Bypass -File tools\testbed\_probe.ps1 -Action click -X <client-x> -Y <client-y>
#   powershell -ExecutionPolicy Bypass -File tools\testbed\_probe.ps1 -Action drag -X <x1> -Y <y1> -X2 <x2> -Y2 <y2>
param(
    [ValidateSet("shot", "click", "drag", "key", "info")]
    [string]$Action = "shot",
    [int]$X = 0,
    [int]$Y = 0,
    [int]$X2 = 0,
    [int]$Y2 = 0,
    [string]$Out = "",
    [string]$Key = "{ESC}"
)

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32 {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
}
"@

$proc = Get-Process qml -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -like "Woordsoep*" } |
    Select-Object -First 1
if (-not $proc) {
    Write-Host "Venster niet gevonden - draait het testbed wel?"
    exit 1
}
$h = $proc.MainWindowHandle

# Venster naar de voorgrond: SW_RESTORE + top + Alt-truc (Windows blokkeert
# SetForegroundWindow anders als een ander programma de voorgrond vasthoudt).
[void][W32]::ShowWindow($h, 9)
[void][W32]::BringWindowToTop($h)
[W32]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)          # Alt indrukken
[void][W32]::SetForegroundWindow($h)
[W32]::keybd_event(0x12, 0, 0x0002, [UIntPtr]::Zero)     # Alt loslaten
$fg = [W32]::GetForegroundWindow()
if ($fg -ne $h) {
    Write-Host "WAARSCHUWING: testbed is niet naar de voorgrond te halen - klik wordt NIET uitgevoerd."
    exit 2
}

switch ($Action) {
    "info" {
        $wr = New-Object W32+RECT; [void][W32]::GetWindowRect($h, [ref]$wr)
        $cr = New-Object W32+RECT; [void][W32]::GetClientRect($h, [ref]$cr)
        $pt = New-Object W32+POINT; $pt.X = 0; $pt.Y = 0
        [void][W32]::ClientToScreen($h, [ref]$pt)
        Write-Host ("Window: {0},{1} - {2},{3}" -f $wr.Left, $wr.Top, $wr.Right, $wr.Bottom)
        Write-Host ("Client: {0} x {1} op schermpositie {2},{3}" -f ($cr.Right - $cr.Left), ($cr.Bottom - $cr.Top), $pt.X, $pt.Y)
    }
    "click" {
        $pt = New-Object W32+POINT; $pt.X = 0; $pt.Y = 0
        [void][W32]::ClientToScreen($h, [ref]$pt)
        $px = $pt.X + $X
        $py = $pt.Y + $Y
        [void][W32]::SetCursorPos($px, $py)
        [W32]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
        [W32]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
        Write-Host ("Klik op schermpositie {0},{1} (client {2},{3})" -f $px, $py, $X, $Y)
    }
    "drag" {
        $pt = New-Object W32+POINT; $pt.X = 0; $pt.Y = 0
        [void][W32]::ClientToScreen($h, [ref]$pt)
        $sx = $pt.X + $X
        $sy = $pt.Y + $Y
        $ex = $pt.X + $X2
        $ey = $pt.Y + $Y2
        [void][W32]::SetCursorPos($sx, $sy)
        [W32]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
        for ($i = 1; $i -le 12; $i++) {
            $mx = [int]($sx + ($ex - $sx) * $i / 12)
            $my = [int]($sy + ($ey - $sy) * $i / 12)
            [void][W32]::SetCursorPos($mx, $my)
            [W32]::mouse_event(0x0001, 0, 0, 0, [UIntPtr]::Zero)
        }
        [W32]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
        Write-Host ("Drag van client {0},{1} naar {2},{3}" -f $X, $Y, $X2, $Y2)
    }
    "key" {
        $ws = New-Object -ComObject WScript.Shell
        $ws.SendKeys($Key)
        Write-Host ("Toets verzonden: " + $Key)
    }
    "shot" {
        $wr = New-Object W32+RECT; [void][W32]::GetWindowRect($h, [ref]$wr)
        $w = $wr.Right - $wr.Left
        $hh = $wr.Bottom - $wr.Top
        $bmp = New-Object System.Drawing.Bitmap($w, $hh)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($wr.Left, $wr.Top, 0, 0, (New-Object System.Drawing.Size($w, $hh)))
        if (-not $Out) { $Out = Join-Path $env:TEMP "woordsoep_testbed.png" }
        $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose()
        $bmp.Dispose()
        Write-Host ("Screenshot opgeslagen: {0} ({1} x {2})" -f $Out, $w, $hh)
    }
}
