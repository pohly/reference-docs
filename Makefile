# To generate docs with Makefile targets
# from this repo base directory,
# set the following environment variables
# to match your environment and release version
#
# WEBROOT=~/src/github.com/kubernetes/website
# K8SROOT=~/k8s/src/k8s.io/kubernetes
# K8S_RELEASE=1.17

WEBROOT=${K8S_WEBROOT}
K8SROOT=${K8S_ROOT}
K8SRELEASE=${K8S_RELEASE}

APISRC=gen-apidocs
APIDST=$(WEBROOT)/static/docs/reference/generated/kubernetes-api/v$(K8SRELEASE)

CLISRC=gen-kubectldocs/generators/build
CLIDST=$(WEBROOT)/static/docs/reference/generated/kubectl
CLISRCFONT=$(CLISRC)/node_modules/font-awesome
CLIDSTFONT=$(CLIDST)/node_modules/font-awesome

default:
	@echo "Support commands:\ncli api comp copycli copyapi updateapispec"

# create directories for new release
createversiondirs:
	@echo "Calling set_version_dirs.sh"
	./set_version_dirs.sh
	@echo "$(K8SRELEASE)" | sed "s/\./_/g" > "release.tmp"

# Build kubectl docs
cleancli:
	sudo rm -f main
	sudo rm -rf $(shell pwd)/gen-kubectldocs/generators/includes
	sudo rm -rf $(shell pwd)/gen-kubectldocs/generators/build
	sudo rm -rf $(shell pwd)/gen-kubectldocs/generators/manifest.json

cli: cleancli
	go run gen-kubectldocs/main.go --kubernetes-version v$(shell cat "release.tmp")
	docker run -v $(shell pwd)/gen-kubectldocs/generators/includes:/source -v $(shell pwd)/gen-kubectldocs/generators/build:/build -v $(shell pwd)/gen-kubectldocs/generators/:/manifest pwittrock/brodocs

copycli: cli
	cp gen-kubectldocs/generators/build/index.html $(WEBROOT)/static/docs/reference/generated/kubectl/kubectl-commands.html
	cp gen-kubectldocs/generators/build/navData.js $(WEBROOT)/static/docs/reference/generated/kubectl/navData.js
	cp $(CLISRC)/scroll.js $(CLIDST)/scroll.js
	cp $(CLISRC)/stylesheet.css $(CLIDST)/stylesheet.css
	cp $(CLISRC)/tabvisibility.js $(CLIDST)/tabvisibility.js
	cp $(CLISRC)/node_modules/bootstrap/dist/css/bootstrap.min.css $(CLIDST)/node_modules/bootstrap/dist/css/bootstrap.min.css
	cp $(CLISRC)/node_modules/highlight.js/styles/default.css $(CLIDST)/node_modules/highlight.js/styles/default.css
	cp $(CLISRC)/node_modules/jquery.scrollto/jquery.scrollTo.min.js $(CLIDST)/node_modules/jquery.scrollto/jquery.scrollTo.min.js
	cp $(CLISRC)/node_modules/jquery/dist/jquery.min.js $(CLIDST)/node_modules/jquery/dist/jquery.min.js
	cp $(CLISRCFONT)/css/font-awesome.min.css $(CLIDSTFONT)/css/font-awesome.min.css

# Build kube component,tool docs
cleancomp:
	rm -rf $(shell pwd)/gen-compdocs/build

comp: cleancomp
	mkdir -p gen-compdocs/build
	go run gen-compdocs/main.go gen-compdocs/build kube-apiserver
	go run gen-compdocs/main.go gen-compdocs/build kube-controller-manager
	go run gen-compdocs/main.go gen-compdocs/build cloud-controller-manager
	go run gen-compdocs/main.go gen-compdocs/build kube-scheduler
	go run gen-compdocs/main.go gen-compdocs/build kubelet
	go run gen-compdocs/main.go gen-compdocs/build kube-proxy
	go run gen-compdocs/main.go gen-compdocs/build kubeadm
	go run gen-compdocs/main.go gen-compdocs/build kubectl

# Build api docs
updateapispec: createversiondirs
	@echo "Updating swagger.json for release version $(K8SRELEASE)"
	if ! [ -f $(APISRC)/config/v$(shell cat "release.tmp")/swagger.json ]; then
		cp $(K8SROOT)/api/openapi-spec/swagger.json $(APISRC)/config/v$(shell cat "release.tmp")/swagger.json
	fi
	cp $(APISRC)/config/v$(shell cat "release.tmp")/swagger.json gen-apidocs/config/swagger.json
	# add this back
	#rm release.tmp

api: cleanapi
	go run gen-apidocs/main.go --work-dir=gen-apidocs --munge-groups=false

cleanapi:
	rm -rf $(shell pwd)/gen-apidocs/build

copyapi: api
	mkdir -p $(APIDST)
	cp $(APISRC)/build/index.html $(APIDST)/index.html
	# copy scroll.js, jquery.scrollTo.min.js and the new navData.js
	mkdir -p $(APIDST)/js
	cp $(APISRC)/build/navData.js $(APIDST)/js/
	cp $(APISRC)/static/js/* $(APIDST)/js/
	# copy stylesheet.css, bootstrap.min.css, font-awesome.min.css
	mkdir -p $(APIDST)/css
	cp $(APISRC)/static/css/* $(APIDST)/css/
	# copy fonts data
	mkdir -p $(APIDST)/fonts
	cp $(APISRC)/static/fonts/* $(APIDST)/fonts/
