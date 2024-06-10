package server

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gorilla/handlers"
)

func (app App) SPAHandler(w http.ResponseWriter, r *http.Request) {
	path := filepath.Join(app.BaseStaticPath, filepath.Clean(r.URL.Path))

	// If the path starts with "/api" then we can assume that the user failed to hit and api endpoint
	// and we should serve an http.Error 4040
	if strings.HasPrefix(r.URL.Path, "/api") {
		http.Error(w, "404 page not found", http.StatusNotFound)
		return
	}

	// Otherwise, do the normal spa handling
	fi, err := os.Stat(path)
	if os.IsNotExist(err) || fi.IsDir() {
		http.ServeFile(w, r, filepath.Join(app.BaseStaticPath, app.IndexPath))
		return
	}

	if err != nil {
		// if we got an error (that wasn't that the file doesn't exist) stating the
		// file, return a 500 internal server error and stop
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// otherwise, use http.FileServer to serve the static file
	handlers.CompressHandler(http.FileServer(http.Dir(app.BaseStaticPath))).ServeHTTP(w, r)
}
