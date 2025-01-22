terraform {
  backend "s3" {
    bucket = "terrform-statefile-mbee"
    key    = "stg/devops/eks2/state" # this will save file in s3
    region = "ap-southeast-1"
  }
}
