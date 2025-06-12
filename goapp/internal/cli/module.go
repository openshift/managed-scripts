package cli

type CommandModule interface {
	Execute() error
}
