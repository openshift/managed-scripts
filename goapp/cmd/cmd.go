// Assisted by GenAI

package cmd

import (
	"github.com/openshift/managed-scripts/goapp/internal/cli"
)

var moduleRegistry map[string]cli.CommandModule

// Allow runtime injection of module registry
func SetModuleRegistry(m map[string]cli.CommandModule) {
	moduleRegistry = m
}

// Add all registered modules to RootCmd using cli.WrapModule
func AddModuleCommands() {
	for _, module := range moduleRegistry {
		cmd := cli.WrapModule(module) // This builds the Cobra command with flag/env/param loading
		RootCmd.AddCommand(cmd)
	}
}
