image_tag() {
    local version
    version="${BASE_VERSION}-$(version_tag)"
    if [ -n "${VERSION_OVERRIDE:-""}" ]; then
        version="$VERSION_OVERRIDE"
    fi
    echo "${version}"
}

tag_push() {
    local image_name=${1}
    shift
    local version=${1}
    shift
    local additional_tags=("$@")

    log "${GREEN}Pushing${NOFORMAT} ${image_name}:${version}"

    docker push "${image_name}:${version}"

    for tag in "${additional_tags[@]}"; do
        log "${GREEN}Tagging${NOFORMAT} ${image_name}:${version} as ${tag}"
        docker tag "${image_name}:${version}" "${image_name}:${tag}"
        docker push "${image_name}:${tag}"
    done
}

# Parse the registry YAML file to get tag information
tags_for_registry_image() {
    # name of the image to look up in the registry
    local name="$1"
    local registry_file="${ROOT_DIR}/image_registry.yaml"
    local tags
    local query
    query=$(printf ".%s.tags[]" "${name}")

    if [[ ! -f "${registry_file}" ]]; then
        die "Registry file not found at ${registry_file}"
    fi

    log "Reading registry data for ${CYAN}${name}${NOFORMAT}"

    tags=$(yq "${query}" "${registry_file}")
    if [[ -z "${tags}" ]]; then
        log "No tags found in registry file for #{name}"
        return 1
    fi
    echo "$tags"
}

default_tag_for_registry_image() {
    # name of the image to look up in the registry
    local name="$1"
    local registry_file="${ROOT_DIR}/image_registry.yaml"
    local tag
    local query
    query=$(printf ".%s.default_tag" "${name}")

    if [[ ! -f "${registry_file}" ]]; then
        die "Registry file not found at ${registry_file}"
    fi

    log "Reading registry data for ${CYAN}${name}${NOFORMAT}"

    tag=$(yq "${query}" "${registry_file}")
    if [[ -z "${tag}" ]]; then
        log "No default tag found in registry file for #{name}"
        return 1
    fi
    echo "$tag"
}

tool_version() {
    local name="$1"

    local tool_version_file="${ROOT_DIR}/.tool-versions"
    [[ -f "${tool_version_file}" ]] || die ".tool_version file not found at ${tool_version_file}"

    local version
    version=$(yq --input-format props --output-format yaml ".${name}" "${tool_version_file}")
    [[ -z "${version}" ]] && log "no version found for ${name} in ${tool_version_file}"

    echo "${version}"
}

# Strip version hash from tags (e.g., 26.3.0-16b3adf7c -> 26.3.0)
strip_version_hash() {
    local tags="$1"
    echo "${tags}" | sed -E 's/(-\w+)$//' | sort -u
}

# Find tags that are in upstream but not in our images
find_missing_tags() {
    local upstream="$1"
    local ours="$2"

    echo "${upstream} ${ours}" | tr ' ' '\n' | sort | uniq -u
}

# Validate that an image exists before trying to push it
validate_image_exists() {
    local image_name="$1"

    log "Checking if image exists: ${image_name}"

    if ! docker image inspect "${image_name}" &>/dev/null; then
        log "Image not found: ${image_name}"
        die "Try building the image first with: ${CYAN}bix-docker build-image <target> <upstream_tag>${NOFORMAT}"
    fi

    log "Image exists: ${image_name}"
    return 0
}

docker_hash() {
    git rev-parse --short=9 HEAD:docker
}

base_image_tag() {
    echo "$(default_tag_for_registry_image ubuntu)-$(docker_hash)"
}
