#!powershell

# Copyright 2016, Stuart Cullinan <stuart.cullinan@gmail.com>

# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.


# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;
$result = New-Object PSObject;
Set-Attr $result "changed" $false;

$package = Get-Attr -obj $params -name name -failifempty $true -emptyattributefailmessage "missing required argument: name"
$output_directory = Get-Attr -obj $params -name location -failifempty $true -emptyattributefailmessage "missing required argument: location"
$exclude_version = Get-Attr -obj $params -name exclude_version -default "false" | ConvertTo-Bool
$prerelease = Get-Attr -obj $params -name prerelease -default "false" | ConvertTo-Bool
$nocache = Get-Attr -obj $params -name nocache -default "false" | ConvertTo-Bool
$force = Get-Attr -obj $params -name force -default "false" | ConvertTo-Bool
$version = Get-Attr -obj $params -name version -default $null

$source = Get-Attr -obj $params -name source -default $null
if ($source) {$source = $source.Tolower()}

$state = Get-Attr -obj $params -name state -default "present"


if ("present","absent" -notcontains $state)
{
    Fail-Json $result "state is $state; must be present or absent"
}

Function Check-NugetIsInstalled
{
    [CmdletBinding()]

    param()

    $installed = get-command nuget -ErrorAction 0
    if ($installed -eq $null)
    {
        Fail-Json $result "nuget is not installed or not in PATH. Install 'Nuget.Commandline' using win_chocolatey module first"
    }
    else
    {
        $script:nuget = "nuget.exe"       
    }
}

function Get-LatestPackageVersion([string]$packageId, [string]$source)
{
    #get the latest version from list command
    $cmd = "$nuget list '$packageId'"

    if(($source -ne $null) -and ($source -ne "")){ $cmd += " -Source $source" }

    $results = invoke-expression $cmd

    if (($LastExitCode -ne 0) -or ($results.Contains('No packages found')))
    {
        Set-Attr $result "nuget_error_cmd" $cmd
        Set-Attr $result "nuget_error_log" "$results"
    
        Throw "Error checking installation status for $package" 
    } 

    $pkg = $results.Split([System.Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries) `
                             | %{ $kv = $_.Split(' '); return @{ Name=$kv[0]; Version=$kv[1] } } `
                             | where { $_.Name -eq $packageId } `
                             | Select -index 0 
                             
    return $pkg.Version 
}

Function Install-Package
{
    [CmdletBinding()]
    
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$package,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$output_directory,
        [Parameter(Mandatory=$false, Position=3)]
        [string]$version,
        [Parameter(Mandatory=$false, Position=4)]
        [string]$source,
        [Parameter(Mandatory=$false, Position=5)]
        [bool]$exclude_version,
        [Parameter(Mandatory=$false, Position=6)]
        [bool]$prerelease,                
        [Parameter(Mandatory=$false, Position=7)]
        [bool]$nocache,
        [Parameter(Mandatory=$false, Position=7)]
        [bool]$force = $false
    ) 

    Add-Facts
    
    if(-not $force)
    {
        if($result.IsInstalled()){ return }
    }    

    $cmd = "$nuget install $package"

    if (-not $version)
    {
        $version = $result.package_version        
    }
    $cmd += " -Version $version"
        
    if ($source)
    {
        $cmd += " -Source $source"
    }

    if ($exclude_version)
    {
        $cmd += " -ExcludeVersion"
    }

    if ($output_directory)
    {
        $cmd += " -OutputDirectory '$output_directory'"
    }

    if ($prerelease)
    {
        $cmd += " -Prerelease"
    }

    if ($nocache)
    {
        $cmd += " -NoCache"
    }

    $cmd += " -NonInteractive"

    $results = invoke-expression $cmd

    if ($LastExitCode -ne 0)
    {
        Set-Attr $result "nuget_error_cmd" $cmd
        Set-Attr $result "nuget_error_log" "$results"
        Throw "Error installing $package" 
    }
    
    $result | Add-Member -MemberType NoteProperty -Name "command" -Value $cmd
            
    $result.changed = $true
}

function Add-Facts()
{
    if(-not $version)
    {
        $version = Get-LatestPackageVersion $package $source
    }
            
    if($exclude_version)
    {
        $dir = (Join-Path $output_directory $package)
    }
    else
    {
        $pdir = "{0}.{1}" -f $package, $version
        $dir = (Join-Path $output_directory $pdir)
    }
          
    $result | Add-Member -MemberType NoteProperty -Name "package_path" -Value $dir
    $result | Add-Member -MemberType NoteProperty -Name "package_id" -Value $package
    $result | Add-Member -MemberType NoteProperty -Name "package_version" -Value $version
    $result | Add-Member -MemberType ScriptMethod -Name "IsInstalled" -Value { return Test-Path $this.package_path }    
    
}

Function Uninstall-Package 
{
    [CmdletBinding()]
    
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$package,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$output_directory,
        [Parameter(Mandatory=$false, Position=3)]
        [string]$version = $null,
        [Parameter(Mandatory=$false, Position=4)]
        [bool]$exclude_version = $false
    )
    
    Add-Facts

    if (-not ($result.IsInstalled()))
    {
        return
    }   

    Remove-Item -Recurse -Force $result.package_path
      
    $result.changed = $true
}

Try
{
    Check-NugetIsInstalled

    if ($state -eq "present")
    {
        Install-Package -package $package -output_directory $output_directory -version $version `
            -source $source -exclude_version $exclude_version -prerelease $prerelease -nocache $nocache -force $force
    }
    else
    {
        Uninstall-Package -package $package -output_directory $output_directory -version $version -exclude_version $exclude_version
    }

    Exit-Json $result;
}
Catch
{
    Fail-Json $result $_.Exception.Message
}
