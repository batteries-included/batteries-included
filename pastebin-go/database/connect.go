package database

import (
	"fmt"
	"log/slog"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func Connect() (*gorm.DB, error) {
	// Connect to the database
	dsn := os.Getenv("DATABASE_URL")
	database, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})

	if err != nil {
		return nil, fmt.Errorf("failed to connect to the database: %v", err)
	}
	slog.Debug("Connected to the database")

	err = database.AutoMigrate(&Paste{})
	if err != nil {
		return nil, fmt.Errorf("failed to migrate the database: %v", err)
	}
	slog.Debug("Migrated the database")

	return database, nil
}
