import yaml
import json
import os
with open("./../scripts/SREP/example/metadata.yaml", 'r') as yaml_in, open("./../scripts/SREP/example/metadata.json", "w") as json_out:
    yaml_object = yaml.safe_load(yaml_in) # yaml_object will be a list or a dict
    json.dump(yaml_object, json_out)
