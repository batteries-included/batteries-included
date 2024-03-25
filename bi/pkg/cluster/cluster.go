package cluster

import (
	"context"
	"io"
)

type provider interface {
	Init(context.Context) error
	Create(context.Context) error
	Destroy(context.Context) error
	Outputs(context.Context, io.Writer) error
}
