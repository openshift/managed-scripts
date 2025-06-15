// Assisted by GenAI
package cli

import (
	"testing"

	"github.com/spf13/cobra"
)

func TestBindFlagsWithViper_NilParams(t *testing.T) {
	cmd := &cobra.Command{
		Use: "test-cmd",
	}

	// Prevent panic when nil is passed
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("BindFlagsWithViper panicked when params was nil: %v", r)
		}
	}()

	BindFlagsWithViper(cmd, nil)

	if cmd.Flags().HasFlags() {
		t.Errorf("expected no flags to be bound when params is nil")
	}
}

func TestLoadParamsFromViper_NilParams(t *testing.T) {
	err := LoadParamsFromViper(nil)
	if err != nil {
		t.Errorf("expected no error when loading nil params, got: %v", err)
	}
}
