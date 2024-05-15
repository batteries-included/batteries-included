package specs

import (
	"fmt"
	"slices"
)

func GetBatteryByType(batteries []BatterySpec, typ string) (*BatterySpec, error) {
	ix := slices.IndexFunc(batteries, func(bs BatterySpec) bool { return bs.Type == typ })
	if ix < 0 {
		return nil, fmt.Errorf("failed to find battery with type: %s", typ)
	}
	return &batteries[ix], nil
}

func GetBatteryConfigField(batteries []BatterySpec, typ, field string) (any, error) {
	b, err := GetBatteryByType(batteries, typ)
	if err != nil {
		return nil, err
	}

	cfg, ok := b.Config[field]
	if !ok {
		return nil, fmt.Errorf("no field %s in config", field)
	}
	return cfg, nil
}
