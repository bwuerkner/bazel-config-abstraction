# bazel-config-abstraction
A set of ideas how one can perform config abstraction using BAZEL

# Abstract handling of identical type different content input files for different projects

Imagine the following scenario:
- A set of Services are developed by independent teams.
- Services can be configured at compile or link time by values in header files.
- These header files are generated by scripts owned by the service teams.
- The inputs to these scripts are clearly defined configuration files with a schema owned by the service team.
- The selection of which services are active for a project is on the project configuration side.

A way to abstract this in BAZEL is to define a `configs` folder with a `Build.bazel` file that performs no other function than to apply select statements to filegroups coming from individual projects (their input files) and provide a common name (`//configs:name`) for them to be used by the services.

It is then in the responsibility of the project to decide how the file will be provided to the service.
It could even happen that the project decides to write it's own transformer from some (maybe provided by a proprietary, external script) format to the expected format of the service and reference this output in the `configs/BUILD.bazel` file.

# Handling of output structure creation using rules_pkg

# Handling of (json based, high level) project configurations at action graph creation time
