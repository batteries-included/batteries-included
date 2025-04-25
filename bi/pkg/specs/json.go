package specs

import (
	"encoding/json"
	"errors"
	"fmt"
)

const ParseErrorMessage = "failed to parse install spec: %w"

func UnmarshalJSON(data []byte) (InstallSpec, error) {
	aux := InstallSpec{}

	if err := json.Unmarshal(data, &aux); err != nil {
		return aux, fmt.Errorf(ParseErrorMessage, err)
	}
	// There have to be batteries
	if len(aux.TargetSummary.Batteries) == 0 {
		return aux, fmt.Errorf(ParseErrorMessage, errors.New("no batteries"))
	}

	// There has to be at least 1 postgres cluster
	if len(aux.TargetSummary.PostgresClusters) == 0 {
		return aux, fmt.Errorf(ParseErrorMessage, errors.New("no postgres clusters"))

	}

	return aux, nil
}
