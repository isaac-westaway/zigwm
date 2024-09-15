name = zigwm

files = src/main.zig src/Connection.zig src/Init.zig src/Layout.zig src/Log.zig src/Window.zig src/Workspace.zig src/Xid.zig src/ZWM.zig

.PHONY: build
build:
	zig build

.PHONY: run
run:
	./zig-out/bin/$(name)

.PHONY: test
test:
	for file in $(files); do zig test $$file; done

.PHONY: clean
clean:
	rm -rf zig-out .zig-cache testlogfile.log

all: build test clean