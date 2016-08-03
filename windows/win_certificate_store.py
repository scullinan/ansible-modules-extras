#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2016, Stuart Cullinan <stuart.cullinan@gmail.com>
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

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

DOCUMENTATION = '''
---
module: win_certificate_store
version_added: "2.1"
short_description: Imports and removes certificates from the local certificate store
description:
    - Imports and removes certificates from the local certificate store.
options:
  store_location:
    description:
      - The certificate store location path where the certificate will be installed or that identifies the certificate to be removed.
    required: true
  thumbprint:
    description:
      - The certificate thumbprint. This will uniquely identify the certificate to import/remove and is required to make this module idempotent.
    required: true
  src:
    description:
      - Specify the folder location where the certificate file to be imported exists. Required if state is 'present'
    require: false     
  private_key:
    description:
      - When state is 'present' will imprt the file specified by src as a Pfx. If state is 'absent' will remove the private key along with the certificate specified.
    require: false
    choices:
      - yes
      - no
    default: no  
  password:
    description:
      - The password to import the Pfx. Required if state is 'present' and private_key is 'yes'
    require: false    
  state:
    description:
      - State of the package on the system
    required: false
    choices:
      - present
      - absent
    default: present
  	
author: "Stuart Cullinan (stuart.cullinan@gmail.com)"
'''

EXAMPLES = '''
  # Install certificate to my localmachine
  win_certificate_store: 
    store_location: 'cert:\\localMachine\\my' 
    thumprint: D2D38EBA60CAA1C12055A2E1C83B15AD450110C2
    src: 'c:\\certs\mycertificate.cer'

  # Install private key Pfx to localmachine trustedpeople
  win_certificate_store: 
    store_location: 'cert:\\localMachine\\trustedpeople' 
    thumprint: D2D38EBA60CAA1C12055A2E1C83B15AD450110C2
    src: 'c:\\certs\mycertificate.pfx'
    private_key: yes
    password: 'secret'

  # Remove certificate from my localmachine
  win_certificate_store: 
    store_location: 'cert:\\localMachine\\my' 
    thumprint: D2D38EBA60CAA1C12055A2E1C83B15AD450110C2
    state: absent

  # Remove certificate and private key 
  win_certificate_store: 
    store_location: 'cert:\\localMachine\\my'
    thumprint: D2D38EBA60CAA1C12055A2E1C83B15AD450110C2 
    private_key: yes
    state: absent

'''