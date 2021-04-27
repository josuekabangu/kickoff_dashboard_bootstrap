=begin
Template Name: Kickoff - Tailwind CSS
Author: Andy Leverenz
Author URI: https://web-crunch.com
Instructions: $ rails new myapp -d <postgresql, mysql, sqlite3> -m template.rb
=end

def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

def add_gems
  gem 'devise', '~> 4.7', '>= 4.7.3'
  gem 'better_errors', '~> 2.9', '>= 2.9.1'
  gem 'friendly_id', '~> 5.4', '>= 5.4.1'
  gem 'name_of_person', '~> 1.1', '>= 1.1.1'
end

def add_users
  # Install Devise
  generate "devise:install"

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  route "root to: 'public#main'"
  route "get 'dashboard' => 'dashboard#index'"

  # Create Devise User
  generate :devise, "User", "first_name", "last_name", "admin:boolean"

  # set admin boolean to false by default
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  # name_of_person gem
  append_to_file("app/models/user.rb", "\nhas_person_name\n", after: "class User < ApplicationRecord")
end

def copy_templates
  directory "app", force: true
end

def add_bootstrap
  # Until PostCSS 8 ships with Webpacker/Rails we need to run this compatability version
  # bootstrap 5
  run "yarn add bootstrap@next"
  run "gem install bootstrap"
  run "yarn add popper.js"
  run "mkdir -p app/javascript/stylesheets"
  run "touch app/javascript/stylesheets/application.scss"

  append_to_file("app/javascript/stylesheets/application.scss", '@import "bootstrap";')
  append_to_file("app/javascript/packs/application.js", 'import "bootstrap"\n import "../stylesheets/application"')
  append_to_file("app/javascript/packs/application.js", 'import "bootstrap-icons/font/bootstrap-icons.css"')

  run "yarn add @popperjs/core"
  run "yarn add bootstrap-icons"
end

# Remove Application CSS
def remove_app_css
  remove_file "app/assets/stylesheets/application.css"
end

def add_foreman
  copy_file "Procfile"
end

def add_friendly_id
  generate "friendly_id"
end

# Main setup
source_paths

add_gems

after_bundle do
  add_users
  remove_app_css
  add_foreman
  copy_templates
  add_bootstrap
  add_friendly_id

  # Migrate
  rails_command "db:create"
  rails_command "db:migrate"

  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }

  say
  say "Kickoff app successfully created! 👍", :green
  say
  say "Switch to your app by running:"
  say "$ cd #{app_name}", :yellow
  say
  say "Then run:"
  say "$ rails server", :green
end
