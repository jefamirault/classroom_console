# Classroom Console

Classroom Console is an administrative tool to help educational institutions better manage their digital learning environments. It organizes and syncs data between Canvas Learning Management System (LMS) by Instructure, and the OnCampus LMS by Blackbaud, bundled with a broader suite of school management solutions.
## Development
Make sure you have Rails 6 installed. Then clone the repository and run bundler.
```
git clone https://github.com/jefamirault/classroom.git
cd classroom_console
bundle
rails s
# Visit localhost:3000 in your web browser
```

## Production

Recommended Configuration (as of Nov 30, 2020)

* Rails 6.0.3
* Ruby 2.7.2
* Ubuntu 20.04
* Digital Ocean Droplet

With a fresh Ubuntu 20.04 instance:

### Access the Server

It is good practice to avoid using `root` as the primary user and instead create a dedicated user without unnecessary privileges. 

Login as root
```
ssh root@YOUR_SERVER_IP
```
Create user 'deploy', assign a strong password, and grant sudo permission.
```
adduser deploy
# set a password
adduser deploy sudo
```
Log in as user 'deploy', and add your development machine's public key for more secure, password-less shell access.
```
su - deploy
mkdir .ssh
nano .ssh/authorized_keys
```
On your local machine, run `cat ~/.ssh/id_rsa.pub` and paste the result back on the remote server into '.ssh/authorized_keys' and save the file.

### Set up Production Environment

From here I recommend following  [this GoRails guide](https://gorails.com/deploy/ubuntu/20.04#ruby) starting with the section "Installing Ruby".
Continue through the guide until you get to the section on deploying with Capistrano.

1. Install Ruby through rbenv version manager
1. Install Nginx and Passenger as our webserver
   * Make sure to replace any instances of "myapp" with "classroom_console". 
1. Set up a database
   * If you have your own database server, you may skip this step
   * Otherwise, PostgreSQL is recommended but MySQL is fine too.
   
#### Azure SQL Server Users
If you intend  to use an Azure SQLServer run the following:
```
sudo apt-get install freetds-dev
```   


### Clone the Repository on your Local Machine
You will be executing the command to deploy the app from your local machine. For this, you need a local copy of the repository.

```
git clone https://github.com/jefamirault/classroom_console.git
cd classroom_console
```

If you are using Azure SQL Server, check out the branch 'sqlserver'.

```
git checkout sqlserver
```

Then 

```
bundle
```
#### Local Environment Variables

Be sure to add PRODUCTION_IP to `.env` 


### Deploy with Capistrano 

You can skip most of the GoRails section on setting up Capistrano as it is already done for you.
Take a look in config/deploy/production.rb

```ruby
server ENV['PRODUCTION_IP'], user: 'deploy', roles: %w{app db web}
```

Instead of including

mkdir /home/deploy/myapp
nano /home/deploy/myapp/.rbenv-vars

#### Sample .rbenv-vars
```
# Database credentials

# Config for local PostgreSQL database
DATABASE_USER=postgresql://<database_username>:<database_password>@127.0.0.1/classroom_console
DATABASE_PASSWORD=<password>

RAILS_MASTER_KEY=<long_hexadecimal_string>
SECRET_KEY_BASE=<much_longer_hexadecimal_string>

# ~/classroom_console/.rbenv-vars
DOMAIN=yourdomain.org
PRODUCTION_IP=SERVER_IP_ADDRESS

# Mailserver Settings
SMTP_USER=postmaster@mail.example.org
SMTP_PASSWORD=ChangeMe!
SMTP_DOMAIN=mail.example.org
```

Finally, run the deploy command. You will be prompted to deploy the current branch.
```
cap production deploy
```