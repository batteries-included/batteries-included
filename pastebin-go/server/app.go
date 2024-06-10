package server

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"gorm.io/gorm"

	"pastebin/database"
)

type App struct {
	Router         *mux.Router
	DB             *gorm.DB
	BaseStaticPath string
	IndexPath      string
	MOTD           string
}

func (a *App) Initialize() error {
	db, err := database.Connect()
	if err != nil {
		return err
	}
	a.DB = db

	router := mux.NewRouter()
	router.HandleFunc("/api/healthz", a.HealthHandler).Methods("GET")
	router.HandleFunc("/api/motd", a.MotdHandler).Methods("GET")
	router.HandleFunc("/api/paste", a.CreatePasteHandler).Methods("POST")
	router.HandleFunc("/api/paste/recent", a.RecentPastesHandler).Methods("GET")
	router.HandleFunc("/api/paste/{id}", a.GetPasteHandler).Methods("GET")
	router.PathPrefix("/").HandlerFunc(a.SPAHandler)

	a.Router = router
	return nil
}

func (a *App) Run(addr string) {
	log.Fatal(http.ListenAndServe(addr, a.Router))
}
