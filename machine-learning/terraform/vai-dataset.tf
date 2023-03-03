resource "google_vertex_ai_dataset" "vai-dataset" {
  display_name          = "terraform" #TODO var
  metadata_schema_uri   = "gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml" #TODO var
  region                = "us-central1" #TODO var with limited options
  #encryption_spec
}