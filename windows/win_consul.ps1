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

$module = New-Object psobject -Property @{
    service_name = Get-Attr -obj $params -name service_name -default $null
    service_id = Get-Attr -obj $params -name service_id -default (Get-Attr -obj $params -name service_name)
    host = Get-Attr -obj $params -name host -default "localhost"
    port = Get-Attr -obj $params -name port -default "8500"
    scheme = Get-Attr -obj $params -name scheme -default "http"
    validate_certs = Get-Attr -obj $params -name validate_certs -default "true" | ConvertTo-Bool
    notes = Get-Attr -obj $params -name notes -default $null
    service_port = Get-Attr -obj $params -name service_port -default $null
    service_address = Get-Attr -obj $params -name service_address -default $null
    tags = Get-Attr -obj $params -name tags -default $null
    script = Get-Attr -obj $params -name script -default $null
    interval = Get-Attr -obj $params -name interval -default $null
    check_id = Get-Attr -obj $params -name check_id -default $null
    check_name = Get-Attr -obj $params -name check_name -default $null
    ttl = Get-Attr -obj $params -name ttl -default $null
    http = Get-Attr -obj $params -name http -default $null
    tcp = Get-Attr -obj $params -name tcp -default $null
    timeout = Get-Attr -obj $params -name timeout -default $null
    token = Get-Attr -obj $params -name token -default $null
    status = Get-Attr -obj $params -name status -default $null -ValidateSet "critical","passing"
    state = Get-Attr -obj $params -name state -default "present" -ValidateSet "present","absent"
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

function Add
{
    $check = Parse-Check $module
    $service = Parse-Service $module

    if(($null -eq $service) -and ($null -eq $check)){
        Fail-Json $result "a name and port are required to register a service"
    }
    if($null -ne $service){
        if($null -ne $check){
            $service.add_check($check)
        }    
        Add-Service $module $service
    }
    elseif ($null -ne $check){
        Add-Check $module $check
    }
}

function Remove
{    
    $service_id = ($module.service_id, $module.service_name -ne $null)[0]
    $check_id = ($module.check_id, $module.check_name -ne $null)[0]

    if(($null -eq $service_id) -and ($null -eq $check_id)){
        Fail-Json $result "services and checks are removed by id or name. please supply a service id/name or a check id/name"
    } 

    if($null -ne $service_id){
        Remove-Service -module $module -service_id $service_id
        Remove-Check -module $module -check_id $service_id
    }

    if($null -ne $check_id){
        Remove-Check -module $module -check_id $check_id
    }   
}

function Add-Service()
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]$module,
        [Parameter(Mandatory=$true,Position=1)]
        [object]$service
    )
    $res = $service
    $result.changed = $false  
    
    $consul_api = Get-ConsulApi $module

    $existing = Get-ServiceById $module $service.id

    if($service.has_checks() -or ($null -eq $existing) -or (-not $service.Equals($existing))){
        $consul_api.agent.check.de_register("service:"+$service.id) 
        $service.register($consul_api)        
        $result.changed = $true
        $res = Get-ServiceById -module $module -id $service.id             
        if($service.has_checks()){
            $res.checks = $service.checks 
        }        
    }

    Exit-Json @{
        changed=$result.changed
        service_id=$res.id
        service_name=$res.name
        service_port=$res.port
        checks=$res.checks | %{ return $_.check }
        tags=$res.tags
    }
}

function Remove-Service()
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]$module,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$service_id
    )          
    
    $consul_api = Get-ConsulApi $module
    $consul_api.agent.service.de_register($service_id)
    $result.changed = $true

    Exit-Json @{
        changed=$result.changed
        id=$service_id
    }
}

function Add-Check()
{    
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]$module,
        [Parameter(Mandatory=$true,Position=1)]
        [object]$check
    )   

    if($null -eq $check.name){
        Fail-Json $result "a check name is required for a node level check, one not attached to a service"
    }

    $consul_api = Get-ConsulApi $module
    $check.register($consul_api)
    $result.changed = $true

    Exit-Json @{
        changed=$result.changed
        check_id=$check.id
        check_name=$check.name
        script=$check.script
        interval=$check.interval
        ttl=$check.ttl
        tcp=$check.tcp
        http=$check.http
        timeout=$check.timeout
    }
}

function Remove-Check()
{
   param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]$module,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$check_id
    )   
    $consul_api = Get-ConsulApi $module    
    
    $consul_api.agent.check.de_register($check_id) 
    $result.changed = $true

    Exit-Json @{
        changed=$result.changed
        id=$check_id
    }
}

function Get-ServiceById()
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]$module,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$id
    )
    $api = Get-ConsulApi $module
    
    $services = $api.agent.services()
    $existing = $services.psobject.properties `
      | where { $_.Name -eq $id } `
      | %{ return $services.psobject.members[$_.Name].Value }
      
    if($null -ne $existing){
      return New-ConsulService -loaded $existing
    }

    return $null
}

function Parse-Check()
{ 
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]$module
    )

    if(($module.script, $module.ttl, $module.http, $module.tcp -ne $null).Length -gt 1){
        Fail-Json $result "checks are either script, http, tcp or ttl driven, supplying more than one does not make sense"
    }

    if(($null -eq $module.check_id) -and `
        ($null -eq $module.script) -and `
        ($null -eq $module.ttl) -and `
        ($null -eq $module.http) -and `
        ($null -eq $module.tcp)){
        return $null
    }

    return New-ConsulCheck -check_id $module.check_id `
                            -name $module.check_name `
                            -script $module.script `
                            -interval $module.interval `
                            -ttl $module.ttl `
                            -notes $module.notes `
                            -http $module.http `
                            -tcp $module.tcp `
                            -timeout $module.timeout `
                            -status $module.status 
}

function New-ConsulCheck()
{
    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string]$check_id,
        [Parameter(Mandatory=$false,Position=1)]
        [string]$name,
        [Parameter(Mandatory=$false,Position=2)]
        [string]$script=$null,
        [Parameter(Mandatory=$false,Position=3)]
        [string]$interval=$null,
        [Parameter(Mandatory=$false,Position=4)]
        [string]$ttl=$null,
        [Parameter(Mandatory=$false,Position=5)]
        [string]$notes=$null,
        [Parameter(Mandatory=$false,Position=6)]
        [string]$http=$null,
        [Parameter(Mandatory=$false,Position=7)]
        [string]$tcp=$null,
        [Parameter(Mandatory=$false,Position=8)]
        [string]$timeout=$null,
        [Parameter(Mandatory=$false,Position=9)]
        [string]$status=$null
    )

    $check = New-Object psobject -Property @{
        id=($check_id, $name -ne $null)[0]
        name=$name
        script=$script            
        notes=$notes
        http=$http
        tcp=$tcp 
        ttl=$null
        interval=$null
        timeout=$null
        check=$null  
        status=$status
    }

    $check | Add-Member ScriptMethod validate_duration {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$name,
            [Parameter(Mandatory=$true, Position=1)]
            [string]$duration
        )
        if(($null -eq $duration) -or ($duration -eq "")){
            return $null
        }           
        $duration_units = @('ns', 'us', 'ms', 's', 'm', 'h')
          
        $suffix_ok=$false
        $duration_units | %{
            if($duration.EndsWith($_)){ $suffix_ok=$true }
        }
        if(-not $suffix_ok){
            throw ('Invalid {0} {1} you must specify units ({2})' -f `
                $name, $duration, ($duration_units -join ', '))
        }        
        return $duration
    }

    if(($script, $http, $tcp -ne $null).Length -gt 0){
        $check.interval = $check.validate_duration("interval",$interval)
    }
    $check.timeout = $check.validate_duration("timeout",$timeout)
    $check.ttl = $check.validate_duration("ttl",$ttl)

    if(-not (null_or_empty $script)) { 
        $check.check = @{
            Script = $script
            Interval = $interval 
        }            
    }
    if(-not (null_or_empty $http)) {
        $check.check = @{ 
            HTTP = $http
            Interval = $interval             
        }
    }
    if(-not (null_or_empty $tcp)) { 
        $check.check = @{ 
            TCP = $tcp
            Interval = $interval             
        }
    }
    if(-not (null_or_empty $ttl)) { 
        $check.check = @{ 
            TTL = $ttl 
        }
    } 

    $check | Add-Member ScriptMethod register {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [object]$consul_api
        )

        $consul_api.agent.check.register($check.name, $check.id, $check.notes, `
                                        $check.script, $check.http, $check.tcp, `
                                        $check.ttl, $check.interval, $check.status)
    }        
    return $check  
}

function Parse-Service()
{  
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]$module,    
        [Parameter(Mandatory=$false, Position=1)]
        [object]$loaded=$null
    ) 
    
    if(($module.service_name -ne $null) -and ($module.service_port -ne $null)){
        return New-ConsulService $module.service_id $module.service_name $module.service_address $module.service_port $module.tags 
    }
    elseif(($module.service_name -ne $null) -and ($module.service_port -eq $null)) {
        Fail-Json $result ("service_name supplied but no service_port, a port is required to configure a service." + `
                          " Did you configure the 'port' argument meaning 'service_port'?")
    }
    return $null
}

function New-ConsulService()
{
    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string]$service_id=$null,
        [Parameter(Mandatory=$false,Position=1)]
        [string]$service_name=$null,  
        [Parameter(Mandatory=$false,Position=2)]
        [string]$service_address=$null,
        [Parameter(Mandatory=$false,Position=3)]
        [string]$service_port=$null,
        [Parameter(Mandatory=$false,Position=4)]
        [array]$tags=$null,        
        [Parameter(Mandatory=$false, Position=5)]
        [object]$loaded=$null
    )

    $service = New-Object psobject -Property @{            
        name=$service_name
        id=($service_id, $service_name -ne $null)[0]
        address=$service_address
        port=$service_port
        tags=($tags,@() -ne $null)[0]
        checks=@()
    }

    if($loaded -ne $loaded){
        $service.id = $loaded.ServiceID
        $service.name = $loaded.ServiceName
        $service.port = $loaded.ServicePort         
        $service.address = $loaded.ServiceAddress
        if($loaded.PSobject.Properties.name -match "ServiceTags"){
            $service.tags = $loaded.ServiceTags
        }
    }

    $service | Add-Member ScriptMethod register { 
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [object]$consul_api
        )
                     
        if($this.checks.Length -gt 0){
            $check = $this.checks[0]               

            $consul_api.agent.service.register($service.name, `
                                    $service.id, `
                                    $service.address, `
                                    $service.port, `
                                    $service.tags, `
                                    $check)             
        } 
        else {
            $consul_api.agent.service.register($service.name, `
                                    $service.id, `
                                    $service.address, `
                                    $service.port, `
                                    $service.tags)     

        }
    }

    $service | Add-Member ScriptMethod add_check {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [object]$check
        )
        $this.checks += $check
    }
	
    $service | Add-Member ScriptMethod has_checks {
        return ($this.checks.Length -gt 0) 
    }

    $service | Add-Member ScriptMethod Equals -Force {
        param(
            [Parameter(Mandatory=$true,Position=0)]
            [object]$obj
        )
        if($null -eq $obj){ return $false }
        return (($obj.GetType() -eq $this.GetType()) -and `
                ($this.id -eq $obj.id) -and `
                ($this.name -eq $obj.name) -and `
                ($this.port -eq $obj.port) -and `
                (@(Compare-Object $this.tags $obj.tags -SyncWindow 0).Length -eq 0))
    }
    return $service
}

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
            check=New-Object psobject @{}
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

    $consul_api.agent.service | Add-Member ScriptMethod register {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$name,
            [Parameter(Mandatory=$false, Position=1)]
            [string]$id,
            [Parameter(Mandatory=$false, Position=2)]
            [string]$address=$null,
            [Parameter(Mandatory=$false, Position=3)]
            [int]$port=$null,
            [Parameter(Mandatory=$false, Position=4)]
            [array]$tags=$null,
            [Parameter(Mandatory=$false, Position=5)]
            [object]$check=$null
        )
        $uri = "{0}://{1}:{2}/v1/agent/service/register" `
                -f $consul_api.scheme, $consul_api.host, $consul_api.port

        $uri = $consul_api.tokenise_url($uri)

        $body = @{ 
            Name=$name 
            ID = ($id, $name -ne $null)[0] 
        }
        if(-not (null_or_empty $address)) { $body.Address = $address }
        if(-not (null_or_empty $port)) { $body.Port = $port }
        if($null -ne $tags) { $body.Tags = $tags }
        if($null -ne $check) { $body.Check = $check }

        return Invoke-RestMethod -Method Put -Uri $uri `
                -Body ($body | ConvertTo-Json) -ContentType "application/json"                
    }

    $consul_api.agent.service | Add-Member ScriptMethod de_register {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$id
        )
        $uri = "{0}://{1}:{2}/v1/agent/service/deregister/{3}" `
                -f $consul_api.scheme, $consul_api.host, $consul_api.port, $id

        $uri = $consul_api.tokenise_url($uri)
        
        return Invoke-RestMethod -Method Put -Uri $uri              
    }

    $consul_api.agent | Add-Member ScriptMethod checks {
        $uri = "{0}://{1}:{2}/v1/agent/checks" `
                -f $consul_api.scheme, $consul_api.host, $consul_api.port

        $uri = $consul_api.tokenise_url($uri)

        return Invoke-RestMethod -Method Get -Uri $uri 
    }

    $consul_api.agent.check | Add-Member ScriptMethod register {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$name,
            [Parameter(Mandatory=$false, Position=1)]
            [string]$id=$null,
            [Parameter(Mandatory=$false, Position=2)]
            [string]$notes=$null,
            [Parameter(Mandatory=$false, Position=3)]
            [string]$script=$null,
            [Parameter(Mandatory=$false, Position=4)]
            [string]$http=$null,
            [Parameter(Mandatory=$false, Position=5)]
            [string]$tcp=$null,
            [Parameter(Mandatory=$false, Position=6)]
            [string]$ttl=$null,
            [Parameter(Mandatory=$false, Position=7)]
            [string]$interval=$null,
            [Parameter(Mandatory=$false, Position=8)]
            [string]$status=$null
        )
        $uri = "{0}://{1}:{2}/v1/agent/check/register" `
                -f $consul_api.scheme, $consul_api.host, $consul_api.port

        $uri = $consul_api.tokenise_url($uri)

        $body = @{            
            Name=$name
            ID=($id, $name -ne $null)[0]
        }        
        if(-not (null_or_empty $notes)) { 
            $body.Notes = $notes 
        }
        if(-not (null_or_empty $script)) { 
            $body.Script = $script
            $body.Interval = $interval
        }
        if(-not (null_or_empty $http)) {  
            $body.HTTP = $http
            $body.Interval = $interval           
        }
        if(-not (null_or_empty $tcp)) { 
            $body.TCP = $tcp
            $body.Interval = $interval                   
        }
        if(-not (null_or_empty $ttl)) { 
            $body.TTL = $ttl           
        } 
        if(-not (null_or_empty $status)) { 
            $body.Status = $status           
        } 
        
        return Invoke-RestMethod -Method Put -Uri $uri `
                -Body ($body | ConvertTo-Json) -ContentType "application/json"             
    }

    $consul_api.agent.check | Add-Member ScriptMethod de_register {
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$id
        )
        $uri = "{0}://{1}:{2}/v1/agent/check/deregister/{3}" `
                -f $consul_api.scheme, $consul_api.host, $consul_api.port, $id
        
        $uri = $consul_api.tokenise_url($uri)
        
        return Invoke-RestMethod -Method Put -Uri $uri          
    }

    return $consul_api    
}

function null_or_empty()
{
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$string
    )
    return (($string -eq $null) -or ($string -eq "") -or ($string -eq [String]::Empty))
}

try
{
    if ($module.state -eq "present"){
        Add
    }
    else {
        Remove
    }

    Exit-Json $result;
}
catch
{
    Fail-Json $result $_.Exception.Message
}