package cluster

import "encoding/json"

func newTags(environment string) (string, error) {
	t := Tags{InnerTags{Environment: environment, Managed: "true"}}
	bs, err := json.Marshal(t)
	if err != nil {
		return "", err
	}
	return string(bs), nil
}

type Tags struct {
	InnerTags `json:"tags"`
}

type InnerTags struct {
	Environment string `json:"batteriesincl.com/environment"`
	Managed     string `json:"batteriesincl.com/managed"`
}
