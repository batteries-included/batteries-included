package specs

import (
	"encoding/json"
	"fmt"
)

const ParseErrorMessage = "failed to parse install spec"

func UnmarshalJSON(data []byte) (InstallSpec, error) {
	aux := InstallSpec{}

	if err := json.Unmarshal(data, &aux); err != nil {
		return aux, err
	}
	// There have to be batteries
	if aux.TargetSummary.Batteries == nil {
		return aux, fmt.Errorf(ParseErrorMessage)
	}

	// There should be at least 3 batteries
	if len(aux.TargetSummary.Batteries) < 3 {
		return aux, fmt.Errorf(ParseErrorMessage)
	}

	// There have to be at least 1 postgres cluster
	if aux.TargetSummary.PostgresClusters == nil {
		return aux, fmt.Errorf(ParseErrorMessage)

	}
	if len(aux.TargetSummary.PostgresClusters) < 1 {
		return aux, fmt.Errorf(ParseErrorMessage)
	}

	return aux, nil
}

func (s *InstallSpec) MarshalJSON() ([]byte, error) {
	return json.Marshal(s)
}

func (s *StateSummarySpec) UnmarshalJSON() ([]byte, error) {
	return json.Marshal(s)
}
