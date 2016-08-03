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
module: win_nuget
version_added: "2.2"
short_description: Installs packages using nuget
description:
    - Installs packages using Nuget (https://www.nuget.org/). If Nuget is missing from the system, this module will NOT install it. To install
      nuget, use the win_chocolatey module and install 'Nuget.Commandline' first.
options:
  name:
    description:
      - Name (packageId) of the package to be installed
    required: true
  output_directory:
    description:
      - Specify the folder location to install the package
    require: true
  state:
    description:
      - State of the package on the system
    required: false
    choices:
      - present
      - absent
    default: present
  force:
    description:
      - Forces install of the package (even if it already exists). Using Force will cause ansible to always report that a change was made
    required: false
    choices:
      - yes
      - no
    default: no
  version:
    description:
      - Specific version of the package to be installed
      - Ignored when state == 'absent'
    required: false
    default: null
  source:
    description:
      - Specify source rather than using default nuget.org gallery
    require: false
    default: null   
  exclude_version:
    description:
      - Exlcude the version in the name of the installation folder. If a package is installed with this option set then it must be uninstalled with this option set too.
    require: false
    choices:
      - yes
      - no
    default: no
  prerelease:
    description:
      - Allows prerelease packages to be installed.
    choices:
      - yes
      - no
    default: no
  nocache:
    description:
      - Disable looking up packages from local machine cache.
    choices:
      - yes
      - no
    default: no
author: "Stuart Cullinan (stuart.cullinan@gmail.com)"
'''

EXAMPLES = '''
  # Install EntityFramework
  win_nuget:
    name: EntityFramework
    location: c:/lib
  # Install EntityFramework 6.1.2
  win_nuget:
    name: EntityFramework
    version: 6.1.2
    location: c:/lib
  # Uninstall EntityFramework
  win_nuget:
    name: EntityFramework
    state: absent
    location: c:/lib
  # Install EntityFramework from specified repository
  win_nuget:
    name: EntityFramework
    location: c:/lib
    source: https://someserver/api/v2/
'''

RETURN = '''
state:
  description: The package installation details after successful install.
  returned: only on successful installation
  type: dict
  sample: {
      "changed": true,
      "package_path": "c:/packages/somepackage-1.2.3",
      "package_id": "somepackage",
      "package_version": "1.2.3"
    }
'''