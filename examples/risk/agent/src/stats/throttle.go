// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package stats

import (
	"context"
	"iter"
	"runtime"
	"sync"
	"time"

	"log/slog"
)

// Wait on a WaitGroup
func Waitable(wg *sync.WaitGroup) <-chan struct{} {
	ch := make(chan struct{})
	go func() {
		wg.Wait()
		close(ch)
	}()
	return ch
}

// Throttle a sequence
//
// This will yield results to the sequence after a certain delay specified by rate (number
// of yields per second).
//
// Ramp_steps and ramp allow for a gentle increase in the rate. Ramp defines how long
// it will take to get to the full rate, while ramp_steps the number of steps to get
// there.
//
// The context is used to short-circuit any delays, but otherwise
// not used to stop the iteration.
func Throttle[V any](ctxt context.Context, seq iter.Seq2[V, error], rate float64, ramp_steps int, ramp time.Duration) iter.Seq2[V, error] {

	// Delay between operations (in nanoseconds)
	nanodelay := time.Duration(0)
	maxDelay := time.Duration(0)
	if rate > 0 {
		nanodelay = time.Duration(int64(1e9 / rate))
		slog.Debug("Minimum delay per throttle", "nanodelay", nanodelay)
	}
	if ramp > 0 {
		maxDelay = time.Duration(int64(ramp) / int64(ramp_steps))
	}

	// Start time of the loop -- used for rate throttling
	s := time.Now()
	startTime := s

	return func(yield func(val V, err error) bool) {
		for v, err := range seq {

			// Pass on error
			if err != nil {
				var empty V
				yield(empty, err)
			}

			// Capture when the activity was dispatched
			dispatchTime := time.Now()

			// Calculate next time
			if rate > 0 {

				thisDelay := nanodelay
				if ramp > 0 {
					ramp_step := (int64(s.Sub(startTime)) * int64(ramp_steps)) / int64(ramp)
					if ramp_step < int64(ramp_steps) {
						thisDelay += time.Duration(((int64(maxDelay) - int64(nanodelay)) * (int64(ramp_steps) - int64(ramp_steps))) / int64(ramp_steps))
					}
				}

				s = s.Add(thisDelay)
				if s.After(dispatchTime) {
					sleepTime := s.Sub(dispatchTime)
					select {
					case <-ctxt.Done():
					case <-time.After(sleepTime):
					}
				} else {
					s = dispatchTime
				}
			}

			// Yield it
			if !yield(v, nil) {
				return
			}
		}
	}
}

// Run the work, applied to a sequence, with a pool of parallel workers.
//
// The first error will stop the processing of new work, and, once the workers
// are all finished, the first non-nil error is returned.
//
// If there are no errors nil is returned.
func ApplyParallel[V any](seq iter.Seq2[V, error], workers int, work func(v V) error) (err error) {
	err = nil

	if workers <= 0 {
		workers = runtime.NumCPU()
	}

	err_ch := make(chan error)

	working := 0

	for v, seq_err := range seq {

		// Break early on error
		if seq_err != nil {
			err = seq_err
			break
		}

		// If at limit, pull an error first.
		if working == workers {
			last_err := <-err_ch
			if last_err != nil {
				working--
				err = last_err
				break
			}
		} else {
			working++
		}

		// Dispatch the work
		go func() {
			err := work(v)
			err_ch <- err
		}()
	}

	for working > 0 {
		last_err := <-err_ch
		working--
		if last_err != nil && err == nil {
			err = last_err
		}
	}

	return
}
