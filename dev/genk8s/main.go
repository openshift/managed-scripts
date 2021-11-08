package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	flags "github.com/jessevdk/go-flags"
	"gopkg.in/yaml.v2"
	v1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type CliOpts struct {
	BaseImage string `short:"i" long:"image" default:"quay.io/your-user/managed-scripts" description:"Base Image" required:"false"`
}

type Metadata struct {
	Rbac     MetadataRbac `yaml:"rbac"`
	Envs     []Envs       `yaml: "envs"`
	Language string       `yaml:"language"`
	File     string       `yaml:"file"`
}

type MetadataRbac struct {
	Roles            []Roles     `yaml:"roles"`
	ClusterRoleRules []RoleRules `yaml:"clusterRoleRules"`
}

type Roles struct {
	Namespace string      `yaml:"namespace"`
	Rules     []RoleRules `yaml:"rules"`
}

type RoleRules struct {
	Verbs     []string `yaml:"verbs"`
	ApiGroups []string `yaml:"apiGroups"`
	Resources []string `yaml:"resources"`
}

type Envs struct {
	Key         string `yaml:"key"`
	Description string `yaml:"description"`
	Optional    bool   `yaml:"optional"`
}

func main() {

	opts := CliOpts{}
	args, err := flags.ParseArgs(&opts, os.Args)
	if err != nil {
		log.Fatalf("Error parsing command line options: %v", err)
	}

	if len(args) != 2 {
		log.Fatalf("Expected 1 positional argument: path to the script folder (e.g. scripts/SREP/example), got %v", os.Args)
	}
	targetScript := os.Args[1]
	yamlFile, err := ioutil.ReadFile(targetScript + "/metadata.yaml")
	if err != nil {
		log.Fatalf("Error reading metadata yaml: %v ", err)
	}
	metadata := Metadata{}
	err = yaml.Unmarshal(yamlFile, &metadata)
	if err != nil {
		log.Fatalf("Error reading metadata: %v", err)
	}

	yamls := []string{}

	ns := createNamespace(metadata, opts, targetScript)
	nsYaml, err := json.MarshalIndent(ns, "", "  ")
	if err != nil {
		log.Fatalf("Error generating namespace yaml: %v", err)
	}
	yamls = append(yamls, string(nsYaml))

	serviceAccount := createServiceAccount(metadata, opts, targetScript)
	saYaml, err := json.MarshalIndent(serviceAccount, "", "  ")
	if err != nil {
		log.Fatalf("Error generating serviceaccount yaml: %v", err)
	}
	yamls = append(yamls, string(saYaml))

	clusterRole := createClusterRole(metadata, opts, targetScript)
	clusterRoleYaml, err := json.MarshalIndent(clusterRole, "", "  ")
	if err != nil {
		log.Fatalf("Error generating clusterrole yaml: %v", err)
	}
	yamls = append(yamls, string(clusterRoleYaml))

	roles := createRoles(metadata, opts, targetScript)
	for _, role := range roles {
		roleYaml, err := json.MarshalIndent(role, "", "  ")
		if err != nil {
			log.Fatalf("Error generating role yaml: %v", err)
		}
		yamls = append(yamls, string(roleYaml))
	}

	roleBindings := createRoleBindings(serviceAccount, roles)
	for _, rb := range roleBindings {
		rbYaml, err := json.MarshalIndent(rb, "", "  ")
		if err != nil {
			log.Fatalf("Error generating rolebinding yaml: %v", err)
		}
		yamls = append(yamls, string(rbYaml))
	}

	clusterRoleBinding := createClusterRoleBinding(serviceAccount, clusterRole)
	clusterRoleBindingYaml, err := json.MarshalIndent(clusterRoleBinding, "", "  ")
	if err != nil {
		log.Fatalf("Error generating clusterrolebinding yaml: %v", err)
	}
	yamls = append(yamls, string(clusterRoleBindingYaml))

	job := createJob(metadata, opts, serviceAccount, targetScript)
	jobYaml, err := json.MarshalIndent(job, "", "  ")
	if err != nil {
		log.Fatalf("Error generating job yaml: %v", err)
	}
	yamls = append(yamls, string(jobYaml))

	for _, yaml := range yamls {
		fmt.Println("---")
		fmt.Println(yaml)
	}
}

func createServiceAccount(metadata Metadata, options CliOpts, script string) v1.ServiceAccount {
	return v1.ServiceAccount{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "v1",
			Kind:       "ServiceAccount",
		},
		ObjectMeta: metav1.ObjectMeta{
			Namespace: "backplane-dev",
			Name:      "managed-script-" + metadata.GetScriptName(script),
		},
	}
}

func createJob(metadata Metadata, options CliOpts, serviceAccount v1.ServiceAccount, script string) v1.Pod {
	envs := []v1.EnvVar{}
	for _, env := range metadata.Envs {
		val := os.Getenv(env.Key)
		if val == "" && !env.Optional {
			log.Fatalf("Environment variable not set but mandatory: %s", env.Key)
		}
		if val == "" {
			continue
		}
		envs = append(envs, v1.EnvVar{
			Name:  env.Key,
			Value: val,
		})
	}
	return v1.Pod{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "v1",
			Kind:       "Pod",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      metadata.GetScriptName(script) + "-pod",
			Namespace: "backplane-dev",
		},
		Spec: v1.PodSpec{
			ServiceAccountName: serviceAccount.Name,
			RestartPolicy:      v1.RestartPolicyNever,
			Containers: []v1.Container{
				{
					Name:    "job",
					Image:   options.BaseImage,
					Command: metadata.GetPodCommand(script),
					Env:     envs,
				},
			},
			Affinity: &v1.Affinity{
				NodeAffinity: &v1.NodeAffinity{
					PreferredDuringSchedulingIgnoredDuringExecution: []v1.PreferredSchedulingTerm{
						{
							Weight: 100,
							Preference: v1.NodeSelectorTerm{
								MatchExpressions: []v1.NodeSelectorRequirement{{
									Key:      "node-role.kubernetes.io/infra",
									Operator: "Exists",
								}},
							}},
					},
				},
			},
			Tolerations: []v1.Toleration{{
				Key:      "node-role.kubernetes.io/infra",
				Operator: "Exists",
				Value:    "",
				Effect:   "NoSchedule",
			}},
		},
	}
}

func (m *Metadata) GetPodCommand(script string) []string {
	filePath := fmt.Sprintf("/managed-scripts/" + strings.Replace(script, "scripts", "", 1) + "/" + m.File)
	if m.Language == "bash" {
		return []string{"/bin/bash", filePath}
	}
	if m.Language == "python" {
		return []string{"/bin/python3", filePath}
	}
	return []string{}
}

func createNamespace(metadata Metadata, options CliOpts, script string) v1.Namespace {
	return v1.Namespace{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "v1",
			Kind:       "Namespace",
		},

		ObjectMeta: metav1.ObjectMeta{
			Name: "backplane-dev",
		},
	}

}

func createRoles(metadata Metadata, options CliOpts, script string) []rbacv1.Role {
	roles := []rbacv1.Role{}
	for i, role := range metadata.Rbac.Roles {
		roles = append(roles, rbacv1.Role{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "rbac.authorization.k8s.io/v1",
				Kind:       "Role",
			},
			ObjectMeta: metav1.ObjectMeta{
				Namespace: role.Namespace,
				Name:      fmt.Sprintf("managed-script-%s-%d", metadata.GetScriptName(script), i),
			},
			Rules: MetadataToPolicyRules(role.Rules),
		})
	}
	return roles

}

func createClusterRole(metadata Metadata, options CliOpts, script string) rbacv1.ClusterRole {
	return rbacv1.ClusterRole{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "rbac.authorization.k8s.io/v1",
			Kind:       "ClusterRole",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name: fmt.Sprintf("managed-script-%s-clusterrole", metadata.GetScriptName(script)),
		},
		Rules: MetadataToPolicyRules(metadata.Rbac.ClusterRoleRules),
	}
}

func createRoleBindings(sa v1.ServiceAccount, roles []rbacv1.Role) []rbacv1.RoleBinding {
	rbs := []rbacv1.RoleBinding{}
	for _, r := range roles {

		rbs = append(rbs, rbacv1.RoleBinding{
			TypeMeta: metav1.TypeMeta{
				APIVersion: "rbac.authorization.k8s.io/v1",
				Kind:       "RoleBinding",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      r.Name + "-" + sa.Name,
				Namespace: r.Namespace,
			},
			Subjects: []rbacv1.Subject{{
				Kind:      sa.Kind,
				Namespace: sa.Namespace,
				Name:      sa.Name,
			}},
			RoleRef: rbacv1.RoleRef{
				Kind: r.Kind,
				Name: r.Name,
			},
		})
	}
	return rbs
}

func createClusterRoleBinding(sa v1.ServiceAccount, role rbacv1.ClusterRole) rbacv1.ClusterRoleBinding {
	return rbacv1.ClusterRoleBinding{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "rbac.authorization.k8s.io/v1",
			Kind:       "ClusterRoleBinding",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      role.Name + "-" + sa.Name,
			Namespace: role.Namespace,
		},
		Subjects: []rbacv1.Subject{{
			Kind:      sa.Kind,
			Namespace: sa.Namespace,
			Name:      sa.Name,
		}},
		RoleRef: rbacv1.RoleRef{
			Kind: role.Kind,
			Name: role.Name,
		},
	}
}

func MetadataToPolicyRules(rules []RoleRules) []rbacv1.PolicyRule {

	policyRules := []rbacv1.PolicyRule{}
	for _, r := range rules {
		policyRules = append(policyRules, rbacv1.PolicyRule(rbacv1.PolicyRule{
			Verbs:     r.Verbs,
			APIGroups: r.ApiGroups,
			Resources: r.Resources,
		}))
	}

	return policyRules
}

func (m Metadata) GetScriptName(script string) string {
	dir := filepath.Dir(script)
	return filepath.Base(dir)
}
