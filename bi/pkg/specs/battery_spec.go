package specs

import (
	"fmt"
	"slices"
)

func (s *InstallSpec) GetBatteryByType(typ string) (*BatterySpec, error) {
	ix := slices.IndexFunc(s.TargetSummary.Batteries, func(bs BatterySpec) bool { return bs.Type == typ })
	if ix < 0 {
		return nil, fmt.Errorf("failed to find battery with type: %s", typ)
	}
	return &s.TargetSummary.Batteries[ix], nil
}

func (s *InstallSpec) GetBatteryConfigField(typ, field string) (any, error) {
	b, err := s.GetBatteryByType(typ)
	if err != nil {
		return nil, err
	}

	cfg, ok := b.Config[field]
	if !ok {
		return nil, fmt.Errorf("no field %s in config", field)
	}
	return cfg, nil
}