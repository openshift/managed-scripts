// Assisted by GenAI
package main

import (
	"github.com/openshift/managed-scripts/goapp/cmd"
	"github.com/openshift/managed-scripts/goapp/internal/registry"
	"github.com/openshift/managed-scripts/goapp/pkg/utils"
)

func main() {
	// utils.GetOrInitKubeClient is for lazy load
	// it will only load the kube client when it actual gets called
	// so that kubeconfig is not a hard requirement for running the root command
	modules := registry.NewRegistry(utils.GetOrInitKubeClient)

	cmd.SetModuleRegistry(modules)
	cmd.AddModuleCommands()

	cmd.Execute()
}
