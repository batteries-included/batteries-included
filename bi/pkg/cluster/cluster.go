package cluster

import (
	"context"
)

type provider interface {
	Init(context.Context) error
	Create(context.Context) error
	Destroy(context.Context) error
}
