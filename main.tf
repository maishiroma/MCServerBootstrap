# Make sure you have a project named this first!
provider "google" {
  project     = "mcserverbootstrap"
  region      = var.region
  credentials = file(var.creds_json)
}

terraform {
  required_version = "> 0.12"
  required_providers {
    google = {
      version = "= 3.60.0"
    }

    template = {
      version = "= 2.2.0"
    }
  }

  # Just to make things easier for PoC, the state is stored locally.
  # If one wants to manage this stack on different computers, make sure to specify a remote backend instead
  backend "local" {
    path = "./terraform.tfstate"
  }
}

