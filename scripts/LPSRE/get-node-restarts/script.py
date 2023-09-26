'''
CheckNodeRestart is a managed backplane script in order to
find out the NODES that got restarted in the LAST_MIN duration
and list out all the pods that the associated with the particular NODE

'''
import argparse
import json
import datetime
import sys

LIB_PATH = "/managed-scripts/LPSRE/lib"
# Use sys.path.insert because PYTHONPATH's support is unclear
sys.path.insert(0, LIB_PATH)

from py.script import Script

LAST_MIN = 60 # default value

class CheckNodeRestart(Script):
    """
    CheckNodeRestart is a managed backplane script to find out
    NODES that got restarted in the LAST_MIN duration

    Usage:
    ocm backplane managedjob create # with default env variables
    ocm backplane managedjob create -p LAST_MIN=<duration> -p LOG_LEVEL=""
    """

    def __init__(self):
        # this will ensure optional environment variables
        env_vars = ["LAST_MIN", "LOG_LEVEL"]
        self.parser = None
        super().__init__(env_vars=env_vars, check_env_var=False)

    def create_parser(self):
        self.parser = argparse.ArgumentParser()

    def get_node_data(self):
        """
        Get node event metadata
        """
        _, node_data, errors = self.cmd.run_pipe(["oc", "get", "nodes", "-o", "json"], check=False)
        if errors:
            self.logger.error(errors)
            self.exit(1)
        node_data = json.loads(node_data)
        return node_data

    @staticmethod
    def get_node_transition_ts(node_data):
        """
        Get Last Transition time of each node for
        reason 'KubeletReady'
        """
        output_dict = {}
        nodes = node_data.get("items", [])
        if nodes:
            for node in nodes:
                conditions = node["status"]["conditions"]
                for condition in conditions:
                    if condition["reason"] == "KubeletReady":
                        last_transition_time = condition["lastTransitionTime"]
                        output_dict[node["metadata"]["name"]] = last_transition_time
        return output_dict

    def get_pods(self, node_name):
        """
        Get list of pods associated with particular node_name
        return:
        output_dict {"podname": "podnamespace"}
        """
        output_dict = {}
        args = [
            "oc",
            "get",
            "pods",
            "--all-namespaces",
            "--field-selector",
            f"spec.nodeName={node_name}",
            "-o",
            "json",
        ]
        _, pod_data, errors = self.cmd.run_pipe(args, check=False)
        if errors:
            self.logger.error(errors)
            self.exit(1)
        pod_data = json.loads(pod_data)
        pods = pod_data.get("items", [])
        for pod in pods:
            metadata = pod.get("metadata")
            output_dict[metadata.get("name")] = metadata.get("namespace")
        return output_dict

    def run(self):
        # the script is getting input arguments from metadata.yaml as env variables
        if not self.LAST_MIN:
            self.LAST_MIN = LAST_MIN

        self.logger.debug(f"LAST_MIN: {self.LAST_MIN}")

        self.logger.debug("Gathering Node Data...")
        node_transition_data = self.get_node_transition_ts(self.get_node_data())
        if node_transition_data:
            print(f"Nodes restarted in the last {self.LAST_MIN} minutes\n")
            print("Node Name\t\t\tMinutes")
            for node, timestamp in node_transition_data.items():
                time_obj = datetime.datetime.strptime(
                    timestamp, "%Y-%m-%dT%H:%M:%SZ"
                ).replace(tzinfo=datetime.timezone.utc)
                current_time_obj = datetime.datetime.now(datetime.timezone.utc)
                time_difference = current_time_obj - time_obj
                time_difference_minutes = int(time_difference.total_seconds() / 60)
                self.logger.debug(f"time difference in minutes: {time_difference_minutes}")
                if time_difference_minutes < int(self.LAST_MIN):
                    print(node, time_difference_minutes)
                    print("----------------------------")
                    print("Pods associated with the particular node:")
                    self.logger.debug(f"Gather pod data for node: {node}...")
                    pods = self.get_pods(node)
                    self.logger.debug("printing data using tabulate...")
                    self.print_table(
                        [[podname, namespace] for podname, namespace in pods.items()],
                        headers=["PodName", "Namespace"],
                    )


if __name__ == "__main__":
    CheckNodeRestart()
