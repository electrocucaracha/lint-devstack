#shellcheck shell=bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2022
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

Describe 'setup.sh'
    Include setup.sh

    Mock _append_config_line
        echo "$1"
    End

    Describe '_enable_service()'

        It 'adds a Horizon service to the local.config Devstack file'
            When call _enable_service 'horizon'
            The status should be success
            The output should equal "enable_service horizon"
        End
    End

    Describe '_enable_services()'
        Parameters
            'ceilometer' 'enable_service ceilometer-api'
            'cloudkitty' 'enable_service ck-api ck-proc'
            'sahara'     ''
        End
        It 'adds a service to the local.config Devstack file'
            When call _enable_services "$1"
            The status should be success
            The output should equal "$2"
        End
    End

    Describe '_enable_plugin()'
        Parameters
            'barbican' "enable_plugin barbican $GIT_REPO_HOST/barbican.git"
            'invalid'  ''
        End
        It 'adds a Barbican plugin to the local.config Devstack file'
            When call _enable_plugin "$1"
            The status should be success
            The output should equal "$2"
        End
    End
End
