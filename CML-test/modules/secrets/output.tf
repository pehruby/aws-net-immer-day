#
# This file is part of Cisco Modeling Labs
# Copyright (c) 2019-2024, Cisco Systems, Inc.
# All rights reserved.
#

output "secrets" {
  value = (
    module.dummy.secrets
  )
  sensitive = true
}