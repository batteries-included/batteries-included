package server

import (
	"encoding/json"
	"io"
	"log"
	"net/http"

	"pastebin/database"

	uuid "github.com/satori/go.uuid"
)

func (a App) CreatePasteHandler(w http.ResponseWriter, r *http.Request) {
	// Read to request body
	defer r.Body.Close()
	body, err := io.ReadAll(r.Body)

	if err != nil {
		log.Fatalln(err)
	}

	var paste database.Paste
	json.Unmarshal(body, &paste)

	// Set ID to nil to avoid overwriting
	paste.ID = uuid.Nil

	if result := a.DB.Create(&paste); result.Error != nil {
		http.Error(w, "Failed to create paste", http.StatusInternalServerError)
		return
	}

	// Send a 201 created response
	w.Header().Add("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(paste)
}
