
resource "aws_networkfirewall_rule_group" "icmp_alert" {
  capacity = 100
  name     = "AnfwDemo-IcmpAlert-RuleGroup"
  type     = "STATEFUL"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      stateful_rule {
        action = "ALERT"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "ICMP"
          source           = "ANY"
          source_port      = "ANY"
        }
        # Snort rule identification
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }
  }
  tags = {
    Name = "AnfwDemo-IcmpAlert-RuleGroup"
  }
}

resource "aws_networkfirewall_rule_group" "domain" {
  capacity = 100
  name     = "AnfwDemo-DomainAllow-RuleGroup"
  type     = "STATEFUL"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [ "10.0.0.0/8" ]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [".amazon.com", ".amazonaws.com",]
        # targets              = [".amazon.com", ".amazonaws.com",".google.com"]
      }
    }
  }

  tags = {
    Name = "AnfwDemo-DomainAllow-RuleGroup"
  }
}


resource "aws_networkfirewall_rule_group" "suricata_ua" {
  capacity = 300
  name     = "AnfwDemo-Emerging-User-Agents-Rules-RuleGroup"
  description = "Emerging user agents rules rule group"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [ "10.0.0.0/8" ]
        }
      }
    }
    rules_source {
      rules_string = file("emerging-user-agents.rules")
    }
  }

  tags = {
    Name = "AnfwDemo-Emerging-User-Agents-Rules-RuleGroup"
  }
}


resource "aws_networkfirewall_rule_group" "suricata_action_order" {
  capacity = 10
  name     = "AnfwDemo-Custom-Suricata-ActionOrder-RuleGroup"
  description = "Surricata Rule with Default Ordering to allow HTTP traffic to specific domains only, allow all SSH traffic, and deny all other TCP traffic"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [ "10.0.0.0/8" ]
        }
      }
    }
    rules_source {
      rules_string = file("suricata-action-order.rules")
    }
  }

  tags = {
    Name = "AnfwDemo-Custom-Suricata-ActionOrder-RuleGroup"
  }
}

resource "aws_networkfirewall_rule_group" "suricata_strict_order" {
  capacity = 10
  name     = "AnfwDemo-Custom-Suricata-StrictOrder-RuleGroup"
  description = "Surricata Rule with Strict Ordering to allow HTTP traffic to specific domains only, allow all SSH traffic, and deny all other TCP traffic"
  type     = "STATEFUL"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [ "10.0.0.0/8" ]
        }
      }
    }
    rules_source {
      rules_string = file("suricata-strict-order.rules")
    }
  }

  tags = {
    Name = "AnfwDemo-Custom-Suricata-StrictOrder-RuleGroup"
  }
}

resource "aws_networkfirewall_firewall_policy" "demo_strict" {
  name = "AnfwDemo-InspectionFirewall-Policy-Strict"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateful_default_actions = ["aws:drop_established", "aws:alert_established"]
    stateful_rule_group_reference {
      priority     = 100
      resource_arn = aws_networkfirewall_rule_group.icmp_alert.arn
    }
    stateful_rule_group_reference {
      priority     = 200
      resource_arn = aws_networkfirewall_rule_group.domain.arn
    }
    stateful_rule_group_reference {
      priority     = 300
      resource_arn = aws_networkfirewall_rule_group.suricata_strict_order.arn
    }
  }

  tags = {
    Name = "AnfwDemo-InspectionFirewall-Policy-Strict"
  }
}

resource "aws_networkfirewall_firewall_policy" "demo_action" {
  name = "AnfwDemo-InspectionFirewall-Policy-Action"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_engine_options {
      rule_order = "DEFAULT_ACTION_ORDER"
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.suricata_action_order.arn
    }
  }

  tags = {
    Name = "AnfwDemo-InspectionFirewall-Policy-Action"
  }
}

resource "aws_networkfirewall_firewall" "central" {
  name                = "AnfwDemo-InspectionFirewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.demo_strict.arn
  vpc_id              = aws_vpc.VPC_C.id
  subnet_mapping {
    subnet_id = aws_subnet.VPC_C_fw_a.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.VPC_C_fw_b.id
  }


  tags = {
    Name = "AnfwDemo-InspectionFirewall"
  }
}

resource "aws_cloudwatch_log_group" "alert" {
  name = "/AnfwDemo/Anfw/Alert"
    
}

resource "aws_cloudwatch_log_group" "flow" {
  name = "/AnfwDemo/Anfw/Flow"
  
}


resource "aws_networkfirewall_logging_configuration" "fw_centr_log" {
  firewall_arn = aws_networkfirewall_firewall.central.arn
  logging_configuration {
    log_destination_config { 
      log_type = "FLOW"
      log_destination_type = "CloudWatchLogs"
      log_destination = {
            logGroup = aws_cloudwatch_log_group.flow.name
      } 
    } 
    log_destination_config {
      log_type = "ALERT"
      log_destination_type = "CloudWatchLogs"
      log_destination = {
            logGroup = aws_cloudwatch_log_group.alert.name
      }    
    }
  }
}




