name = zigwm

files = src/main.zig

.PHONY: build
build:
	zig build

.PHONY: run
run:
	./zig-out/bin/$(name)

.PHONY: test
test:
	zig test $(files)

.PHONY: all
all:
	zig build && zig test $(files)

.PHONY: clean
clean:
	rm -rf zig-out .zig-cache