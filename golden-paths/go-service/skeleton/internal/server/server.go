// Package server wires the service's HTTP surface.
package server

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Config holds everything the server needs from its environment.
type Config struct {
	ServiceName string
	Description string
	Logger      *slog.Logger
}

type server struct {
	cfg      Config
	requests *prometheus.CounterVec
	registry *prometheus.Registry
}

// New returns the service's HTTP handler.
func New(cfg Config) http.Handler {
	// A dedicated registry rather than the default one keeps metrics from
	// leaking between tests and makes the collector set explicit.
	registry := prometheus.NewRegistry()
	factory := promauto.With(registry)

	registry.MustRegister(
		prometheus.NewGoCollector(),
		prometheus.NewProcessCollector(prometheus.ProcessCollectorOpts{}),
	)

	s := &server{
		cfg:      cfg,
		registry: registry,
		requests: factory.NewCounterVec(
			prometheus.CounterOpts{
				Name: "http_requests_total",
				Help: "Total HTTP requests by route and status.",
			},
			[]string{"route", "status"},
		),
	}

	mux := http.NewServeMux()
	mux.Handle("GET /healthz", s.instrument("healthz", s.handleHealth))
	mux.Handle("GET /readyz", s.instrument("readyz", s.handleReady))
	mux.Handle("GET /", s.instrument("root", s.handleRoot))
	mux.Handle("GET /metrics", promhttp.HandlerFor(registry, promhttp.HandlerOpts{}))

	return s.recoverPanic(mux)
}

func (s *server) instrument(route string, next http.HandlerFunc) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next(rec, r)
		s.requests.WithLabelValues(route, http.StatusText(rec.status)).Inc()
	})
}

// recoverPanic keeps one bad request from taking the whole process down, which
// in Kubernetes would otherwise drop every in-flight connection on that pod.
func (s *server) recoverPanic(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				s.cfg.Logger.Error("recovered from panic", "error", err, "path", r.URL.Path)
				http.Error(w, "internal server error", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func (s *server) handleHealth(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// Readiness is separate from liveness so a warming instance is pulled from the
// load balancer rather than restarted.
func (s *server) handleReady(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (s *server) handleRoot(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{
		"service":     s.cfg.ServiceName,
		"description": s.cfg.Description,
	})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(status int) {
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}
