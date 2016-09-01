#
# Cookbook Name:: Task3
# Recipe:: default
#
# Copyright (c) 2016 Dmytro

#
# First, disable selinux as the community code for MySQL requires

include_recipe 'selinux::disabled'

#
# Second, using community code to install MySQL
# The code below is NOT cross-platform due to necessity to install
# specific RPM.

comm_rpm = "#{Chef::Config['file_cache_path']}\
mysql57-community-release-el6-8.noarch.rpm"

cookbook_file comm_rpm do
  source 'mysql57-community-release-el6-8.noarch.rpm'
  mode '0711'
  not_if 'yum list | grep mysql57-community-release'
end

execute 'mysql community rpm installation' do
  command "rpm -ivh #{comm_rpm}"
  not_if 'yum list | grep mysql57-community-release'
end

file comm_rpm do
  action :delete
  only_if { File.exist?(comm_rpm) }
end

mysql_pwd = 'devops'

# For future, hashed with SHA-512:
# 2e04c978070fb9756cde6a684aebd608c330ab6734aac6e6f52c642191
# 32cc383e0d00dd31bc6a696c7a14fd69e2c83a8800bb54148b6769de19f9bb1098806d

mysql_port = '3306' # it's used few times later

mysql_service 't3' do
  bind_address '0.0.0.0'
  port mysql_port
  version '5.7'
  initial_root_password mysql_pwd
  action [:create, :start]
end

#
# Since that moment, we need to address correct MySQL socket.
# The code below is NOT cross-platform.

mysql_socket = '-S /var/run/mysql-t3/mysqld.sock'
mysql_cmd = "mysql #{mysql_socket} -p#{mysql_pwd}"

#
# We do not need to deletes obvious DB and users
# because they are not created by community code.

#
# Create MySQL users
# (via data_bags)

db_users = data_bag('db_users')
db_users.each do |dbu|
  db_user = data_bag_item('db_users', dbu)
  db_username = db_user['username']
  db_full_username = "'#{db_username}'@'localhost'"
  mysql_arg = "create user #{db_full_username} identified by '#{db_username}'"
  execute "mysql_useradd #{db_username}" do
    command "#{mysql_cmd} -e \"#{mysql_arg}\""
    not_if "#{mysql_cmd} -e \"select user from mysql.user\" |\
    grep #{db_username}"
  end
end

#
# Create databases

db_dbs = data_bag('db_dbs')
db_dbs.each do |dbi|
  db = data_bag_item('db_dbs', dbi)
  db_name = db['dbname']
  mysql_arg = "create database #{db_name}"
  execute "mysql_dbadd #{db_name}" do
    command "#{mysql_cmd} -e \"#{mysql_arg}\""
    not_if "#{mysql_cmd} -e \"show databases\" | grep #{db_name}"
  end
end

#
# Now, some games with schema in cookbook_file

devops_sql = "#{Chef::Config['file_cache_path']}/devops.sql"

cookbook_file devops_sql do
  action :create
  source 'devops.sql'
  not_if "#{mysql_cmd} -e \"show databases\" | grep devops"
end

execute 'create_db_from_file' do
  command "#{mysql_cmd} < #{devops_sql}"
  not_if "#{mysql_cmd} -e \"show databases\" | grep devops"
end

file devops_sql do
  action :delete
  only_if { File.exist?(devops_sql) }
end

#
# Directory for backups
# We'll create a user for it as well.
# An alternative is to use mysql user that *is* created by
# mysql community code.

user 'backup' do
  action :create
  home '/home/backup'	# formal, won't be used
  shell '/sbin/nologin'
  password '$1$nkcLJNGX$lsux6kr9wJ4XJabcyoj3t/'	# "devops"
end

backup_dir = '/opt/backups'

directory backup_dir do
  owner 'backup'
  group 'backup'
  mode '0755'
  action :create
end

#
# Place crontab file to /etc/cron.d

dump_cmd = "/usr/bin/mysqldump #{mysql_socket} -p#{mysql_pwd}"

template '/etc/cron.d/mysql_backup' do
  source 'mysql_backup.erb'
  cookbook 'Task3' # bypassing foodcritic bug #449
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    dump_cmd: dump_cmd,
    backup_dir: backup_dir
  )
end

#
# Add rules for mysql to iptables
#
# I use -A. Theoretically, I should check whether everything is blocked
# by some earlier rule, like "-A -p tcp -j DROP". But this would require
# writing complex recognition code, and altering such strict policies
# silently is bad practice.

#
# Provide correct prefix for iptables config file if it is missed.

execute 'iptables prefix' do
  command 'echo "*filter" > /etc/sysconfig/iptables'
  not_if 'grep *filter /etc/sysconfig/iptables'
end

#
# Remove COMMIT from iptables config file

execute 'remove commit step 1' do
  command "grep -v COMMIT /etc/sysconfig/iptables > \
#{Chef::Config['file_cache_path']}/iptables"
  not_if "/sbin/iptables --list -n | grep dpt:#{mysql_port} | grep ACCEPT"
end

execute 'remove commit step 2' do
  command "cp #{Chef::Config['file_cache_path']}/iptables \
/etc/sysconfig/iptables"
  only_if { ::File.exist?("#{Chef::Config['file_cache_path']}/iptables") }
end

file "#{Chef::Config['file_cache_path']}/iptables" do
  action :delete
end

#
# Add and permanently store INPUT rules

execute 'allow mysql in iptables INPUT' do
  command "/sbin/iptables -A INPUT -p tcp --dport #{mysql_port} -j ACCEPT"
  not_if "/sbin/iptables --list -n | grep dpt:#{mysql_port} | grep ACCEPT"
end

execute 'store iptables INPUT changes' do
  command "echo \"-A INPUT -p tcp --dport #{mysql_port} -j ACCEPT\" \
>> /etc/sysconfig/iptables"
  not_if "grep \"dport #{mysql_port}\" /etc/sysconfig/iptables | grep ACCEPT"
end

#
# Add and permanently store OUTPUT rules

execute 'allow mysql in iptables OUTPUT' do
  command "/sbin/iptables -A OUTPUT -p tcp --sport #{mysql_port} -j ACCEPT"
  not_if "/sbin/iptables --list -n | grep spt:#{mysql_port} | grep ACCEPT"
end

execute 'store iptables OUTPUT changes' do
  command "echo \"-A OUTPUT -p tcp --sport #{mysql_port} -j ACCEPT\" \
>> /etc/sysconfig/iptables"
  not_if "grep \"sport #{mysql_port}\" /etc/sysconfig/iptables | grep ACCEPT"
end

#
# Add COMMIT footer

execute 'iptables commit footer' do
  command 'echo "COMMIT" >> /etc/sysconfig/iptables'
  not_if 'grep COMMIT /etc/sysconfig/iptables'
end
