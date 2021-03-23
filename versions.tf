terraform {
  required_version = "> 0.12"
  required_providers {
    google = {
      version = "= 3.60.0"
    }

    template = {
      version = "= 2.2.0"
    }

    random = {
      version = "= 3.1.0"
    }
  }
}