#!powershell

# (c) 2015, Stuart Cullinan <stuart.cullinan@gmail.com>
#
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

# Ensure WebAdministration module is loaded
if ((Get-Module "WebAdministration" -ErrorAction SilentlyContinue) -eq $null) {
  Import-Module WebAdministration
}

# Result
$result = New-Object psobject @{  
  changed = $false
  ansible_facts = New-Object psobject @{
    websites = New-Object psobject @{}
  }
};

# Web Sites info
$sites =Get-Website | % {
  $site = New-Object psobject @{
      Name = $_.Name
      ID = $_.ID
      State = $_.State
      PhysicalPath = $_.PhysicalPath
      ApplicationPool = $_.applicationPool
      Bindings = @($_.Bindings.Collection | ForEach-Object { $_.BindingInformation })
    }
  $result.ansible_facts.websites.Add($site.name, $site)
}

Exit-Json $result