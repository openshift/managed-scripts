// Assisted by GenAI
package pods

import (
	"context"
	"fmt"

	"github.com/openshift/managed-scripts/goapp/internal/cli"
	"github.com/openshift/managed-scripts/goapp/pkg/utils"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type PodParams struct {
	// defined the parameters that will be used by Execute().
	// the main program will handle the input for those parameters, it will read from ENV or subcommand arguments.
	Namespace string `flag:"namespace" env:"NAMESPACE" default:"default" usage:"Namespace to list pods"`
	Selector  string `flag:"selector" env:"SELECTOR" usage:"Label selector"`
}

type PodModule struct {
	// we will need to register a module in internal/registry/registry.go
	// this module should implement CommandModule as defined in internal/cli/cli.go
	// clientFn is optional. If we need to interact with kube-apiserver, we can accept a clientFn here.
	clientFn utils.ClientFactoryFunc
	params   *PodParams
}

func NewPodModule(clientFn utils.ClientFactoryFunc) *PodModule {
	return &PodModule{
		clientFn: clientFn,
		params:   &PodParams{},
	}
}

func NewPodModuleWithParams(clientFn utils.ClientFactoryFunc, params *PodParams) *PodModule {
	return &PodModule{
		clientFn: clientFn,
		params:   params,
	}
}

func (m *PodModule) Name() string       { return "getpods" }
func (m *PodModule) Summary() string    { return "List pods in a namespace" }
func (m *PodModule) Params() cli.Params { return m.params }

func (m *PodModule) Execute() error {
	client, err := m.clientFn()
	if err != nil {
		return fmt.Errorf("failed to init Kubernetes client: %w", err)
	}

	pods, err := client.CoreV1().Pods(m.params.Namespace).List(context.TODO(), metav1.ListOptions{
		LabelSelector: m.params.Selector,
	})
	if err != nil {
		return err
	}

	for _, pod := range pods.Items {
		fmt.Println("-", pod.Name)
	}
	return nil
}
