### Docker Image

#### Docker build image

`docker build -t your-dockerhub-username/your-app-name:tag .`
e.g.:
`docker build -t leftybanos/tech-app:latest .`

#### Docker push image

`docker push your-dockerhub-username/your-app-name:tag`
e.g.:
`docker push leftybanos/tech-app:latest`

***INFO***
Make sure you update the `deployment` at `app-manifests/all-manifests.yaml`