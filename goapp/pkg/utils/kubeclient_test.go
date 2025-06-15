// Assisted by GenAI
package utils

import (
	"errors"
	"testing"

	"k8s.io/client-go/rest"
)

// mockConfigLoader is a fake implementation of ConfigLoader for testing
type mockConfigLoader struct {
	config *rest.Config
	err    error
}

func (m *mockConfigLoader) ClientConfig() (*rest.Config, error) {
	return m.config, m.err
}

func TestGetKubeClient_Success(t *testing.T) {
	loader := &mockConfigLoader{
		config: &rest.Config{Host: "https://fake-kube-api"},
	}

	client, err := GetKubeClient(loader)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if client == nil {
		t.Fatal("expected client, got nil")
	}
}

func TestGetKubeClient_Error(t *testing.T) {
	loader := &mockConfigLoader{
		err: errors.New("config error"),
	}

	_, err := GetKubeClient(loader)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
