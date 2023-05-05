FROM alpine:latest
RUN apk add --no-cache curl jq gawk bash
RUN mkdir -p /faros
RUN adduser -D faros
COPY faros_event.sh /faros
RUN chmod +x /faros/faros_event.sh
USER faros
ENTRYPOINT ["/faros/faros_event.sh"]
