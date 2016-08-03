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

$store_location = Get-Attr -obj $params -name store_location -failifempty $true -emptyattributefailmessage "missing required argument: store_location"
$thumbprint  = Get-Attr -obj $params -name thumbprint -failifempty $true -emptyattributefailmessage "missing required argument: thumbprint"
$src = Get-Attr -obj $params -name src -default $null
$password = Get-Attr -obj $params -name password -deafult $true 
$private_key = Get-Attr -obj $params -name private_key -default "false" | ConvertTo-Bool
$state = Get-Attr -obj $params -name state -default "present" -ValidateSet "present","absent"

function Import-Cert()
{
    if(Is-Installed){
        return
    }

    if($src -eq $null -or $src -eq ""){
        throw "'src' argument is required when importing a certificate"
    }
    if($private_key -and ($password -eq $null -or $password -eq "")){
        throw "'password' argument is required when importing a private key (pfx)"
    }    
              
    $certificate = ( Get-ChildItem -Path $src )
   
    if($private_key){
        $securepassword = ConvertTo-SecureString -String $password -Force -AsPlainText	
        $res = $certificate | Import-PfxCertificate -CertStoreLocation $store_location -Password $securepassword
        $result.changed = $true
    }
    else {
        $res = $certificate | Import-Certificate -CertStoreLocation $store_location 
        $result.changed = $true
    }
    $result = new-object psobject @{
        changed = $result.changed
        thumb_print = $res.Thumbprint
        serial_number = $res.SerialNumber
        subject = $res.Subject
    }        
}

function Is-Installed()
{
    $item = Get-ChildItem -Path $store_location | where {$_.Thumbprint -eq $thumbprint } 
    return ($item -ne $null)
}

function Remove-Cert()
{
    if(-not (Is-Installed)){
        return
    }
    
    [string]$path = $store_location 
    if(-not $path.EndsWith('\')){ $path += '\' }
    $path += $thumbprint

    if($private_key){        
        Remove-Item -Path $path -DeleteKey -Confirm:$false -Force
    }
    else{
        Remove-Item -Path $path -Confirm:$false -Force
    }
    $result.changed = $true
}

Try
{   

    if ($state -eq "present"){
        Import-Cert
    }
    else{
        Remove-Cert        
    }

    Exit-Json $result;
}
Catch
{
    Fail-Json $result $_.Exception.Message
}
