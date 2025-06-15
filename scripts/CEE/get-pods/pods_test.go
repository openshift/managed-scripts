// Assisted by GenAI
package pods

import (
	"testing"

	"github.com/openshift/managed-scripts/goapp/pkg/utils"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/fake"
)

func TestPodModule_Execute(t *testing.T) {
	// Create a fake client with some pods
	scheme := runtime.NewScheme()
	corev1.AddToScheme(scheme)

	client := fake.NewSimpleClientset(
		&corev1.Pod{
			ObjectMeta: metav1.ObjectMeta{
				Name:      "pod-1",
				Namespace: "test-ns",
			},
			Status: corev1.PodStatus{
				Phase: corev1.PodRunning,
			},
		},
	)

	// Create the client factory
	var clientFn utils.ClientFactoryFunc = func() (kubernetes.Interface, error) {
		return client, nil
	}

	podModule := NewPodModuleWithParams(clientFn, &PodParams{Namespace: "test-ns"})

	err := podModule.Execute()
	if err != nil {
		t.Fatalf("Execute() failed: %v", err)
	}
}
