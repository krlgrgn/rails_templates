#
# Application Setup
# ==================================
# Application generators configuration
inject_into_file "config/application.rb", :before => "  end" do <<-'RUBY'
    # Generator configuration
    config.generators do |g|
      g.test_framework :rspec,
        fixture: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: true,
        controller_specs: true,
        request_specs: true
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end
RUBY
end


#
# gitignore
# ===================================
run "cat << EOF >> .gitignore
/.bundle
/db/*.sqlite3
/db/*.sqlite3-journal
/log/*.log
/tmp
database.yml
doc/
*.swp
*~
.project
.idea
.secret
.DS_Store
EOF"


#
# Gems
# ===================================
# Authentication
gem 'devise'

# Authorization
gem 'declarative_authorization'

gem_group :development, :test do
  gem 'rspec-rails' # Testing framework for rails.
  gem 'factory_girl_rails' # Replaces fixtures for feeding test data via factories.
end

gem_group :test do
  gem 'faker' # Generates fake test data.
  gem 'capybara'
end

# Use unicorn as the app server
gem 'unicorn'

# Postgres
gem 'pg'

# Styling
gem 'foundation-rails'

# Install the gems
run 'bundle install'

#
# Rspec Setup
# ===================================
generate "rspec:install"

run "echo \"--format documentation\" >> .rspec"

inject_into_file "spec/spec_helper.rb", :after => "require 'rspec/autorun'" do
  "\nrequire 'capybara/rspec'"
end

# Create spec/features to place out feature spec.
run "mkdir spec/features"


#
# Foundation Setup
# ===================================
remove_file 'app/views/layouts/application.html.erb'
generate "foundation:install"

#
# Base User Setup
# ===================================
generate "scaffold User email:string first_name:string last_name:string password_digest:string session_token:string"

#
# Authentication Setup
# ===================================


#
# Authorization Setup
create_file "config/authoriazation_rules.rb" do
  "#
# Here we define the roles that each user could have.
# A user could have many roles, and each role could have many users.
# We have a many to many relationship between users and roles.
#
authorization do
  #role :admin do
  #  has_permission_on [:adventures], :to => [:index, :show, :new, :create, :edit, :update, :destroy]
  #end
  #role :adventurer do
  #  has_permission_on [:adventures], :to => [:index, :show, :new, :create]
  #  has_permission_on [:adventures], :to => [:edit, :update, :destroy] do
  #    if_attribute :user => is { user }
  #  end
  #end
end"
end

run "rake db:migrate"
run "rake db:test:prepare"

say <<-eos
============================================================================
Your new Rails application is ready to go.
Don't forget to scroll up for important messages from installed generators.

No model spec has been written for the User model.
eos
