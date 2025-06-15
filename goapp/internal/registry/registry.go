// Assisted by GenAI

package registry

// Contributor TODO: import your package here
import (
	"github.com/openshift/managed-scripts/goapp/internal/cli"
	pods "github.com/openshift/managed-scripts/goapp/pkg/ceepod"
	nodes "github.com/openshift/managed-scripts/goapp/pkg/srepnode"
	"github.com/openshift/managed-scripts/goapp/pkg/utils"
)

// Contributor TODO: register your module here.
// clientFn provides a kube client, you can use it if your code needs to interact with the cluster.
func NewRegistry(clientFn utils.ClientFactoryFunc) map[string]cli.CommandModule {
	return map[string]cli.CommandModule{
		"getnodes": nodes.NewNodeModule(clientFn),
		"getpods":  pods.NewPodModule(clientFn),
	}
}
