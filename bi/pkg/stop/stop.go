package stop

import "bi/pkg/specs"

func StopInstall(url string) error {
	// Get the install spec
	spec, err := specs.GetSpecFromURL(url)
	if err != nil {
		return err
	}

	err = spec.StopKubeProvider()
	if err != nil {
		return err
	}

	return nil
}
