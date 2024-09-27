

resource "aws_networkfirewall_rule_group" "http_alert" {
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
          protocol         = "HTTP"
          source           = "ANY"
          source_port      = "ANY"
        }
        # Snort rule identification
        rule_option {
          keyword  = "sid"
          settings = ["2"]
        }
      }
    }
    
  }
  tags = {
    Name = "AnfwDemo-HttpAlert-RuleGroup"
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
    stateful_default_actions = ["aws:alert_established"]
    stateful_rule_group_reference {
      priority     = 100
      resource_arn = aws_networkfirewall_rule_group.http_alert.arn
    }
  }

  tags = {
    Name = "AnfwDemo-InspectionFirewall-Policy-Strict"
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
