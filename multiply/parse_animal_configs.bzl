"""
    Virtual repository to provide a animals configuration target to be used by other rules
"""

def _repo_impl(rctx):
    current_repo_path = rctx.path(".")

    rctx.report_progress("Parsing animals_config.json ...")

    rctx.execute(
        ["find", str(rctx.workspace_root) + "/projects", "-type", "f", "-iname", "animals_config.json", "-fprint", str(current_repo_path.get_child("animals_config.lst"))],
        timeout = 5,
        environment = {},
        quiet = False,
        working_directory = "",
    )
    animal_configs = rctx.read("animals_config.lst", watch = "auto").split("\n")
    projects = {}
    rctx.delete("animals_config.lst")
    for file in animal_configs:
        if file:
            segments = file.split("/")
            project = segments[-2]
            projects[project] = file

    # The defs.bzl file shall contain a CONSTANT that is containing the necessary structure
    # to read in the animals in a macro.
    # Structure should look like the following:
    # ANIMALS = {
    #    "//configs/constraints:<project>": animals
    # }

    bzl_file = """# This file is generated by parse_animal_configs.bzl. Do not edit manually.
ANIMALS = {
"""
    for project, file in projects.items():
        animals = json.decode(rctx.read(file, watch = "auto"))
        bzl_file += '    "//configs/constraints:{project}": {data},'.format(
            project = project,
            data = json.encode_indent(animals, indent = "    ", prefix = "    "),
        )
    bzl_file += """
}
"""

    rctx.file("defs.bzl", content = bzl_file, executable = False, legacy_utf8 = True)
    rctx.file("BUILD.bazel", content = "", executable = False, legacy_utf8 = True)

    rctx.report_progress("Done.")

parse_animals_repo = repository_rule(
    implementation = _repo_impl,
    attrs = {
    },
    local = True,
    configure = True,
    doc = "Repository to provide a dynamic animals configuration target to be used by other rules",
)
