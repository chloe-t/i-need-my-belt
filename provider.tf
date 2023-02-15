provider "google" {
  credentials = file(var.credentials_json)
  project     = "i-need-my-belt"
  region      = "us-west1"
}