# Task3

Progress:

* sets up mysql, and creates DB users and schemas **- DONE**

* configures regular database dumps ( using cron ) into some folder. **- DONE**

* configures iptables to enable access to mysql. **- DONE**

* sets up apache and provides HTTP access to mysql dumps folder. **- DONE**

* configures iptables to enable access to httpd. **- DONE**

* Cookstyle syntax check and foodcritic with 0 errors. **- DONE**

* rspec unit tests **- ToDo**

* jsonlint check on databag files. **- ToDo**

* Use sample ( by your choise ) schema file(or files) for schemas, keep schema files as cookbook files. **- DONE**

* Use Chef-vault to store encrypted passwords. **- ToDo**

* Try to achieve state when your consequent chef-client runs results in 0 resources updates.  **- DONE**

* Make sure cookbook will work if applied to 3-rd party machine with enabled iptables and selinux.  **- ToDo**