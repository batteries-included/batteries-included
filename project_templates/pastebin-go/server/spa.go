package server

import (
	"net/http"
	"os"
	"path/filepath"

	"github.com/gorilla/handlers"
)

func (app App) SPAHandler(w http.ResponseWriter, r *http.Request) {
	path := filepath.Join(app.staticPath, filepath.Clean(r.URL.Path))

	fi, err := os.Stat(path)
	if os.IsNotExist(err) || fi.IsDir() {
		http.ServeFile(w, r, filepath.Join(app.staticPath, app.indexPath))
		return
	}

	if err != nil {
		// if we got an error (that wasn't that the file doesn't exist) stating the
		// file, return a 500 internal server error and stop
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// otherwise, use http.FileServer to serve the static file
	handlers.CompressHandler(http.FileServer(http.Dir(app.staticPath))).ServeHTTP(w, r)
}
