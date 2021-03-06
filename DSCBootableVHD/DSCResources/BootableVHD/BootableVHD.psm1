function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceISO,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $ImageNumber,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VHDFile,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Packages
    )


    $returnValue = @{
        SourceISO = $SourceISO
        ImageNumber = $ImageNumber
        VHDFile = $VHDFile
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceISO,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $ImageNumber,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VHDFile,

        [Parameter(Mandatory = $false)]
        [System.Array]
        $Packages
    )

    if ($Packages.Count -gt 0) {
        Convert-WindowsImage -SourcePath $SourceISO -VhdPath $VHDFile -DiskLayout UEFI -Edition $ImageNumber -Package $Packages
    }
    else {
        Convert-WindowsImage -SourcePath $SourceISO -VhdPath $VHDFile -DiskLayout UEFI -Edition $ImageNumber
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceISO,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $ImageNumber,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VHDFile,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Packages
    )

    try {
        $iso = Mount-DiskImage $SourceISO -PassThru
        $isopath = ($iso | Get-Volume).DriveLetter+":"
        Write-Verbose $isopath
        $vhd=Mount-VHD -Path $VHDFile -Passthru -ReadOnly -ErrorAction SilentlyContinue
        if($null -eq $vhd) {return $false}
        $vhdpath = ($vhd | Get-Disk | Get-Partition | Where-Object -FilterScript {($_.Type -ne 'Recovery') -and ($_.Type -ne 'System')} | Get-Volume).DriveLetter
        if($null -eq $vhdpath) {return $false}
        $vhdpath+=":"
        Write-Verbose $vhdpath
        $ISOVersion=(get-windowsimage -imagepath "$isopath\sources\install.wim" -Index $ImageNumber)
        Write-Verbose ($ISOVersion.Version)
        $DLLVersion = (get-command "$vhdpath\Windows\System32\kernel32.dll").Version
        Write-Verbose $DLLVersion
        return ($ISOVersion.MajorVersion -eq $DLLVersion.Major) -and ($ISOVersion.MinorVersion -eq $DLLVersion.Minor) -and ($ISOVersion.Build -eq $DLLVersion.Build)
    }
    catch{
        Write-Verbose "ERROR: $_"
        return $false
    }
    finally{
        if($null -ne $iso) {$iso | Dismount-DiskImage | Out-Null}
        if($null -ne $vhd) {$vhd | Dismount-VHD}
    }

}


Export-ModuleMember -Function *-TargetResource

