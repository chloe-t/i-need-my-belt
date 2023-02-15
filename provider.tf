variable "GOOGLE_APPLICATION_CREDENTIALS" {}

provider "google" {
  credentials = file("${var.GOOGLE_APPLICATION_CREDENTIALS}")
  project     = "i-need-my-belt"
  region      = "us-west1"
}