default['Task3']['mysql']['instance_suffix'] = 't3'
default['Task3']['mysql']['instance_name'] = 'mysql-' +
                                             node['Task3']\
                                             ['mysql']['instance_suffix']
default['Task3']['mysql']['port'] = 3306
default['Task3']['mysql']['version'] = '5.6.29-2'
default['Task3']['mysql']['db_users'] = %w(service_prod service_stage)
default['Task3']['mysql']['db_dbs'] = %w(prod_db stage_db)
