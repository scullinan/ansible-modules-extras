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
module: consul
short_description: "Gathers service and check facts from local consul agent"
description:
 - Gathers service and check details from the local consul agent as ansible facts.
 - "See http://consul.io for more details."

version_added: "2.1"
author: "Stuart Cullinan (stuart.cullinan@gmail.com)"
options:
    host:
        description:
          - host of the consul agent defaults to localhost
        required: false
        default: localhost
    port:
        description:
          - the port on which the consul agent is running
        required: false
        default: 8500
    scheme:
        description:
          - the protocol scheme on which the consul agent is running
        required: false
        default: http
    validate_certs:
        description:
          - whether to verify the tls certificate of the consul agent
        required: false
        default: True
    token:
        description:
          - the token key indentifying an ACL rule set. May be required to register services.
        required: false
        default: None
"""

EXAMPLES = '''
  - name: Gather all consul facts
    win_consul_facts:
     
'''