// Assisted-by Generative AI.

package utils

import (
	"sync"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

type ClientFactoryFunc func() (kubernetes.Interface, error)

var (
	clientOnce   sync.Once
	cachedClient kubernetes.Interface
	clientErr    error
)

func GetOrInitKubeClient() (kubernetes.Interface, error) {
	clientOnce.Do(func() {
		cachedClient, clientErr = GetKubeClient(NewDefaultConfigLoader())
	})
	return cachedClient, clientErr
}

type ConfigLoader interface {
	ClientConfig() (*rest.Config, error)
}

func GetKubeClient(loader ConfigLoader) (*kubernetes.Clientset, error) {
	config, err := loader.ClientConfig()
	if err != nil {
		return nil, err
	}
	return kubernetes.NewForConfig(config)
}
