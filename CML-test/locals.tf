

locals {
  cfg_file = "config.yaml"
  raw_cfg  = yamldecode(file(var.cfg_file))
  cfg = merge(
    {
      for k, v in local.raw_cfg : k => v if k != "secret"
    },
    {
      secrets = module.secrets.secrets
    }
  )
  extras = var.cfg_extra_vars == null ? "" : (
    fileexists(var.cfg_extra_vars) ? file(var.cfg_extra_vars) : var.cfg_extra_vars
  )
  num_computes = local.cfg.cluster.enable_cluster ? local.cfg.cluster.number_of_compute_nodes : 0
  compute_hostnames = [
    for i in range(1, local.num_computes + 1) :
    format("%s-%d", local.cfg.cluster.compute_hostname_prefix, i)
  ]

  
  /*
  cml_config_compute = [for compute_hostname in local.compute_hostnames : templatefile("${path.module}/../data/virl2-base-config.yml", {
    hostname      = compute_hostname,
    is_controller = false,
    is_compute    = true,
    cfg = merge(
      local.cfg,
      # Need to have this as it's referenced in the template.
      # (Azure specific)
      { sas_token = "undefined" }
    ) }
    )
  ]
  cloud_config_compute = [for i in range(0, local.num_computes) : templatefile("${path.module}/../data/cloud-config.txt", {
    vars          = local.vars
    cml_config    = local.cml_config_compute[i]
    cfg           = local.cfg
    cml           = local.cml
    common        = local.common
    copyfile      = local.copyfile
    del           = local.del
    interface_fix = local.interface_fix
    extras        = local.extras
    hostname      = local.compute_hostnames[i]
    path          = path.module
  })]
  */
}
