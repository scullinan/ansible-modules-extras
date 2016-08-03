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
short_description: "Waits for a condition on an HTTP request before continuing"
description:
 - Invokes web requests and waits for the given status_code and/or search_regex condition to evaluate to true on the response or untill the timeout period expires.

version_added: "2.1"
author: "Stuart Cullinan (stuart.cullinan@gmail.com)"
options:
    url:
        description:
          - the url to invoke
        required: true        
    status_code:
        description:
          - wait for this status code condition
        required: false
        default: 200
    search_regex:
        description:
          - wait for this regular expression condition applied to the raw content returned.
        required: false
        default: None  
    timeout:
        description:
          - maximum number of seconds to wait for a response to return before closing and retrying
        required: false
        default: 10 
    delay:
        description:
          - number of seconds to wait before starting to poll
        required: false
        default: 0
"""

EXAMPLES = '''
  - name: Wait for home page to load with welcome message 
    win_wait_for_http:
      url: http://10.0.0.10:81/home
      timeout: 30
      search_regex: 'Welcome'  

  - name: Wait for 200 status code 
    win_wait_for_http:
      url: http://10.0.0.10:81/health
      timeout: 30
      status_code: 200
'''