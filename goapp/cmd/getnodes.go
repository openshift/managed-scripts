// cmd/getnodes.go
package cmd

import (
	"fmt"

	srepnode "github.com/openshift/managed-scripts/goapp/pkg/srepnode"
	"github.com/spf13/cobra"
)

var getNodesCmd = &cobra.Command{
	Use:   "getnodes",
	Short: "List Kubernetes nodes",
	Run: func(cmd *cobra.Command, args []string) {
		var mod = srepnode.NodeModule{}
		if err := mod.Execute(); err != nil {
			fmt.Printf("Error: %v\n", err)
		}
	},
}

func init() {
	RootCmd.AddCommand(getNodesCmd)
}
