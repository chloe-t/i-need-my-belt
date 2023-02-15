provider "google" {
    credentials = "${file("credentials.json")}"
    project = "i-need-my-belt"
    region = "us-west1"
}
