#!/bin/bash

entries=(
    "Run the transitioned final output of project A: "
    "bazel build projects/projectA/package:final"
    "Run the transitioned final output of project C: "
    "bazel build projects/projectC/package:final"
    "Run the multiplyable service with the 'all_animals' target: "
    "bazel build product/multiplyable_service:all_animals --platforms=//configs/platforms:ProjectA"
    "Run the multiplyable service with the 'only_carnivores' target: "
    "bazel build product/multiplyable_service:only_carnivores --platforms=//configs/platforms:ProjectA"
    "Run the multiplyable service with the 'all_names' target: "
    "bazel build product/multiplyable_service:all_names --platforms=//configs/platforms:ProjectA"
    "Run the multiplyable service with the 'all_names' target for project C: "
    "bazel build product/multiplyable_service:all_names --platforms=//configs/platforms:ProjectC"
    )

for ((i=0; i<${#entries[@]}; i+=2)); do
    echo "${entries[i]}"
    read -p "$(echo "\$ ${entries[i+1]}")" response
    if [ "$response" = "" ]; then
        ${entries[i+1]}
        echo ""
    else
        break
    fi
done
