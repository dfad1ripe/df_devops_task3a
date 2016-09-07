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

mysql_pwd = 'devops'

# For future, hashed with SHA-512:
# 2e04c978070fb9756cde6a684aebd608c330ab6734aac6e6f52c642191
# 32cc383e0d00dd31bc6a696c7a14fd69e2c83a8800bb54148b6769de19f9bb1098806d

mysql_port = '3306' # it's used few times later

mysql_service 't3' do
  bind_address '0.0.0.0'
  port mysql_port
  version '5.6.29-2'
  # Because 5.7 is not available in mysql_community_* packages yet,
  # and just '5.6' conflicts with current mysql_community_devel.
  initial_root_password mysql_pwd
  action [:create, :start]
end

#
# As we need to use mysqldump binary in the future, we have to address
# correct MySQL socket.

mysql_socket = '-S /var/run/mysql-t3/mysqld.sock'

#
# We need to install specific version of mysql_community_devel.

package 'mysql-community-devel' do
  version '5.6.29-2.el6'
  # allow_downgrade true
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

db_users = data_bag('db_users')
db_users.each do |dbu|
  db_user = data_bag_item('db_users', dbu)
  db_username = db_user['username']
  mysql_database_user db_username do
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

db_dbs = data_bag('db_dbs')
db_dbs.each do |dbi|
  db = data_bag_item('db_dbs', dbi)
  db_name = db['dbname']
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
# Create cron.d entry

dump_cmd = "/usr/bin/mysqldump #{mysql_socket} -p#{mysql_pwd}"

#
# Unfortunately, cron_d resource does not support multiple commands
# per single file under /etc/cron.d, so creating 2 files.

cron_d 'mysql_backup_stage' do
  minute  '*/5'
  command "#{dump_cmd} stage_db > #{backup_dir}/stage_db.sql"
  user 'root'
end

cron_d 'mysql_backup_prod' do
  minute  '*/5'
  command "#{dump_cmd} prod_db > #{backup_dir}/prod_db.sql"
  user 'root'
end
