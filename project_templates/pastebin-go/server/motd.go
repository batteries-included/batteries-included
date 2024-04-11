package server

import (
	"encoding/json"
	"net/http"
)

func (app *App) MotdHandler(w http.ResponseWriter, r *http.Request) {

	var result = make(map[string]interface{})
	result["message"] = app.MOTD
	result["status"] = "success"

	w.Header().Add("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(result)
}
