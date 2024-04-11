package server

import (
	"encoding/json"
	"net/http"
	"pastebin/database"

	"github.com/gorilla/mux"
	uuid "github.com/satori/go.uuid"
)

func (a App) GetPaste(w http.ResponseWriter, r *http.Request) {
	// Read dynamic id parameter
	vars := mux.Vars(r)
	id := vars["id"]
	pasteUuid, err := uuid.FromString(id)

	if err != nil {
		http.Error(w, "Invalid UUID", http.StatusBadRequest)
		return
	}

	var paste database.Paste

	if result := a.DB.First(&paste, "id = ?", pasteUuid); result.Error != nil {
		http.Error(w, "Paste not found", http.StatusNotFound)
		return
	}

	w.Header().Add("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(paste)
}
