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

package protoio

import (
	"bufio"
	"context"
	"io"
	"iter"

	"github.com/GoogleCloudPlatform/finance-research-risk-examples/examples/risk/agent/gcp"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"
)

// ReadLines (text)
func ReadLines(ctxt context.Context, google *gcp.GoogleConfig, input string) iter.Seq2[[]byte, error] {
	return func(yield func(msg []byte, err error) bool) {

		r, err := google.OpenReader(ctxt, input)
		if err != nil {
			yield(nil, err)
			return
		}
		defer r.Close()

		reader := bufio.NewReader(r)

		for ctxt.Err() == nil {
			msg, err := reader.ReadString('\n')
			if err != nil {
				if err != io.EOF {
					yield(nil, err)
				}
				return
			}
			if !yield([]byte(msg), nil) {
				return
			}
		}
	}
}

// WriteLines (text)
func WriteLines(ctxt context.Context, google *gcp.GoogleConfig, src iter.Seq2[[]byte, error], output string) error {
	w, err := google.CreateWriter(ctxt, output)
	if err != nil {
		return err
	}
	defer w.Close()

	for msg, err := range src {
		if err != nil {
			return err
		}
		_, err = w.Write(msg)
		if err != nil {
			return err
		}
		_, err = w.Write([]byte{'\n'})
		if err != nil {
			return err
		}
	}

	return nil
}

// Read as Proto messages
func ReadProto(ctxt context.Context, google *gcp.GoogleConfig, desc protoreflect.MessageDescriptor, input string) iter.Seq2[proto.Message, error] {
	return MapIterErr(ReadLines(ctxt, google, input), JSONToProto(desc))
}

// Read as Proto messages as bytes
func ReadProtoBytes(ctxt context.Context, google *gcp.GoogleConfig, desc protoreflect.MessageDescriptor, input string) iter.Seq2[[]byte, error] {
	return MapIterErr(ReadLines(ctxt, google, input), JSONToProtoBytes(desc))
}

// Write as Proto messages
func WriteProto(ctxt context.Context, google *gcp.GoogleConfig, src iter.Seq2[proto.Message, error], output string) error {
	return WriteLines(ctxt, google, MapIterErr(src, ProtoToJSON()), output)
}

// Map input to output through a filter, aborting on any error
func MapIterErr[I any, O any](input iter.Seq2[I, error], filterFunc func(I) (O, error)) iter.Seq2[O, error] {
	return func(yield func(o O, err error) bool) {
		var empty O
		for i, err := range input {
			if err != nil {
				yield(empty, err)
				return
			}
			o, err := filterFunc(i)
			if err != nil {
				yield(empty, err)
				return
			}
			if !yield(o, nil) {
				return
			}
		}
	}
}
