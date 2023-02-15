variable "GOOGLE_APPLICATION_CREDENTIALS" {}

provider "google" {
  credentials = "${var.GOOGLE_APPLICATION_CREDENTIALS}"
  project     = "i-need-my-belt"
  region      = "us-west1"
}