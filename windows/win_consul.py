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

DOCUMENTATION = """
---
module: consul
short_description: "Add, modify & delete services within a consul cluster."
description:
 - Registers services and checks for an agent with a consul cluster.
   A service is some process running on the agent node that should be advertised by
   consul's discovery mechanism. It may optionally supply a check definition,
   a periodic service test to notify the consul cluster of service's health.
 - "Checks may also be registered per node e.g. disk usage, or cpu usage and
   notify the health of the entire node to the cluster.
   Service level checks do not require a check name or id as these are derived
   by Consul from the Service name and id respectively by appending 'service:'
   Node level checks require a check_name and optionally a check_id."
 - Currently, there is no complete way to retrieve the script, interval or ttl
   metadata for a registered check. Without this metadata it is  not possible to
   tell if the data supplied with ansible represents a change to a check. As a
   result this does not attempt to determine changes and will always report a
   changed occurred. An api method is planned to supply this metadata so at that
   stage change management will be added.
 - "See http://consul.io for more details."

version_added: "2.2"
author: "Stuart Cullinan (stuart.cullinan@gmail.com)"
options:
    state:
        description:
          - register or deregister the consul service, defaults to present
        required: true
        choices: ['present', 'absent']
    service_name:
        description:
          - Unique name for the service on a node, must be unique per node,
            required if registering a service. May be ommitted if registering
            a node level check
        required: false
    service_id:
        description:
          - the ID for the service, must be unique per node, defaults to the
            service name if the service name is supplied
        required: false
        default: service_name if supplied
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
    notes:
        description:
          - Notes to attach to check when registering it.
        required: false
        default: None
    service_port:
        description:
          - the port on which the service is listening required for
            registration of a service, i.e. if service_name or service_id is set
        required: false
    service_address:
        description:
          - the address on which the service is serving required for
            registration of a service
        required: false
        default: localhost
    tags:
        description:
          - a list of tags that will be attached to the service registration.
        required: false
        default: None
    script:
        description:
          - the script/command that will be run periodically to check the health
            of the service. Scripts require an interval and vise versa
        required: false
        default: None
    interval:
        description:
          - the interval at which the service check will be run. This is a number
            with a s or m suffix to signify the units of seconds or minutes e.g
            15s or 1m. If no suffix is supplied, m will be used by default e.g.
            1 will be 1m. Required if the script param is specified.
        required: false
        default: None
    check_id:
        description:
          - an ID for the service check, defaults to the check name, ignored if
            part of a service definition.
        required: false
        default: None
    check_name:
        description:
          - a name for the service check, defaults to the check id. required if
            standalone, ignored if part of service definition.
        required: false
        default: None
    ttl:
        description:
          - checks can be registered with a ttl instead of a script and interval
            this means that the service will check in with the agent before the
            ttl expires. If it doesn't the check will be considered failed.
            Required if registering a check and the script an interval are missing
            Similar to the interval this is a number with a s or m suffix to
            signify the units of seconds or minutes e.g 15s or 1m. If no suffix
            is supplied, m will be used by default e.g. 1 will be 1m
        required: false
        default: None
    http:
        description:
          - checks can be registered with an http endpoint. This means that consul
            will check that the http endpoint returns a successful http status.
            Interval must also be provided with this option.
        required: false
        default: None 
    tcp:
        description:
          - checks can be registered with a tcp endpoint. An TCP check will perform an TCP connection attempt against the value of TCP (expected to be an IP/hostname and port combination) every Interval. If the connection attempt is successful, the check is passing. If the connection attempt is unsuccessful, the check is critical. In the case of a hostname that resolves to both IPv4 and IPv6 addresses, an attempt will be made to both addresses, and the first successful connection attempt will result in a successful check
        required: false
        default: None 
    timeout:
        description:
          - A custom HTTP check timeout. The consul default is 10 seconds.
            Similar to the interval this is a number with a s or m suffix to
            signify the units of seconds or minutes, e.g. 15s or 1m.
        required: false
        default: None        
    token:
        description:
          - the token key indentifying an ACL rule set. May be required to register services.
        required: false
        default: None
    status:
        description:
          - The Status field can be provided to specify the initial state of the health check. Valid values are "critical","passing".
        required: false
        default: critical
"""

EXAMPLES = '''
    - name: register foo service with the local consul agent
      win_consul:
        service_name: foo
        service_port: 80

    - name: register foo service with curl check
      win_consul:
        service_name: foo
        service_port: 80
        script: "curl http://localhost"
        interval: 60s

    - name: register foo with an http check
      win_consul:
        name: foo
        service_port: 80
        interval: 60s
        http: /status

    - name: register foo with address
      win_consul:
        service_name: foo
        service_port: 80
        service_address: 127.0.0.1

    - name: register foo with some service tags
      win_consul:
        service_name: foo
        service_port: 80
        tags:
          - prod
          - webservers

    - name: remove foo service
      win_consul:
        service_name: foo
        state: absent

    - name: create a node level check to test disk usage
      win_consul:
        check_name: Disk usage
        check_id: disk_usage
        script: "c:/temp/disk_usage.ps1"
        interval: 5m
'''

RETURN = '''
state:
  description: The service details after a successful service registration.
  returned: only on successful registration
  type: dict
  sample: {
      "changed": true,
      "service_id": "foo",
      "service_name": "foo",
      "service_port": 80,
      "checks": [],
      "tags": "webservers"
    }
state:
  description: The service details after a successful service removal (unregister).
  returned: only on successful service removal
  type: dict
  sample: {
      "changed": true,
      "id": "foo"
    }
state:
  description: The check details after a successful check registration.
  returned: only on successful check registration
  type: dict
  sample: {
      "changed": true,
      "check_id": "foo-health",
      "check_name": "foo-health",
      "script": null,
      "interval": 5,
      "ttl": null,
      "tcp": null,
      "http": "http://localhost:80/health",
      "timeout": 25,
    }
state:
  description: The check details after a successful check removal.
  returned: only on successful check removal
  type: dict
  sample: {
      "changed": true,
      "id": "foo-health"
    }
'''