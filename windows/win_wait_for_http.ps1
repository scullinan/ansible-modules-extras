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
Set-Attr $result "condition" $false;

$url = Get-Attr -obj $params -name url -failifempty $true -emptyattributefailmessage "missing required argument: url"
$status_code = Get-Attr -obj $params -name status_code -default 200
$search_regex = Get-Attr -obj $params -name search_regex -default $null
$timeout = Get-Attr -obj $params -name timeout -default 10
$delay = Get-Attr -obj $params -name delay -default 0

$default_request_timeout_ms = 10000

function Evaluate_Response()
{
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [AllowNull()]
        [Microsoft.PowerShell.Commands.WebResponseObject]$response,
        [Parameter(Mandatory=$false,Position=1)]
        [int]$status_code=200,
        [Parameter(Mandatory=$false,Position=2)]
        [string]$search_regex=$null
    )

    if($response -eq $null){
        return $false
    }

    $ok = $false

    if($status_code -eq $response.StatusCode) { $ok = $true }
    
    if(($search_regex -ne $null) -or ($search_regex -ne "")){
        if($response.RawContent -match $search_regex) { $ok = $true }
    }

    return $ok
}

Try
{
    if($delay -gt 0){
        sleep -Seconds $delay
    }

    $timeout_ms = $timeout * 1000

    $sw = [system.diagnostics.stopwatch]::startNew()

    while($sw.get_ElapsedMilliseconds() -lt $timeout_ms){

        $to_ms = (($timeout_ms - $sw.get_ElapsedMilliseconds()), $default_request_timeout_ms  | Measure -Min).Minimum
        [Microsoft.PowerShell.Commands.WebResponseObject]$response=$null;
        try{
            $response = Invoke-WebRequest -Method Get -Uri $url -TimeoutSec ($to_ms/1000) -UseBasicParsing

            if(Evaluate_Response -response $response -status_code $status_code -search_regex $search_regex){
                $result.condition = $true
                Exit-Json $result
            }
        }
        catch{
            if(Evaluate_Response -response $response -status_code $status_code -search_regex $search_regex){
                $result.condition = $true
                Exit-Json $result
            }
        }
    }

    $sw.Stop()

    Exit-Json $result

}
Catch
{
    Fail-Json $result $_.Exception.Message
}
