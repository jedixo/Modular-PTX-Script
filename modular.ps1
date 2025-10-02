# modular - Wrapper to configure Network Settings on Modular PTX screens
# Built by Jake Dixon
#
# requires plink.exe from the putty application
# 
# ChangeLog:
#    15/09/2025
#      - Initial Code Written
#    16/09/2025
#      - Tested & worked successfully in the field
#      - Added Pause at end to review output instead of
#        the window just closing.
#    17/09/2025
#      - Integrated all options into one dialog
#      - Added additional configurable options with Dawson Mine Defaults
#    18/09/2025
#      - Added handling of root user

# add a helper
Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
function Hide-Console {
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [void][Console.Window]::ShowWindow($consolePtr, 0)
}
function Show-Console {
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [void][Console.Window]::ShowWindow($consolePtr, 5)
}
Hide-Console

# Default Variables
$MTU            = 1400
$PTXTargetMask  = "/22"
$InitialIP      = "192.168.0.111"
$NetworkFirstTwoOctets = "10.48."
$TimeZone       = "Australia/Brisbane"
$Gateway        = "10.48.108.1"
$NTPServer      = "10.61.126.153"
$ModularUN      = "mms"
$PLinkPath      = "./plink.exe"
$sudoPrefix     = "sudo"

if (Test-path "commands.sh") {
    Remove-Item "commands.sh" -Force
}

Clear-Host
write-host -foregroundcolor Cyan "Modular PTX Network Configuration Utility"
write-host -foregroundcolor Cyan "Written By: Jake Dixon"
Write-Host ""

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.Text = "Modular PTX Network Configuration Utility"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Size = New-Object System.Drawing.Size(400, 400)

$form.Add_FormClosed({
    write-host -foregroundcolor Red "ERROR: Operating Aborted."
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

$PTXVerGroup = New-Object System.Windows.Forms.GroupBox
$PTXVerGroup.Text = "PTX Version"
$PTXVerGroup.Location = New-Object System.Drawing.Point(15,5)
$PTXVerGroup.AutoSize = $true
$PTXVerGroup.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink

$PTX7RB = New-Object System.Windows.Forms.RadioButton
$PTX7RB.Text = "PTX 7 / 10"
$PTX7RB.Location = New-Object System.Drawing.Point(20, 20)
$PTX7RB.Checked = $true  # Default selection
$PTXCRB = New-Object System.Windows.Forms.RadioButton
$PTXCRB.Text = "PTXC"
$PTXCRB.Location = New-Object System.Drawing.Point(20, 50)

$ConnectionGroup = New-Object System.Windows.Forms.GroupBox
$ConnectionGroup.Text = "PTX Connection Details"
$ConnectionGroup.Location = New-Object System.Drawing.Point(150,5)
$ConnectionGroup.AutoSize = $true
$ConnectionGroup.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink

$InitialIPTB = New-Object System.Windows.Forms.TextBox
$InitialIPTB.AcceptsReturn = $false
$InitialIPTB.Text = $InitialIP
$InitialIPTB.AcceptsTab = $false
$InitialIPTB.Multiline = $False
$InitialIPTB.Location = New-Object System.Drawing.Point(110, 20)
$InitialIPLBL = New-Object System.Windows.Forms.Label
$InitialIPLBL.Text = "Initial IP Address:"
$InitialIPLBL.Location = New-Object System.Drawing.Point(5, 22)

$ModularUNTB = New-Object System.Windows.Forms.TextBox
$ModularUNTB.AcceptsReturn = $false
$ModularUNTB.Text = $ModularUN
$ModularUNTB.AcceptsTab = $false
$ModularUNTB.Multiline = $False
$ModularUNTB.Location = New-Object System.Drawing.Point(110, 50)
$ModularUNLBL = New-Object System.Windows.Forms.Label
$ModularUNLBL.Text = "Linux Username:"
$ModularUNLBL.Location = New-Object System.Drawing.Point(5, 53)

$NetworkGroup = New-Object System.Windows.Forms.GroupBox
$NetworkGroup.Text = "New Network Settings"
$NetworkGroup.Location = New-Object System.Drawing.Point(15,105)
$NetworkGroup.AutoSize = $true
$NetworkGroup.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink

$TargetIPTB = New-Object System.Windows.Forms.TextBox
$TargetIPTB.AcceptsReturn = $false
$TargetIPTB.Text = $NetworkFirstTwoOctets
$TargetIPTB.AcceptsTab = $false
$TargetIPTB.Multiline = $False
$TargetIPTB.Location = New-Object System.Drawing.Point(110, 20)
$TargetIPLBL = New-Object System.Windows.Forms.Label
$TargetIPLBL.Text = "Target IP Address:"
$TargetIPLBL.Location = New-Object System.Drawing.Point(5, 22)

$MaskTB = New-Object System.Windows.Forms.TextBox
$MaskTB.AcceptsReturn = $false
$MaskTB.Text = $PTXTargetMask
$MaskTB.AcceptsTab = $false
$MaskTB.Multiline = $False
$MaskTB.Location = New-Object System.Drawing.Point(245, 20)
$MaskLBL = New-Object System.Windows.Forms.Label
$MaskLBL.Text = "Mask:"
$MaskLBL.Location = New-Object System.Drawing.Point(212, 22)

$HostnameTB = New-Object System.Windows.Forms.TextBox
$HostnameTB.AcceptsReturn = $false
$HostnameTB.AcceptsTab = $false
$HostnameTB.Multiline = $False
$HostnameTB.Location = New-Object System.Drawing.Point(70, 50)
$HostnameLBL = New-Object System.Windows.Forms.Label
$HostnameLBL.Text = "Hostname: "
$HostnameLBL.Location = New-Object System.Drawing.Point(5, 53)

$GatewayTB = New-Object System.Windows.Forms.TextBox
$GatewayTB.AcceptsReturn = $false
$GatewayTB.Text = $Gateway
$GatewayTB.AcceptsTab = $false
$GatewayTB.Multiline = $False
$GatewayTB.Location = New-Object System.Drawing.Point(245, 50)
$GatewayLBL = New-Object System.Windows.Forms.Label
$GatewayLBL.Text = "Gateway:"
$GatewayLBL.Location = New-Object System.Drawing.Point(195, 53)

$MTUTB = New-Object System.Windows.Forms.TextBox
$MTUTB.AcceptsReturn = $false
$MTUTB.Text = $MTU
$MTUTB.AcceptsTab = $false
$MTUTB.Multiline = $False
$MTUTB.Location = New-Object System.Drawing.Point(70, 80)
$MTULBL = New-Object System.Windows.Forms.Label
$MTULBL.Text = "MTU: "
$MTULBL.Location = New-Object System.Drawing.Point(5, 83)

$TimeGroup = New-Object System.Windows.Forms.GroupBox
$TimeGroup.Text = "Time Settings"
$TimeGroup.Location = New-Object System.Drawing.Point(15,235)
$TimeGroup.AutoSize = $true
$TimeGroup.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink

$TimeZoneTB = New-Object System.Windows.Forms.TextBox
$TimeZoneTB.AcceptsReturn = $false
$TimeZoneTB.Text = $TimeZone
$TimeZoneTB.AcceptsTab = $false
$TimeZoneTB.Multiline = $False
$TimeZoneTB.Location = New-Object System.Drawing.Point(70, 20)
$TimeZoneLBL = New-Object System.Windows.Forms.Label
$TimeZoneLBL.Text = "Timezone:"
$TimeZoneLBL.Location = New-Object System.Drawing.Point(5, 22)

$NTPServerTB = New-Object System.Windows.Forms.TextBox
$NTPServerTB.AcceptsReturn = $false
$NTPServerTB.Text = $NTPServer
$NTPServerTB.AcceptsTab = $false
$NTPServerTB.Multiline = $False
$NTPServerTB.Location = New-Object System.Drawing.Point(245, 20)
$NTPServerLBL = New-Object System.Windows.Forms.Label
$NTPServerLBL.Text = "NTP Server:"
$NTPServerLBL.Location = New-Object System.Drawing.Point(178, 22)

$SyncToPCCB = New-Object System.Windows.Forms.CheckBox
$SyncToPCCB.Text = "Sync Time With"
$SyncToPCCB.Checked = $true
$SyncToPCCB.Location = New-Object System.Drawing.Point(10, 50)
$SyncToPCCB2 = New-Object System.Windows.Forms.Label
$SyncToPCCB2.Text = "PC Clock."
$SyncToPCCB2.Location = New-Object System.Drawing.Point(107, 55)


$PLinkTB = New-Object System.Windows.Forms.TextBox
$PLinkTB.AcceptsReturn = $false
$PLinkTB.Text = $PLinkPath
$PLinkTB.AcceptsTab = $false
$PLinkTB.Multiline = $False
$PLinkTB.Location = New-Object System.Drawing.Point(260, 332)
$PLinkLBL = New-Object System.Windows.Forms.Label
$PLinkLBL.Text = "Plink Path:"
$PLinkLBL.Location = New-Object System.Drawing.Point(190, 335)

$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Program"
$submitButton.Location = New-Object System.Drawing.Point(15, 332)

$SYSTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"


$submitButton.Add_Click({
    $TimeZone = $TimeZoneTB.Text
    $PTXTagetIP = $TargetIPTB.Text
    $PTXTargetMask = $MaskTB.Text
    $Gateway = $GatewayTB.Text
    $MTU = $MTUTB.Text
    $NTPServer = $NTPServerTB.Text
    $PTXhostname = $HostnameTB.Text
    if ($ModularUNTB.Text -eq "root"){
        write-host -foregroundcolor Yellow "Using Root User."
        $sudoPrefix = ""
    }
    Add-Content -Path "commands.sh" -Value "$sudoPrefix nmcli general hostname $PTXhostname"
    if ($PTX7RB.Checked) {
        Add-Content -Path "commands.sh" -Value "$sudoPrefix ptxapp -z $TimeZone"
        Add-Content -Path "commands.sh" -Value "$sudoPrefix nmcli connection modify eth0 ipv4.addresses $PTXTagetIP$PTXTargetMask"
        Add-Content -Path "commands.sh" -Value "$sudoPrefix nmcli connection modify eth0 ipv4.gateway $Gateway"
        Add-Content -Path "commands.sh" -Value "$sudoPrefix nmcli connection modify eth0 802-3-ethernet.mtu $MTU"
        Add-Content -Path "commands.sh" -Value "> /media/realroot/home/mms/.config/ntp/ntp.conf"
        Add-Content -Path "commands.sh" -Value "echo `"driftfile /var/lib/ntp/drift`" >> /media/realroot/home/mms/.config/ntp/ntp.conf"
        Add-Content -Path "commands.sh" -Value "echo `"server $NTPServer`" >> /media/realroot/home/mms/.config/ntp/ntp.conf"
        Add-Content -Path "commands.sh" -Value "echo `"restrict default nomodify nopeer noquery notrap`" >> /media/realroot/home/mms/.config/ntp/ntp.conf"
        if ($SyncToPCCB.Checked) {
            Add-Content -Path "commands.sh" -Value "$sudoPrefix timedatectl set-ntp false"
            Add-Content -Path "commands.sh" -Value "$sudoPrefix timedatectl set-time `"$SYSTime`""
            Add-Content -Path "commands.sh" -Value "$sudoPrefix timedatectl set-ntp true"
        }
        Add-Content -Path "commands.sh" -Value "$sudoPrefix hwclock -w"
        Add-Content -Path "commands.sh" -Value "$sudoPrefix sync_config.sh"
        
    } elseif ($PTXCRB.Checked) {
        Add-Content -Path "commands.sh" -Value "$sudoPrefix ptxapp -Z $TimeZone"
        Add-Content -Path "commands.sh" -Value "$sudoPrefix nmcli connection modify eth0 ipv4.addresses $PTXTagetIP$PTXTargetMask"
        Add-Content -Path "commands.sh" -Value "$sudoPrefix nmcli connection modify eth0 ipv4.gateway $Gateway"
        Add-Content -Path "commands.sh" -Value "$sudoPrefix nmcli connection modify eth0 802-3-ethernet.mtu $MTU"
        Add-Content -Path "commands.sh" -Value "> /media/realroot/home/mms/.config/ntp/ntp.conf"
        Add-Content -Path "commands.sh" -Value "echo `"driftfile /var/lib/ntp/drift`" >> /media/realroot/home/mms/.config/ntp/ntp.conf"
        Add-Content -Path "commands.sh" -Value "echo `"server $NTPServer`" >> /media/realroot/home/mms/.config/ntp/ntp.conf"
        Add-Content -Path "commands.sh" -Value "echo `"restrict default nomodify nopeer noquery notrap`" >> /media/realroot/home/mms/.config/ntp/ntp.conf"
        if ($SyncToPCCB.Checked) {
            Add-Content -Path "commands.sh" -Value "$sudoPrefix timedatectl set-ntp false"
            Add-Content -Path "commands.sh" -Value "$sudoPrefix timedatectl set-time `"$SYSTime`""
            Add-Content -Path "commands.sh" -Value "$sudoPrefix timedatectl set-ntp true"
        }
        Add-Content -Path "commands.sh" -Value "$sudoPrefix hwclock -w"
        Add-Content -Path "commands.sh" -Value "$sudoPrefix sync_etc"
       
    }
    [void]$form.Hide()
})

$PTXVerGroup.Controls.Add($PTX7RB)
$PTXVerGroup.Controls.Add($PTXCRB)
$ConnectionGroup.Controls.Add($InitialIPTB)
$ConnectionGroup.Controls.Add($InitialIPLBL)
$ConnectionGroup.Controls.Add($ModularUNLBL)
$ConnectionGroup.Controls.Add($ModularUNTB)
$NetworkGroup.Controls.Add($TargetIPTB)
$NetworkGroup.Controls.Add($TargetIPLBL)
$NetworkGroup.Controls.Add($MaskTB)
$NetworkGroup.Controls.Add($MaskLBL)
$NetworkGroup.Controls.Add($HostnameTB)
$NetworkGroup.Controls.Add($HostnameLBL)
$NetworkGroup.Controls.Add($GatewayTB)
$NetworkGroup.Controls.Add($GatewayLBL)
$NetworkGroup.Controls.Add($MTUTB)
$NetworkGroup.Controls.Add($MTULBL)
$TimeGroup.Controls.Add($TimeZoneTB)
$TimeGroup.Controls.Add($TimeZoneLBL)
$TimeGroup.Controls.Add($NTPServerTB)
$TimeGroup.Controls.Add($NTPServerLBL)
$TimeGroup.Controls.Add($SyncToPCCB2)
$TimeGroup.Controls.Add($SyncToPCCB)
$form.Controls.Add($PTXVerGroup)
$form.Controls.Add($ConnectionGroup)
$form.Controls.Add($NetworkGroup)
$form.Controls.Add($TimeGroup)
$form.Controls.Add($submitButton)
$form.Controls.Add($PLinkTB)
$form.Controls.Add($PLinkLBL)

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
$PLinkPath = $PLinkTB.Text
$ModularUN = $ModularUNTB.Text
$InitialIP = $InitialIPTB.Text
Show-Console
write-host -foregroundcolor Yellow "INFO: Initiating Connection to PTX Screen. You may be prompted to accept Fingerprint Certificate."
Add-Content -Path "commands.sh" -Value "$sudoPrefix reboot"
$command = "$PLinkPath -ssh -l $ModularUN -m commands.sh $InitialIP"
Invoke-Expression $command
write-host -foregroundcolor Yellow "INFO: Configuration Attempted. Please review SSH Output Above."
pause