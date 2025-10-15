# Wrapper to bulk configure Westermo Switch VLANs
# Built by Jake Dixon
#
# requires plink.exe from the putty application
# 
# ChangeLog:
#    14/10/2025
#     

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
#Hide-Console

# Default Variables
$VLID           = 115
$VLName         = "Modular"
$Tagged         = @(10)
$Untagged       = @(8)
$TaggedARR      = New-Object System.Collections.ArrayList
$UntaggedARR    = New-Object System.Collections.ArrayList
$Username       = "admin"
$PLinkPath      = "./plink.exe"
$StartAddress   = ""
$EndAddress     = ""

if (Test-path "commands.sh") {
    Remove-Item "commands.sh" -Force
}

Clear-Host
write-host -foregroundcolor Cyan "Westermo Bulk VLAN Utility"
write-host -foregroundcolor Cyan "Written By: Jake Dixon"
Write-Host ""

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.Text = "Westermo Bulk VLAN Import Utility"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Size = New-Object System.Drawing.Size(415, 305)

$form.Add_FormClosed({
    write-host -foregroundcolor Red "ERROR: Operating Aborted."
    [System.Windows.Forms.Application]::Exit()
    Stop-Process -Id $PID
})

$ConnectionGroup = New-Object System.Windows.Forms.GroupBox
$ConnectionGroup.Text = "Switch Connection Details"
$ConnectionGroup.Location = New-Object System.Drawing.Point(15,5)
$ConnectionGroup.AutoSize = $true
$ConnectionGroup.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
$ConnectionGroup.MaximumSize = New-Object System.Drawing.Size(220, 100)

$IPRangeStartTB = New-Object System.Windows.Forms.TextBox
$IPRangeStartTB.AcceptsReturn = $false
$IPRangeStartTB.Text = $StartAddress
$IPRangeStartTB.AcceptsTab = $false
$IPRangeStartTB.Multiline = $False
$IPRangeStartTB.Location = New-Object System.Drawing.Point(110, 20)
$IPRangeStartLBL = New-Object System.Windows.Forms.Label
$IPRangeStartLBL.Text = "IP Range Start:"
$IPRangeStartLBL.Location = New-Object System.Drawing.Point(5, 22)

$IPRangeEndTB = New-Object System.Windows.Forms.TextBox
$IPRangeEndTB.AcceptsReturn = $false
$IPRangeEndTB.Text = $EndAddress
$IPRangeEndTB.AcceptsTab = $false
$IPRangeEndTB.Multiline = $False
$IPRangeEndTB.Location = New-Object System.Drawing.Point(110, 45)
$IPRangeEndLBL = New-Object System.Windows.Forms.Label
$IPRangeEndLBL.Text = "IP Range End:"
$IPRangeEndLBL.Location = New-Object System.Drawing.Point(5, 48)

$UsernameTB = New-Object System.Windows.Forms.TextBox
$UsernameTB.AcceptsReturn = $false
$UsernameTB.Text = $Username
$UsernameTB.AcceptsTab = $false
$UsernameTB.Multiline = $False
$UsernameTB.Location = New-Object System.Drawing.Point(110, 70)
$UsernameLBL = New-Object System.Windows.Forms.Label
$UsernameLBL.Text = "Username:"
$UsernameLBL.Location = New-Object System.Drawing.Point(5, 73)

$VLInfoGroup = New-Object System.Windows.Forms.GroupBox
$VLInfoGroup.Text = "VLAN Information"
$VLInfoGroup.Location = New-Object System.Drawing.Point(235,5)
$VLInfoGroup.AutoSize = $true
$VLInfoGroup.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
$VLInfoGroup.MinimumSize = New-Object System.Drawing.Size(155, 100)

$VLNameTB = New-Object System.Windows.Forms.TextBox
$VLNameTB.AcceptsReturn = $false
$VLNameTB.Text = $VLName
$VLNameTB.AcceptsTab = $false
$VLNameTB.Multiline = $False
$VLNameTB.Location = New-Object System.Drawing.Point(43, 20)
$VLNameLBL = New-Object System.Windows.Forms.Label
$VLNameLBL.Text = "Name:"
$VLNameLBL.Location = New-Object System.Drawing.Point(5, 22)

$VLIDTB = New-Object System.Windows.Forms.TextBox
$VLIDTB.AcceptsReturn = $false
$VLIDTB.Text = $VLID
$VLIDTB.AcceptsTab = $false
$VLIDTB.Multiline = $False
$VLIDTB.Location = New-Object System.Drawing.Point(43, 45)
$VLIDLBL = New-Object System.Windows.Forms.Label
$VLIDLBL.Text = "ID:"
$VLIDLBL.Location = New-Object System.Drawing.Point(5, 48)

$TaggedGroup = New-Object System.Windows.Forms.GroupBox
$TaggedGroup.Text = "Tagged Ports"
$TaggedGroup.Location = New-Object System.Drawing.Point(15,105)
$TaggedGroup.AutoSize = $true
$TaggedGroup.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
$TaggedGroup.MinimumSize = New-Object System.Drawing.Size(370, 25)

$UntaggedGroup = New-Object System.Windows.Forms.GroupBox
$UntaggedGroup.Text = "Untagged Ports"
$UntaggedGroup.Location = New-Object System.Drawing.Point(15,165)
$UntaggedGroup.AutoSize = $true
$UntaggedGroup.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
$UntaggedGroup.MinimumSize = New-Object System.Drawing.Size(370, 25)

$TCB = @{}
$UCB = @{}

$xPos = 8
foreach ($num in 0..9) {
    $i = $num
    $keyTCB = "TCB$i"
    $keyUCB = "UCB$i"

    
    $UCB[$keyUCB] = New-Object System.Windows.Forms.CheckBox
    $UCB[$keyUCB].Text = ($i + 1).ToString()
    $UCB[$keyUCB].Location = New-Object System.Drawing.Point($xPos, 20)
    $UCB[$keyUCB].MaximumSize = New-Object System.Drawing.Size(36,20)
    if ($Untagged -contains $i+1) {
         $UCB[$keyUCB].Checked = $true
    }
    

    $TCB[$keyTCB] = New-Object System.Windows.Forms.CheckBox
    $TCB[$keyTCB].Text = ($i + 1).ToString()
    $TCB[$keyTCB].Location = New-Object System.Drawing.Point($xPos, 20) 
    $TCB[$keyTCB].MaximumSize = New-Object System.Drawing.Size(36,20)
    if ($Tagged -contains $i+1) {
        $TCB[$keyTCB].Checked = $true
    }
   

    $TCB[$keyTCB].Add_CheckedChanged({
        if ($TCB[$keyTCB].Checked) {
            $UCB[$keyUCB].Checked = $false
        }
    })
    $UCB[$keyUCB].Add_CheckedChanged({
        if ($UCB[$keyUCB].Checked) {
            $TCB[$keyTCB].Checked = $false
        }
    })

    $TaggedGroup.Controls.Add($TCB[$keyTCB])
    #$TaggedARR.Add($TaggedCB) | Out-Null
    $UntaggedGroup.Controls.Add($UCB[$keyUCB])
    #$UntaggedARR.Add($UntaggedCB) | Out-Null
    $xPos = $xPos + 36
}

$PLinkTB = New-Object System.Windows.Forms.TextBox
$PLinkTB.AcceptsReturn = $false
$PLinkTB.Text = $PLinkPath
$PLinkTB.AcceptsTab = $false
$PLinkTB.Multiline = $False
$PLinkTB.Location = New-Object System.Drawing.Point(290, 235)
$PLinkLBL = New-Object System.Windows.Forms.Label
$PLinkLBL.Text = "Plink Path:"
$PLinkLBL.Location = New-Object System.Drawing.Point(220, 238)

$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Batch Add"
$submitButton.Location = New-Object System.Drawing.Point(15, 235)

$SYSTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"


$submitButton.Add_Click({
    $TimeZone = $TimeZoneTB.Text
    $PTXTagetIP = $TargetIPTB.Text
    $PTXTargetMask = $MaskTB.Text
    $Gateway = $GatewayTB.Text
    $MTU = $MTUTB.Text
    $NTPServer = $NTPServerTB.Text
    $PTXhostname = $HostnameTB.Text
    if ($IPRangeEndTB.Text -eq "root"){
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

$VLInfoGroup.Controls.Add($VLNameTB)
$VLInfoGroup.Controls.Add($VLNameLBL)
$VLInfoGroup.Controls.Add($VLIDTB)
$VLInfoGroup.Controls.Add($VLIDLBL)
$ConnectionGroup.Controls.Add($IPRangeStartTB)
$ConnectionGroup.Controls.Add($IPRangeStartLBL)
$ConnectionGroup.Controls.Add($IPRangeEndLBL)
$ConnectionGroup.Controls.Add($IPRangeEndTB)
$ConnectionGroup.Controls.Add($UsernameLBL)
$ConnectionGroup.Controls.Add($UsernameTB)

$form.Controls.Add($VLInfoGroup)
$form.Controls.Add($ConnectionGroup)
$form.Controls.Add($TaggedGroup)
$form.Controls.Add($UntaggedGroup)

$form.Controls.Add($submitButton)
$form.Controls.Add($PLinkTB)
$form.Controls.Add($PLinkLBL)

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
$PLinkPath = $PLinkTB.Text
$ModularUN = $IPRangeEndTB.Text
$InitialIP = $IPRangeStartTB.Text
Show-Console
write-host -foregroundcolor Yellow "INFO: Initiating Connection to PTX Screen. You may be prompted to accept Fingerprint Certificate."
Add-Content -Path "commands.sh" -Value "$sudoPrefix reboot"
$command = "$PLinkPath -ssh -l $ModularUN -m commands.sh $InitialIP"
Invoke-Expression $command
write-host -foregroundcolor Yellow "INFO: Configuration Attempted. Please review SSH Output Above."
pause