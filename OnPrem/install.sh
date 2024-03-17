#!/bin/bash
# set up DNS server
dnf install -y bind

# replace named.conf
cat > /etc/named.conf<< EOF
options {
  directory       "/var/named";
  dump-file       "/var/named/data/cache_dump.db";
  statistics-file "/var/named/data/named_stats.txt";
  memstatistics-file "/var/named/data/named_mem_stats.txt";
  recursing-file  "/var/named/data/named.recursing";
  secroots-file   "/var/named/data/named.secroots";

  recursion yes;

  allow-query { any; };

  dnssec-enable no;
  dnssec-validation no;

  bindkeys-file "/etc/named.root.key";

  managed-keys-directory "/var/named/dynamic";

  pid-file "/run/named/named.pid";
  session-keyfile "/run/named/session.key";

  forwarders {
          169.254.169.253;
  };
  forward first;
};

logging {
  channel default_debug {
      file "data/named.run";
      severity dynamic;
  };
};


zone "." IN {
        type hint;
        file "named.ca";
};

zone "example.corp" IN {
        type master;
        file "/etc/named/example.corp";
        allow-update { none; };
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

# build zone file with my IP address and AppServer IP.
ORIGIN='$ORIGIN'
APPIP='${aws_instance.VPC_OP_app_server.private_ip}'
MYIP='172.16.1.200'

cat > /etc/named/example.corp<< EOF
$ORIGIN example.corp.
@                      3600 SOA   ns.example.corp. (
                                  zone-admin.example.com.     ; address of responsible party
                                  2020050701                 ; serial number
                                  3600                       ; refresh period                                    
                                  600                        ; retry period
                                  604800                     ; expire time
                                  1800                     ) ; minimum ttl
                      86400 NS    ns1.example.corp.
myapp                    60 IN A  $APPIP
ns1                      60 IN A  $MYIP
EOF

# activate DNS server
systemctl enable named.service
systemctl start named.service

# set up as local DNS resolver
cat > /etc/resolv.conf<< EOF
search example.corp
nameserver ${aws_instance.VPC_OP_app_server.private_ip}
EOF
