function Get-tssServerDetails {
    
    [CmdletBinding()]
    param (
        [string[]] $ComputerName
    )
    
    foreach ($computer in $ComputerName){
    
        $dns = Test-Connection $computer -count 1 | select Address,Ipv4Address
        $props = @{
                ComputerName = $dns.Address
                IPAddress = $dns.Ipv4Address
        }

        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer
        $props.Add("OperatingSystem", $os.Caption + ' ' + $os.OSArchitecture + ' (' + $os.Version + ' build ' + $os.BuildNumber + ')')

        $comp = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer
        $props.Add("SystemModel",$comp.Model)

        $cpu = Get-WmiObject -Class Win32_Processor -ComputerName $computer
        $cpuval = $cpu | Measure-Object -Property Name -Maximum | foreach {$_.Maximum +  ' (' + $_.Count  + ' CPUs)' }
        $props.Add("Processor",$cpuval)
        
        $mem = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $computer
        $props.Add("Memory",($mem | Measure-Object -Property capacity -Sum | Foreach {"{0:N2}" -f ([math]::round(($_.Sum / 1GB),2))}).ToString() + ' GB')

        $pf = Get-WmiObject -Class Win32_PageFileUsage -computername $computer
        $strpf = $pf.CurrentUsage.ToString() + " MB used, " + ($pf.AllocatedBaseSize - $pf.CurrentUsage).ToString() + " MB available"
        $props.Add("PageFile",$strpf)

        $hds = Get-WmiObject -Class Win32_Volume -ComputerName $computer -Filter "DriveType=3 and SystemVolume=false" | Sort-Object Name 
        $strhds = ''
        foreach ($hd in $hds){
            $Size=("{0:N2}" -f ($hd.capacity/1GB)).ToString() + ' GB '
            $Freespace="{0:N2}" -f ($hd.Freespace/1GB) + ' GB '
            $strhds = $strhds + "`n" + 'Drive: ' + $hd.Name + "`n" + 'Free Space: ' + $Freespace + "`n" + 'TotalSpace:' + $Size
        }
        $props.Add("Drives",$strhds)

        New-Object -TypeName PSObject -Property $props

    }

}