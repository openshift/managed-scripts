import sys, yaml, json, os

with open(sys.argv[1], 'r') as yaml_in, open(''.join((sys.argv[1].split('.')[:-1])) + ".json", "w") as json_out:
    yaml_object = yaml.safe_load(yaml_in)
    json.dump(yaml_object, json_out)
