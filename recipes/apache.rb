#
# First, install apache from the community code

include_recipe 'apache2'

# Place VirtualHost description to apache conf dir.

web_app 'mysql-backup' do
  server_name 'Task3'
  server_alias 'mysql-backup'
  docroot '/opt/backups/'
  directory_options 'Indexes'
end
