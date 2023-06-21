# Get to right directory
cd ai/matomo
# GTFO images
docker system prune -a
# Build
docker build -t matomo .
# Run
docker run --privileged -p 8080:80 -v matomo:/var/www/html/ matomo
# Execute
docker exec -it {name} /bin/bash
# Deploy
gcloud run deploy matomo-custom  --source . --execution-environment gen2 --allow-unauthenticated --service-account fs-identity --port 80 --region europe-west1
# Curl localhost
curl localhost:8080
# Complete gcsfuse
gcsfuse --key-file=/service_acc.json --debug_gcs --debug_fuse -o allow_other -o nonempty --implicit-dirs --dir-mode=777 --file-mode=777 --in matomo-plugin /var/www/html/config
# Use gsutil to copy all subdirectories of plugins to the gcs bucket gc://matomo-plugins
gsutil -m cp -r plugins/* gs://matomo-plugins
# Use gsutil to copy all subdirectories of config to the gcs bucket gc://matomo-config