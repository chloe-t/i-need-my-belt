provider "google" {
  credentials = file(env.credentials_json)
  project     = "i-need-my-belt"
  region      = "us-west1"
}