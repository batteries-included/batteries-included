defmodule CommonCore.Util.ImagesTest do
  use ExUnit.Case, async: true

  alias CommonCore.Util.Images

  doctest Images

  describe "repository/1" do
    test "extracts repository from full image string" do
      assert Images.repository("nvcr.io/nvidia/cuda:12.8.1-base-ubi9") == "nvcr.io/nvidia"
      assert Images.repository("docker.io/library/nginx:1.21") == "docker.io/library"
      assert Images.repository("registry.k8s.io/autoscaling/addon-resizer:1.8.23") == "registry.k8s.io/autoscaling"
      assert Images.repository("gcr.io/my-project/my-app:v1.0.0") == "gcr.io/my-project"
    end

    test "handles images with namespace but no registry" do
      assert Images.repository("library/nginx:1.21") == "library"
      assert Images.repository("nvidia/cuda:latest") == "nvidia"
      assert Images.repository("company/internal/app:dev") == "company/internal"
    end

    test "handles simple image names without repository" do
      assert Images.repository("nginx:1.21") == ""
      assert Images.repository("redis:6.2") == ""
      assert Images.repository("postgres:13") == ""
    end

    test "handles images without tags" do
      assert Images.repository("nvcr.io/nvidia/cuda") == "nvcr.io/nvidia"
      assert Images.repository("docker.io/library/nginx") == "docker.io/library"
      assert Images.repository("nginx") == ""
    end

    test "handles deep namespaces" do
      assert Images.repository("registry.company.com/team/project/service/app:v1.0") ==
               "registry.company.com/team/project/service"

      assert Images.repository("localhost:5000/dev/test/image:latest") == "localhost:5000/dev/test"
    end

    test "handles edge cases" do
      assert Images.repository("") == ""
      assert Images.repository("single") == ""
      assert Images.repository("single:tag") == ""
    end
  end

  describe "image/1" do
    test "extracts image name from full image string" do
      assert Images.image("nvcr.io/nvidia/cuda:12.8.1-base-ubi9") == "cuda"
      assert Images.image("docker.io/library/nginx:1.21") == "nginx"
      assert Images.image("registry.k8s.io/autoscaling/addon-resizer:1.8.23") == "addon-resizer"
      assert Images.image("gcr.io/my-project/my-app:v1.0.0") == "my-app"
    end

    test "handles images with namespace but no registry" do
      assert Images.image("library/nginx:1.21") == "nginx"
      assert Images.image("nvidia/cuda:latest") == "cuda"
      assert Images.image("company/app:dev") == "app"
    end

    test "handles simple image names without repository" do
      assert Images.image("nginx:1.21") == "nginx"
      assert Images.image("redis:6.2") == "redis"
      assert Images.image("postgres:13") == "postgres"
    end

    test "handles images without tags" do
      assert Images.image("nvcr.io/nvidia/cuda") == "cuda"
      assert Images.image("docker.io/library/nginx") == "nginx"
      assert Images.image("nginx") == "nginx"
    end

    test "handles hyphenated and special character image names" do
      assert Images.image("registry.k8s.io/autoscaling/addon-resizer:1.8.23") == "addon-resizer"
      assert Images.image("gcr.io/project/my_app:latest") == "my_app"
      assert Images.image("registry.com/team/app.service:v1") == "app.service"
    end

    test "handles deep namespaces" do
      assert Images.image("registry.company.com/team/project/service/final-app:v1.0") == "final-app"
      assert Images.image("localhost:5000/dev/test/nested/image:latest") == "image"
    end

    test "handles edge cases" do
      assert Images.image("") == ""
      assert Images.image("single") == "single"
      assert Images.image("single:tag") == "single"
    end
  end

  describe "version/1" do
    test "extracts version from full image string" do
      assert Images.version("nvcr.io/nvidia/cuda:12.8.1-base-ubi9") == "12.8.1-base-ubi9"
      assert Images.version("docker.io/library/nginx:1.21") == "1.21"
      assert Images.version("registry.k8s.io/autoscaling/addon-resizer:1.8.23") == "1.8.23"
      assert Images.version("gcr.io/my-project/my-app:v1.0.0") == "v1.0.0"
    end

    test "handles complex version strings" do
      assert Images.version("nginx:1.21.3-alpine") == "1.21.3-alpine"
      assert Images.version("postgres:13.4-bullseye") == "13.4-bullseye"
      assert Images.version("node:16.14.0-alpine3.15") == "16.14.0-alpine3.15"
      assert Images.version("mysql:8.0.28-debian") == "8.0.28-debian"
    end

    test "handles semantic versioning" do
      assert Images.version("myapp:v1.2.3") == "v1.2.3"
      assert Images.version("service:v2.0.0-rc.1") == "v2.0.0-rc.1"
      assert Images.version("api:1.0.0-beta.5") == "1.0.0-beta.5"
    end

    test "returns 'latest' for images without explicit tags" do
      assert Images.version("nginx") == "latest"
      assert Images.version("docker.io/library/nginx") == "latest"
      assert Images.version("nvcr.io/nvidia/cuda") == "latest"
      assert Images.version("gcr.io/project/app") == "latest"
    end

    test "handles special tags" do
      assert Images.version("nginx:latest") == "latest"
      assert Images.version("app:dev") == "dev"
      assert Images.version("service:staging") == "staging"
      assert Images.version("api:main") == "main"
    end

    test "handles versions with multiple colons" do
      # Only splits on the first colon, so port numbers in registries work correctly
      assert Images.version("localhost:5000/app:v1.0") == "v1.0"
      assert Images.version("registry.com:8080/project/service:latest") == "latest"
    end

    test "handles edge cases" do
      assert Images.version("") == "latest"
      assert Images.version("app:") == ""
      assert Images.version(":tag") == "tag"
    end
  end

  describe "integration tests" do
    test "all functions work together on real-world examples" do
      # NVIDIA GPU Operator images
      gpu_operator_image = "nvcr.io/nvidia/gpu-operator:v25.3.2"
      assert Images.repository(gpu_operator_image) == "nvcr.io/nvidia"
      assert Images.image(gpu_operator_image) == "gpu-operator"
      assert Images.version(gpu_operator_image) == "v25.3.2"

      # Kubernetes system images
      k8s_image = "registry.k8s.io/autoscaling/addon-resizer:1.8.23"
      assert Images.repository(k8s_image) == "registry.k8s.io/autoscaling"
      assert Images.image(k8s_image) == "addon-resizer"
      assert Images.version(k8s_image) == "1.8.23"

      # Simple Docker Hub images
      simple_image = "nginx:1.21.3-alpine"
      assert Images.repository(simple_image) == ""
      assert Images.image(simple_image) == "nginx"
      assert Images.version(simple_image) == "1.21.3-alpine"

      # Private registry with port
      private_image = "localhost:5000/team/myapp:v2.0.0"
      assert Images.repository(private_image) == "localhost:5000/team"
      assert Images.image(private_image) == "myapp"
      assert Images.version(private_image) == "v2.0.0"
    end

    test "reconstructing image strings" do
      original = "nvcr.io/nvidia/k8s-device-plugin:v0.17.3"
      repo = Images.repository(original)
      image = Images.image(original)
      version = Images.version(original)

      reconstructed =
        case repo do
          "" -> "#{image}:#{version}"
          _ -> "#{repo}/#{image}:#{version}"
        end

      assert reconstructed == original
    end
  end
end
