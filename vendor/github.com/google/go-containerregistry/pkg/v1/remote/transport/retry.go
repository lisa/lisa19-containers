// Copyright 2018 Google LLC All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package transport

import (
	"net/http"
	"time"

	"github.com/google/go-containerregistry/pkg/internal/retry"
	"k8s.io/apimachinery/pkg/util/wait"
)

// Sleep for 0.1, 0.3, 0.9, 2.7 seconds. This should cover networking blips.
var defaultBackoff = wait.Backoff{
	Duration: 100 * time.Millisecond,
	Factor:   3.0,
	Jitter:   0.1,
	Steps:    5,
}

var _ http.RoundTripper = (*retryTransport)(nil)

// retryTransport wraps a RoundTripper and retries temporary network errors.
type retryTransport struct {
	inner     http.RoundTripper
	backoff   wait.Backoff
	predicate retry.Predicate
}

// Option is a functional option for retryTransport.
type Option func(*options)

type options struct {
	backoff   wait.Backoff
	predicate retry.Predicate
}

// WithRetryBackoff sets the backoff for retry operations.
func WithRetryBackoff(backoff wait.Backoff) Option {
	return func(o *options) {
		o.backoff = backoff
	}
}

// WithRetryPredicate sets the predicate for retry operations.
func WithRetryPredicate(predicate func(error) bool) Option {
	return func(o *options) {
		o.predicate = predicate
	}
}

// NewRetry returns a transport that retries errors.
func NewRetry(inner http.RoundTripper, opts ...Option) http.RoundTripper {
	o := &options{
		backoff:   defaultBackoff,
		predicate: retry.IsTemporary,
	}

	for _, opt := range opts {
		opt(o)
	}

	return &retryTransport{
		inner:     inner,
		backoff:   o.backoff,
		predicate: o.predicate,
	}
}

func (t *retryTransport) RoundTrip(in *http.Request) (out *http.Response, err error) {
	roundtrip := func() error {
		out, err = t.inner.RoundTrip(in)
		return err
	}
	retry.Retry(roundtrip, t.predicate, t.backoff)
	return
}
