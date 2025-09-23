//go:generate bash -c "cd ../../assets && npm ci && npm run build"

package rage_server

import (
	"context"
	"embed"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"html/template"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	"github.com/gorilla/mux"

	"bi/pkg/rage"
)

//go:embed templates/*.html
var templateFS embed.FS

type RageServer struct {
	rageDir   string
	port      int
	templates *template.Template
	rageFiles []RageFileInfo
	watcher   *fsnotify.Watcher
}

type RageFileInfo struct {
	Filename  string
	Timestamp time.Time
	Size      int64
}

func NewRageServer(rageDir string, port int) *RageServer {
	return &RageServer{
		rageDir: rageDir,
		port:    port,
	}
}

func (s *RageServer) Start(ctx context.Context) error {
	// Initialize templates
	if err := s.initTemplates(); err != nil {
		return fmt.Errorf("failed to initialize templates: %w", err)
	}

	// Initialize file watcher
	if err := s.initWatcher(); err != nil {
		return fmt.Errorf("failed to initialize file watcher: %w", err)
	}
	defer s.watcher.Close()

	// Initial scan of rage files
	s.scanRageFiles()

	// Set up HTTP routes
	router := mux.NewRouter()

	// Static assets - try to find assets directory
	assetsDir := s.findAssetsDir()
	if assetsDir != "" {
		router.PathPrefix("/static/").Handler(http.StripPrefix("/static/", s.staticFileHandler(assetsDir)))
	}

	// Rage viewer routes
	router.HandleFunc("/", s.handleIndex).Methods("GET")
	router.HandleFunc("/rage/{filename}", s.handleRageDetail).Methods("GET")
	router.HandleFunc("/rage/{filename}/pods", s.handlePods).Methods("GET")
	router.HandleFunc("/rage/{filename}/networking", s.handleNetworking).Methods("GET")
	router.HandleFunc("/rage/{filename}/logs", s.handleLogs).Methods("GET")

	server := &http.Server{
		Addr:    fmt.Sprintf(":%d", s.port),
		Handler: router,
	}

	// Start file watcher in background
	go s.watchFiles(ctx)

	return server.ListenAndServe()
}

func (s *RageServer) initTemplates() error {
	tmplFuncs := template.FuncMap{
		"formatTime": func(t time.Time) string {
			return t.Format("2006-01-02 15:04:05")
		},
		"formatSize": func(size int64) string {
			if size < 1024 {
				return fmt.Sprintf("%d B", size)
			} else if size < 1024*1024 {
				return fmt.Sprintf("%.1f KB", float64(size)/1024)
			} else {
				return fmt.Sprintf("%.1f MB", float64(size)/(1024*1024))
			}
		},
		"div": func(a, b float64) float64 {
			if b == 0 {
				return 0
			}
			return a / b
		},
		"dir": func(path string) string {
			return filepath.Dir(path)
		},
		"base": func(path string) string {
			return filepath.Base(path)
		},
		"urlEncode": func(s string) string {
			return base64.URLEncoding.EncodeToString([]byte(s))
		},
	}

	var err error
	s.templates, err = template.New("").Funcs(tmplFuncs).ParseFS(templateFS, "templates/*.html")
	return err
}

func (s *RageServer) initWatcher() error {
	var err error
	s.watcher, err = fsnotify.NewWatcher()
	if err != nil {
		return err
	}

	// Create rage directory if it doesn't exist
	if err := os.MkdirAll(s.rageDir, 0755); err != nil {
		return err
	}

	// Add the main directory and all subdirectories to the watcher
	err = filepath.WalkDir(s.rageDir, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return nil // Skip directories we can't read
		}

		if d.IsDir() {
			return s.watcher.Add(path)
		}

		return nil
	})

	return err
}

func (s *RageServer) watchFiles(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case event, ok := <-s.watcher.Events:
			if !ok {
				return
			}
			if event.Op&fsnotify.Create == fsnotify.Create || event.Op&fsnotify.Write == fsnotify.Write {
				if strings.HasSuffix(event.Name, ".json") {
					s.scanRageFiles()
				} else if event.Op&fsnotify.Create == fsnotify.Create {
					// Check if a new directory was created and add it to the watcher
					if info, err := os.Stat(event.Name); err == nil && info.IsDir() {
						s.watcher.Add(event.Name)
					}
				}
			}
		case err, ok := <-s.watcher.Errors:
			if !ok {
				return
			}
			fmt.Printf("File watcher error: %v\n", err)
		}
	}
}

func (s *RageServer) scanRageFiles() {
	var files []RageFileInfo

	// Recursively walk the directory tree to find all JSON files
	err := filepath.WalkDir(s.rageDir, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			// Skip directories we can't read
			return nil
		}

		// Skip directories
		if d.IsDir() {
			return nil
		}

		// Only process JSON files
		if !strings.HasSuffix(d.Name(), ".json") {
			return nil
		}

		info, err := d.Info()
		if err != nil {
			return nil
		}

		// Use relative path from the rage directory for display
		relPath, err := filepath.Rel(s.rageDir, path)
		if err != nil {
			relPath = d.Name()
		}

		files = append(files, RageFileInfo{
			Filename:  relPath,
			Timestamp: info.ModTime(),
			Size:      info.Size(),
		})

		return nil
	})

	if err != nil {
		fmt.Printf("Error walking rage directory: %v\n", err)
		return
	}

	// Sort by timestamp, newest first
	sort.Slice(files, func(i, j int) bool {
		return files[i].Timestamp.After(files[j].Timestamp)
	})

	s.rageFiles = files
}

func (s *RageServer) loadRageReport(filename string) (*rage.RageReport, error) {
	fullPath := filepath.Join(s.rageDir, filename)
	data, err := os.ReadFile(fullPath)
	if err != nil {
		return nil, err
	}

	var report rage.RageReport
	if err := json.Unmarshal(data, &report); err != nil {
		return nil, err
	}

	return &report, nil
}

func (s *RageServer) handleIndex(w http.ResponseWriter, r *http.Request) {
	data := struct {
		RageFiles []RageFileInfo
	}{
		RageFiles: s.rageFiles,
	}

	if err := s.templates.ExecuteTemplate(w, "index.html", data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (s *RageServer) handleRageDetail(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	encodedFilename := vars["filename"]

	filenameBytes, err := base64.URLEncoding.DecodeString(encodedFilename)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid filename encoding: %v", err), http.StatusBadRequest)
		return
	}
	filename := string(filenameBytes)

	report, err := s.loadRageReport(filename)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to load rage report: %v", err), http.StatusNotFound)
		return
	}

	data := struct {
		Filename string
		Report   *rage.RageReport
	}{
		Filename: filename,
		Report:   report,
	}

	if err := s.templates.ExecuteTemplate(w, "rage_detail.html", data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (s *RageServer) handlePods(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	encodedFilename := vars["filename"]

	filenameBytes, err := base64.URLEncoding.DecodeString(encodedFilename)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid filename encoding: %v", err), http.StatusBadRequest)
		return
	}
	filename := string(filenameBytes)

	report, err := s.loadRageReport(filename)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to load rage report: %v", err), http.StatusNotFound)
		return
	}

	data := struct {
		Filename string
		Report   *rage.RageReport
	}{
		Filename: filename,
		Report:   report,
	}

	if err := s.templates.ExecuteTemplate(w, "pods.html", data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (s *RageServer) handleNetworking(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	encodedFilename := vars["filename"]

	filenameBytes, err := base64.URLEncoding.DecodeString(encodedFilename)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid filename encoding: %v", err), http.StatusBadRequest)
		return
	}
	filename := string(filenameBytes)

	report, err := s.loadRageReport(filename)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to load rage report: %v", err), http.StatusNotFound)
		return
	}

	data := struct {
		Filename string
		Report   *rage.RageReport
	}{
		Filename: filename,
		Report:   report,
	}

	if err := s.templates.ExecuteTemplate(w, "networking.html", data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (s *RageServer) handleLogs(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	encodedFilename := vars["filename"]

	filenameBytes, err := base64.URLEncoding.DecodeString(encodedFilename)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid filename encoding: %v", err), http.StatusBadRequest)
		return
	}
	filename := string(filenameBytes)

	report, err := s.loadRageReport(filename)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to load rage report: %v", err), http.StatusNotFound)
		return
	}

	data := struct {
		Filename string
		Report   *rage.RageReport
	}{
		Filename: filename,
		Report:   report,
	}

	if err := s.templates.ExecuteTemplate(w, "logs.html", data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (s *RageServer) staticFileHandler(dir string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Get the file extension and set appropriate MIME type
		ext := filepath.Ext(r.URL.Path)
		switch ext {
		case ".js":
			w.Header().Set("Content-Type", "application/javascript; charset=utf-8")
		case ".css":
			w.Header().Set("Content-Type", "text/css; charset=utf-8")
		case ".html":
			w.Header().Set("Content-Type", "text/html; charset=utf-8")
		default:
			// For other files, try to detect MIME type
			if mimeType := mime.TypeByExtension(ext); mimeType != "" {
				w.Header().Set("Content-Type", mimeType)
			}
		}

		// Serve the file
		http.FileServer(http.Dir(dir)).ServeHTTP(w, r)
	})
}

func (s *RageServer) findAssetsDir() string {
	// Try different possible locations for assets
	candidates := []string{
		"assets/dist",
		"../../../assets/dist",
		"/home/elliott/Code/batteries-included/bi/assets/dist",
	}

	for _, dir := range candidates {
		if _, err := os.Stat(dir); err == nil {
			return dir
		}
	}

	return ""
}
