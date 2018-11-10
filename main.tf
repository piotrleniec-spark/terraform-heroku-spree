provider "heroku" {
  email = "${var.heroku_email}"
  api_key = "${var.heroku_api_key}"
}

resource "heroku_app" "spree" {
  name = "${terraform.workspace}-spree"
  region = "eu"

  organization = {
    name = "${var.heroku_organization}"
  }

  buildpacks = [
    "heroku/ruby",
    "heroku/nodejs"
  ]

  config_vars = {
    RAILS_ENV = "production"
  }

  provisioner "local-exec" {
    command = <<-SHELL
      cd /tmp
      git clone https://github.com/piotrleniec-spark/spree-app.git
      cd spree-app
      git remote add heroku ${heroku_app.spree.git_url}
      git push heroku master
      cd ..
      rm -rf spree-app
    SHELL
  }
}

resource "heroku_addon" "database" {
  app = "${heroku_app.spree.name}"
  plan = "heroku-postgresql:hobby-dev"

  provisioner "local-exec" {
    command = <<-SHELL
      heroku run 'AUTO_ACCEPT=1 bundle exec rails db:schema:load db:seed spree_sample:load' -a ${heroku_app.spree.name}
    SHELL
  }
}
