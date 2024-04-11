package database

import (
	"time"

	uuid "github.com/satori/go.uuid"
	"gorm.io/gorm"
)

type Paste struct {
	CreatedAt time.Time `json:"created_at" gorm:"created_at"`
	UpdatedAt time.Time `json:"updated_at" gorm:"updated_at"`
	ID        uuid.UUID `json:"id" gorm:"column:id;primary_key;type:uuid"`
	Title     string    `json:"title" gorm:"column:title;not null"`
	Content   string    `json:"content" gorm:"column:content;type:text;not null"`
}

type PasteArgs struct {
	Title   string `json:"title"`
	Content string `json:"content"`
}

// BeforeCreate will set a UUID.
func (p *Paste) BeforeCreate(tx *gorm.DB) error {
	p.ID = uuid.NewV4()

	return nil
}
