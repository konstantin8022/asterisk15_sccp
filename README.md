# asterisk15_sccp

 1  yum install asterisk14-devel mc git htop
    2  cd /usr/src
    3  git clone https://github.com/chan-sccp/chan-sccp chan-sccp_master
    4  cd chan-sccp_master
    5  ./configure --enable-conference --enable-advanced-functions --enable-distributed-devicestate
    6  make && make install
    7  mysql -u root asterisk < ./conf/mysql-v5_enum.sql
    8  cp conf/sccp.conf.freepbx /etc/asterisk/sccp.conf
    9  cp conf/sccp_extensions.conf.freepbx /etc/asterisk/sccp_extensions.conf
   10  cp conf/sccp_hardware.conf.freepbx /etc/asterisk/sccp_hardware.conf
   11  chown asterisk:asterisk /etc/asterisk/sccp*
   12  vi  /etc/asterisk/modules.conf
   13  nano  /etc/asterisk/modules.conf
   14  service asterisk restart
   15  asterisk -r
   16  chown -R asterisk:asterisk /usr/lib64/asterisk/
   17  mysql -u root -p  asterisk < conf/mysql-v5_enum.sql
   18  fwconsole restart
   19  asterisk -rv
   20  useradd -d /tftpboot tftpd
   21  nano /etc/xinetd.d/tftp
   22  systemctl restart xinetd
   23  nano /etc/my.cnf.d/server.cnf
   24  nano /etc/my.cnf.d/client.cnf
   25  rpm -e --nodeps mysql-connector-odbc-5.2.5-7.el7.x86_64
   26  yum install mariadb-connector-odbc
   27  nano /etc/odbcinst.ini
   28  reboot
   29  ifconfig
   30  reboot
   31  asterisk -rv
   32  date
   33  ntpq -p
   34  nano /etc/ntp.conf
   35  ping  185.209.85.222
   36  nano /etc/ntp.conf
   37  service ntpd status
   38  service ntpd restart
   39  service ntpd status
   40  chkconfig ntpd on
   41  ntpq -p
   42  date
   43   ls /usr/share/zoneinfo/
   44  ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/locatime
   45  date
   46   ls /usr/share/zoneinfo/europe/
   47   ls /usr/share/zoneinfo/Europe/
   48  ls /etc/localtime
   49  date
   50  timedatectl
   51  ls -lh /etc/localtime
   52  tzselect
   53  date
   54  sudo tzselect
   55  date
   56  timedatectl set-timezone Europe/Moscow
   57  date
   58  reboot
   59  asterisk -rv
   60  reboot
   61  asterisk -rv
   62  reboot
   63  mkdir .ssh
   64  chmod 0600 .ssh
   65  vim .ssh/authorized_keys
   66  chmod 0700 .ssh/authorized_keys 
   67  exit
   68  reboot
   69  dmesg
   70  dmesg | grep -i failed
   71  htop
   72  dmesg
   73  fwconsole unlock 
   74  fwconsole unlock dmntbgbjcb0kq2f6o708l3qc63 
   75  asterisk -r
   76  service asterisk restart
