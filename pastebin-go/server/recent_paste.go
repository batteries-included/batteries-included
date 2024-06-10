package server

import (
	"encoding/json"
	"net/http"

	"pastebin/database"
)

func (a App) RecentPastesHandler(w http.ResponseWriter, r *http.Request) {
	var pastes []database.Paste

	dbResult := a.DB.Order("created_at DESC").
		Limit(5).
		Select([]string{"id", "title", "created_at"}).
		Find(&pastes)

	if dbResult.Error != nil {
		http.Error(w, "Paste not found", http.StatusNotFound)
		return
	}

	var result = make(map[string]interface{})
	result["data"] = pastes
	result["count"] = len(pastes)
	result["status"] = "success"

	w.Header().Add("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(result)
}
