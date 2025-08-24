// Assisted by GenAI

package cli

import (
	"fmt"
	"reflect"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

type Params interface{}

type CommandModule interface {
	Name() string    // return the name of the subcommand (script).
	Summary() string // return a short summary of what this subcommand does.
	Params() Params  // return a pointer to a struct of needed parameters.
	Execute() error  // main logic goes here.
}

func WrapModule(module CommandModule) *cobra.Command {
	params := module.Params()

	cmd := &cobra.Command{
		Use:   module.Name(),
		Short: module.Summary(),
		PreRunE: func(cmd *cobra.Command, args []string) error {
			return LoadParamsFromViper(params)
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			return module.Execute()
		},
	}

	BindFlagsWithViper(cmd, params)
	return cmd
}

func BindFlagsWithViper(cmd *cobra.Command, params Params) {
	if params == nil {
		return // nothing to bind
	}

	v := reflect.ValueOf(params).Elem()
	t := v.Type()

	viper.AutomaticEnv()
	viper.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))

	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)
		flag := field.Tag.Get("flag")
		env := field.Tag.Get("env")
		usage := field.Tag.Get("usage")
		def := field.Tag.Get("default")

		if flag == "" {
			flag = strings.ToLower(field.Name)
		}
		if env == "" {
			env = strings.ToUpper(flag)
		}

		key := flag // same key for flag/env/viper

		switch field.Type.Kind() {
		case reflect.String:
			cmd.Flags().String(flag, def, usage)
			viper.BindPFlag(key, cmd.Flags().Lookup(flag))
			viper.BindEnv(key, env)
		case reflect.Bool:
			cmd.Flags().Bool(flag, def == "true", usage)
			viper.BindPFlag(key, cmd.Flags().Lookup(flag))
			viper.BindEnv(key, env)
		}
	}
}

func LoadParamsFromViper(params Params) error {
	if params == nil {
		return nil // nothing to load
	}

	v := reflect.ValueOf(params).Elem()
	t := v.Type()

	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)
		key := field.Tag.Get("flag")
		if key == "" {
			key = strings.ToLower(field.Name)
		}
		val := v.Field(i)

		switch field.Type.Kind() {
		case reflect.String:
			val.SetString(viper.GetString(key))
		case reflect.Bool:
			val.SetBool(viper.GetBool(key))
		default:
			return fmt.Errorf("unsupported param type: %s", field.Type.Kind())
		}
	}
	return nil
}
