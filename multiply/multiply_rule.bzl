""" Macros that generate targets for different animals. """

load("@aspect_bazel_lib//lib:run_binary.bzl", "run_binary")
load("@parse_animals_repo//:defs.bzl", "ANIMALS")

def _format(rule_value, values):
    """ Helper function to format the rule value with the values."""
    if type(rule_value) == type((None,)) or type(rule_value) == type(list()):
        return [value.format(**values) for value in rule_value]
    elif type(rule_value) == type(""):
        return rule_value.format(**values)
    else:
        fail("multiply_rule: rule_value of type '%s' is not supported" % type(rule_value))

def _instantiate_rule(src_rule, dest_rules_select, name_with_placeholders, placeholder_values):
    dst_rule_attrs = {}
    constraint = placeholder_values["constraint"]
    for rule_key, rule_value in src_rule.items():
        if rule_key == "kind" or rule_key.startswith("generator_") or rule_key == "mnemonic":
            # No substitution for kind and generator_ attributes
            continue

        if rule_key == "name":
            rule_value = name_with_placeholders.replace(" ", "_")

        if rule_value:
            dst_rule_attrs[rule_key] = _format(rule_value, placeholder_values)

        if rule_key == "name":  # Add the sub target to the dict for the file group. Needs to be done here to have it added to dst_rule_attrs first.
            dest_rules_select[constraint].append(":" + dst_rule_attrs[rule_key])

    #print("multiply_existing_target: dst_rule_attrs = %s" % dst_rule_attrs)
    if src_rule.get("kind") == "_run_binary":
        run_binary(**dst_rule_attrs)
    elif src_rule.get("kind") == "genrule":
        native.genrule(**dst_rule_attrs)
    else:
        fail("multiply_existing_target: rule %s is not supported" % src_rule.get("kind"))

def multiply_existing_target(name, target, animals_per_project = ANIMALS, iterator = "species", conditions = [], **kwargs):
    """ Macro to wrap an existing target of a rule to create multiple targets of the same type for different animals.

    Args:
      name: name of the filegroup target to be created that contains select for the outputs per iterator.

      target: existing target of a rule to be multiplied based on the chosen iterator.

      animals_per_project: argument to specify which animals are defined for each project

      iterator: argument to specify which iterator to use. Options are "species", "name" with "species" as default.

      conditions: argument to provide conditions to filter for. The argument is expected to be a list with dictionaries
                  that contain the condition to filter for. The condition is expected to be a dictionary with the key
                  being the attribute to filter for and the value being the value to filter for. A third key "invert"
                  with the value "True" may be provided to invert the condition.
                  Examples:
                    - [{"type": "carnivore", "invert": "True"}] will filter for all animals that are not "carnivore".
                    - [{"species": "lion"}] will filter for all lions.

      **kwargs: arguments to be passed on to filegroup.
    """
    if iterator not in ["species", "name"]:
        fail("multiply_rule: iterator %s is not supported. Needs to be 'species' or 'name'" % iterator)

    src_rule = native.existing_rule(target)

    dest_rules_select = {}
    for constraint, configs in animals_per_project.items():
        project = constraint.split(":")[-1]

        dest_rules_select[constraint] = []

        for animal in configs.get("animals"):
            species = animal.get("species")
            placeholder_values = {"name": name, "project": project, "constraint": constraint, "species": species}
            if iterator == "species":
                if not condition_applies(animal, conditions):
                    continue
                name_with_placeholders = name + "_{project}_{species}"
                _instantiate_rule(src_rule, dest_rules_select, name_with_placeholders, placeholder_values)
            else:  # iterator == "name"
                for animal_name in animal.get("names", []):
                    if not condition_applies({"animal_name": animal_name}, conditions):
                        continue
                    placeholder_values["animal_name"] = animal_name

                    name_with_placeholders = name + "_{project}_{species}_{animal_name}"
                    _instantiate_rule(src_rule, dest_rules_select, name_with_placeholders, placeholder_values)

    native.filegroup(
        name = name,
        srcs = select(dest_rules_select),
        **kwargs
    )

def condition_applies(data, conditions):
    """ Helper function to check if the conditions apply to the provided data.

    Args:
      data: The data related to the animal that needs to be checked.
      conditions: The conditions that need to be applied to the data.

    Returns:
      A boolean indicating whether the conditions apply to the data.
    """
    for condition in conditions:
        invert = condition.get("invert", False)
        if type(invert) != type(True):
            fail("value of 'invert' must be boolean!")
        for key, value in condition.items():
            if key == "invert":
                continue

            # Value is not defined, programming error (value not exposed)
            if key not in data:
                fail("multiply_rule: condition key %s is not in data. Supported condition keys are: [species, type, name]. " % key)
            if (data[key] == value and invert) or (
                data[key] != value and not invert
            ):
                return False
    return True
