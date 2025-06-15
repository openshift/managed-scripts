// Assitsted by GenAI

package nodes

import (
	"context"
	"fmt"

	"github.com/openshift/managed-scripts/goapp/internal/cli"
	"github.com/openshift/managed-scripts/goapp/pkg/utils"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type NodeModule struct {
	clientFn utils.ClientFactoryFunc
}

func NewNodeModule(clientFn utils.ClientFactoryFunc) *NodeModule {
	return &NodeModule{
		clientFn: clientFn,
	}
}

func (n NodeModule) Name() string       { return "getnodes" }
func (n NodeModule) Summary() string    { return "List nodes in the cluster" }
func (n NodeModule) Params() cli.Params { return nil }

func (n NodeModule) Execute() error {
	client, err := n.clientFn()
	if err != nil {
		return fmt.Errorf("failed to init Kubernetes client: %w", err)
	}

	nodes, err := client.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return fmt.Errorf("failed to list nodes: %w", err)
	}

	fmt.Println("Nodes in the cluster:")
	for _, node := range nodes.Items {
		fmt.Printf("- %s\n", node.Name)
	}
	return nil
}
