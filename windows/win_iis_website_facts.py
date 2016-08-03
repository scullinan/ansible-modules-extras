#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2014, Trond Hindenes <trond@hindenes.com>
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
module: win_iis_website_facts
version_added: "0.1"
short_description: Gathers facts about IIS websites
description:
    - Gathers information about existing IIS websites
options:

author: "Stuart Cullinan (@scullinan)"
'''

EXAMPLES = '''
# This return information about an existing websites on the host
$ ansible -i vagrant-inventory -m win_iis_website_facts windows
host | success >> {
  "changed": false,
  "ansible_facts": {
    "websites": {
      "Default Web Site": {           
        "Bindings": [
          "*:80:"
        ],
        "ID": 1,
        "Name": "Default Web Site",
        "PhysicalPath": "%SystemDrive%\\inetpub\\wwwroot",
        "State": "Stopped"
      }
    }
  }
} 

# Playbook example
---

- name: Gather facts about websites
  win_iis_website_facts:
'''