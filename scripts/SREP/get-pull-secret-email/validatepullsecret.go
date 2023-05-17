package cluster

import (
	"context"
	"fmt"

	v1 "github.com/openshift-online/ocm-sdk-go/accountsmgmt/v1"
	corev1 "k8s.io/api/core/v1"
	metaV1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func getPullSecretEmail(secret *corev1.Secret, sendServiceLog bool) (string, error) {
	dockerConfigJsonBytes, found := secret.Data[".dockerconfigjson"]
	if !found {
		// Indicates issue w/ pull-secret, so we can stop evaluating and specify a more direct course of action
		fmt.Println("Secret does not contain expected key '.dockerconfigjson'.")
		return "", nil
	}

	dockerConfigJson, err := v1.UnmarshalAccessToken(dockerConfigJsonBytes)
	if err != nil {
		return "", err
	}

	cloudOpenshiftAuth, found := dockerConfigJson.Auths()["cloud.openshift.com"]
	if !found {
		return "", nil
	}

	clusterPullSecretEmail := cloudOpenshiftAuth.Email()
	if clusterPullSecretEmail == "" {
		fmt.Printf("%v\n%v\n%v\n",
			"Couldn't extract email address from pull secret for cloud.openshift.com",
			"This can mean the pull secret is misconfigured. Please verify the pull secret manually:",
			"  oc get secret -n openshift-config pull-secret -o json | jq -r '.data[\".dockerconfigjson\"]' | base64 -d")
		return "", nil
	}
	return clusterPullSecretEmail, nil
}

func main() {
	config, err := rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}
	// creates the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	secret := &corev1.Secret{}
	secretsClient := clientset.CoreV1().Secrets("openshift-config")
	secret, err = secretsClient.Get(context.TODO(), "pull-secret", metaV1.GetOptions{})
	if err != nil {
		panic(err.Error())
	}
	//clientset.Get(context.TODO(), types.NamespacedName{Namespace: "openshift-config", Name: "pull-secret"}, secret)
	if err != nil {
		panic(err.Error())
	}

	clusterPullSecretEmail, err := getPullSecretEmail(secret, true)
	if err != nil {
		panic(err.Error())
	}

	println("Cluster Pull Secret Email: " + clusterPullSecretEmail)

	return

}
