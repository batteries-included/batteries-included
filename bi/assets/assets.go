package assets

import "embed"

//go:embed dist/js dist/css
var FS embed.FS
