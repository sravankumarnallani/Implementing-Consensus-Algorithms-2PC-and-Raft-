FROM golang:1.22 AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y protobuf-compiler

COPY proto ./proto
COPY go_decision/twopc ./twopc

WORKDIR /build/twopc

RUN go mod init twopcapp
RUN go mod tidy


RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.30.0
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0

RUN protoc --go_out=. --go-grpc_out=. --proto_path=../proto ../proto/twopc.proto

RUN go build -o /decision_participant participant.go

FROM python:3.9-slim

WORKDIR /app

COPY python_voting/participant.py .
COPY python_voting/twopc_pb2*.py .
COPY --from=builder /decision_participant .

RUN pip install grpcio grpcio-tools

EXPOSE 50051 60051

CMD ["sh", "-c", "python participant.py & ./decision_participant"]
