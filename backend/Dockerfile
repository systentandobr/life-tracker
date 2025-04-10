# Dockerfile for Life Tracker
FROM golang:1.21-alpine AS builder

# Set working directory
WORKDIR /app

# Copy go.mod and go.sum
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o /lifetracker ./cmd/server

# Final stage
FROM alpine:latest

# Add ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /lifetracker .

# Environment variables
ENV PORT=8080
ENV MONGODB_URI=mongodb://mongodb:27017
ENV SUPABASE_URL=
ENV SUPABASE_KEY=

# Expose port
EXPOSE 8080

# Run the application
CMD ["./lifetracker"]
