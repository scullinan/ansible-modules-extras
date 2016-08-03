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

# Result
$result = New-Object psobject @{  
    changed = $false
    ansible_facts = New-Object psobject @{
        services = New-Object psobject @{}
        checks = New-Object psobject @{}
    }
};

$module = New-Object psobject -Property @{   
    host = Get-Attr -obj $params -name host -default "localhost"
    port = Get-Attr -obj $params -name port -default "8500"
    scheme = Get-Attr -obj $params -name scheme -default "http"
    validate_certs = Get-Attr -obj $params -name validate_certs -default "true" | ConvertTo-Bool        
    token = Get-Attr -obj $params -name token -default $null
}

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

function Get-ConsulApi()
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]$module
    )

    if(-not $module.validate_certs){        
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }

    $consul_api = New-Object psobject -Property @{
        agent = New-Object psobject -Property @{
            service=New-Object psobject @{}
        }               
        host=$module.host
        port=$module.port
        scheme=$module.scheme
        validate_certs=$module.validate_certs
        token=$module.token
    }

    $consul_api | Add-Member ScriptMethod tokenise_url {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$uri            
        )

        if($this.token -ne $null){ 
            $uri += "?token="+$this.token 
        }
        return $uri
    }

    $consul_api.agent | Add-Member ScriptMethod services {
        $uri = "{0}://{1}:{2}/v1/agent/services" `
                -f $consul_api.scheme, $consul_api.host, $consul_api.port

        $uri = $consul_api.tokenise_url($uri)

        return Invoke-RestMethod -Method Get -Uri $uri         
    }    
    
    $consul_api.agent | Add-Member ScriptMethod checks {
        $uri = "{0}://{1}:{2}/v1/agent/checks" `
                -f $consul_api.scheme, $consul_api.host, $consul_api.port

        $uri = $consul_api.tokenise_url($uri)

        return Invoke-RestMethod -Method Get -Uri $uri
    }
    
    return $consul_api    
}

try
{
    $consul_api = Get-ConsulApi $module
    
    $result.ansible_facts.services = $consul_api.agent.services()
    $result.ansible_facts.checks = $consul_api.agent.checks()

    Exit-Json $result;
}
catch
{
    Fail-Json $result $_.Exception.Message
}