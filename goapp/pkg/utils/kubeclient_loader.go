// Assisted-by Generative AI.

package utils

import (
	"k8s.io/client-go/tools/clientcmd"
)

func NewDefaultConfigLoader() ConfigLoader {
	loadingRules := clientcmd.NewDefaultClientConfigLoadingRules()
	overrides := &clientcmd.ConfigOverrides{}
	return clientcmd.NewNonInteractiveDeferredLoadingClientConfig(loadingRules, overrides)
}
