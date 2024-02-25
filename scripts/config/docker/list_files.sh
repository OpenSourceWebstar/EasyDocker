#!/bin/bash

# Function to list Docker Compose files in a directory
listDockerComposeFiles() 
{
  local dir="$1"
  local docker_compose_files=()

  for file in "$dir"/*; do
    if [[ -f "$file" && "$file" == *docker-compose* ]]; then
      docker_compose_files+=("$file")
    fi
  done

  echo "${docker_compose_files[@]}"
}
