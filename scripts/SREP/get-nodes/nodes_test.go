// Assitsted by GenAI
package nodes

import (
	"fmt"
	"testing"

	"github.com/openshift/managed-scripts/goapp/pkg/utils"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/fake"
	k8stesting "k8s.io/client-go/testing"
)

func TestNodeModule_Execute(t *testing.T) {
	client := fake.NewSimpleClientset(
		&corev1.Node{
			ObjectMeta: metav1.ObjectMeta{
				Name: "node-1",
			},
		},
		&corev1.Node{
			ObjectMeta: metav1.ObjectMeta{
				Name: "node-2",
			},
		},
	)

	// Create the client factory
	var clientFn utils.ClientFactoryFunc = func() (kubernetes.Interface, error) {
		return client, nil
	}

	module := NewNodeModule(clientFn)

	if err := module.Execute(); err != nil {
		t.Fatalf("Execute() failed: %v", err)
	}
}

func TestNodeModule_Execute_Error(t *testing.T) {
	client := fake.NewSimpleClientset()
	client.PrependReactor("list", "nodes", func(action k8stesting.Action) (bool, runtime.Object, error) {
		return true, nil, fmt.Errorf("fake list error")
	})

	// Create the client factory
	var clientFn utils.ClientFactoryFunc = func() (kubernetes.Interface, error) {
		return client, nil
	}

	module := NewNodeModule(clientFn)

	err := module.Execute()
	if err == nil {
		t.Fatal("expected error but got nil")
	}
}
