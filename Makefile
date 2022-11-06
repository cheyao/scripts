export OPENLANE_IMAGE_NAME ?= efabless/openlane:2022.07.02_01.38.08
export OPENLANE_ROOT ?= /Users/ray/openlane
export PDK_ROOT ?= /Users/ray/pdk
export PDK ?= sky130B
current_dir = $(shell pwd)
ifeq ($(OS),Windows_NT)
	METHOD ?= docker
else
	UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
		METHOD = docker
	else 
		METHOD ?= docker
    endif
endif

.PHONY: all gds svg viewer preview setup

all: test

gds:
	./configure.py --create-user-config
	$(METHOD) run --rm \
        -v $(OPENLANE_ROOT):/openlane \
        -v $(PDK_ROOT):$(PDK_ROOT) \
        -v $(PWD):/work \
        -e PDK_ROOT=$(PDK_ROOT) \
        -u $(shell id -u $$USER):$(shell id -g $$USER) \
        $(OPENLANE_IMAGE_NAME) \
        /bin/bash -c "./flow.tcl -verbose 2 -overwrite -design /work/src -run_path /work/runs -tag wokwi"

svg: gds
	python3 scripts/svg.py

viewer: gds
	cp runs/wokwi/results/final/gds/*.gds tinytapeout.gds
	python3 scripts/gds2gltf.py tinytapeout.gds 

preview: svg viewer
	open http://localhost:8080/scripts/index.html http://localhost:8080/gds_render.svg
	python3 -m http.server 8080

setup:
	if [ $(METHOD) == "systemctl" ]; then systemctl enable --now --user podman.socket; export DOCKER_HOST=unix://$(XDG_RUNTIME_DIR)/podman/podman.sock; fi
	python3 -m pip install requests PyYAML gdstk numpy gdspy triangle pygltflib
	# if  [ ! -d scripts ]; then git clone https://github.com/cheyao/scripts.git; fi
	if  [ ! -d ~/caravel_user_project ]; then git clone https://github.com/efabless/caravel_user_project.git -b mpw-7a; cd ~/caravel_user_project; make setup; fi
	
clean:
	rm -rf runs gds_render.svg tinytapeout.gds tinytapeout.gds.gltf

test:
	iverilog src/video.v
	vvp -M. -mvgasim a.out
