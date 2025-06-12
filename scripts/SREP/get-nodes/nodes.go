package srepnodes

import (
	"context"
	"fmt"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

type NodeModule struct{}

func (n NodeModule) Execute() error {
	clientset, err := getKubeClient()
	if err != nil {
		return fmt.Errorf("failed to create k8s client: %w", err)
	}

	nodes, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return fmt.Errorf("failed to list nodes: %w", err)
	}

	fmt.Println("Nodes in the cluster:")
	for _, node := range nodes.Items {
		fmt.Printf("- %s\n", node.Name)
	}
	return nil
}

func getKubeClient() (*kubernetes.Clientset, error) {
	// from the example in https://pkg.go.dev/k8s.io/client-go/tools/clientcmd#pkg-overview
	loadingRules := clientcmd.NewDefaultClientConfigLoadingRules()
	configOverrides := &clientcmd.ConfigOverrides{}
	kubeConfig := clientcmd.NewNonInteractiveDeferredLoadingClientConfig(loadingRules, configOverrides)
	config, err := kubeConfig.ClientConfig()
	if err != nil {
		return nil, err
	}

	return kubernetes.NewForConfig(config)
}
