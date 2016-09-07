#
# Cookbook Name:: Task3
# Recipe:: default
#
# Copyright (c) 2016 Dmytro

#
# Pre-tasks: install some dependencies

include_recipe 'build-essential::default'

#
# First, disable selinux as the community code for MySQL requires

include_recipe 'selinux::disabled'

#
# Second, install MySQL prerequisites

include_recipe 'yum_mysql_community'

mysql_root_bag = search(:db_users, 'id:root').first
mysql_pwd = mysql_root_bag['password']

mysql_port = node['Task3']['mysql']['port']

mysql_service 't3' do
  bind_address '0.0.0.0'
  port mysql_port
  version node['Task3']['mysql']['version']
  # Because 5.7 is not available in mysql_community_* packages yet,
  # and just '5.6' conflicts with current mysql_community_devel.
  initial_root_password mysql_pwd
  action [:create, :start]
end

#
# As we need to use mysqldump binary in the future, we have to address
# correct MySQL socket.

mysql_socket = "-S /var/run/#{node['Task3']['mysql']['instance_name']}\
/mysqld.sock"

#
# We need to install specific version of mysql_community_devel.

package 'mysql-community-devel' do
  version node['Task3']['mysql']['version'] + '.el6'
  action :install
end

mysql2_chef_gem 'default' do
  action :install
end

#
# Create connection info as an external ruby hash

mysql_connection_info = {
  host:      '127.0.0.1',
  username:  'root',
  password:   mysql_pwd
}

#
# Create mysql users

db_users = node['Task3']['mysql']['db_users']
db_users.each do |db_user|
  mysql_database_user db_user do
    connection mysql_connection_info
    password   'devops'
    action     :create
  end
end

#
# Drop test DB if exists
# (it should not exist with current version of mysql community code,
# but ensuring anyway.

mysql_database 'test' do
  connection mysql_connection_info
  action :drop
end

#
# Create databases

db_dbs = node['Task3']['mysql']['db_dbs']
db_dbs.each do |db_name|
  mysql_database db_name do
    connection mysql_connection_info
    action :create
  end
end

#
# Directory for backups
# We'll create a user for it as well.
# An alternative is to use mysql user that *is* created by
# mysql community code.

backup_bag = search(:db_users, 'id:backup').first
backup_pwd = backup_bag['password']
backup_hashed = backup_bag['hashed']

user 'backup' do
  action :create
  home '/home/backup'	# formal, won't be used
  shell '/bin/bash'
  password backup_hashed
end

mysql_database_user 'backup' do
  connection mysql_connection_info
  password   backup_pwd
  action     :create
end

backup_dir = '/opt/backups'

directory backup_dir do
  owner 'backup'
  group 'backup'
  mode '0755'
  action :create
end

#
# Create cron.d entries

dump_cmd = "/usr/bin/mysqldump #{mysql_socket} -p#{backup_pwd}"

#
# Unfortunately, cron_d resource does not support multiple commands
# per single file under /etc/cron.d, so creating 2 files.

db_dbs.each do |db_name|
  cron_name = 'mysql_backup_' + db_name
  cron_d cron_name do
    minute  '*/5'
    command "#{dump_cmd} #{db_name} > #{backup_dir}/#{db_name}.sql"
    user 'backup'
  end
end
