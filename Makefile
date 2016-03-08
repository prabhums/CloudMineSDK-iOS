PRETTY="gem list xcpretty -i"
NOTIFICATION_GROUP='xcodebuild'
NOTIFICATION_TITLE='iOS Lib Tests'
NOTIFICATION_MESSAGE='Tests Finished'
NOTIFICATION_ACTIVATE='com.apple.Terminal'
TERMINAL_NOTIFIER_INSTALLED=$(shell terminal-notifier | grep 'Usage')
NOTIFICATION_ERROR_MSG='You do not have terminal-notifier installed! Run `[sudo] gem install terminal-notifier` to get notifications from this script!'

# Default
build:	clean
	xcodebuild -workspace cm-ios.xcworkspace \
	-scheme libcloudmine \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
	2>&1 \
	build | xcpretty -c && exit ${PIPESTATUS[0]}


delete-test-data:
	$(eval APP_ID := $(shell [ -z $${APP_ID} ] && echo "9977f87e6ae54815b32a663902c3ca65"))
	$(eval API_KEY := $(shell [ -z $${API_KEY} ] && echo "B93006AC1B3E40209B4477383B150CF2"))
	$(eval BASE_URL := $(shell [ -z $${BASE_URL} ] && echo "https://api.cloudmine.io/"))
	-@ ruby scripts/delete_all_users.rb ${BASE_URL} ${APP_ID} ${API_KEY} true
	-@ ruby scripts/delete_all_objects.rb ${BASE_URL} ${APP_ID} ${API_KEY} true


test: delete-test-data clean
	(xcodebuild -workspace cm-ios.xcworkspace \
	-scheme libcloudmine \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
	2>&1 \
	test || exit 1) |  xcpretty -c && exit ${PIPESTATUS[0]}
	@$(MAKE) delete-test-data


jenkins:
	xcodebuild -workspace cm-ios.xcworkspace \
	-scheme libcloudmine \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
	test

clean:
	-@rm -rf Pods/
	-@rm -rf ~/Library/Developer/Xcode/DerivedData/cm-ios-*
	pod install
	xcodebuild -workspace cm-ios.xcworkspace \
	-scheme libcloudmine \
	clean | xcpretty -c && exit ${PIPESTATUS[0]}

cov:
	./ios/XcodeCoverage/cleancov
	$(MAKE) test
	./ios/XcodeCoverage/getcov
 
docs:
	-@find docs/ -name "*.md" -exec rm -rf {} \;
	git clone git@github.com:cloudmine/clairvoyance.git
	-@rsync -rtuvl --exclude=.git --delete clairvoyance/docs/3_iOS/ docs/
	-@cp clairvoyance/app/img/CMHealth-SDK-Login-Screen.png docs/
	-@rm -rf clairvoyance
.PHONY: docs

bump-patch:
	@perl -i.bak -pe 's/(\d+)(")$$/($$1+1).$$2/e if m/version\s+=\s+"\d+\.\d+\.\d+"$$/;' CloudMine.podspec 
	@rm -f CloudMine.podspec.bak
	@$(MAKE) get-version

bump-minor:
	@perl -i.bak -pe 's/(\d+)(\.\d+")$$/($$1+1).$$2/e if m/version\s+=\s+"\d+\.\d+\.\d+"$$/;' CloudMine.podspec 
	@rm -f CloudMine.podspec.bak
	@$(MAKE) get-version

bump-major:
	@perl -i.bak -pe 's/(\d+)(\.\d+\.\d+")$$/($$1+1).$$2/e if m/version\s+=\s+"\d+\.\d+\.\d+"$$/;' CloudMine.podspec 
	@rm -f CloudMine.podspec.bak
	@$(MAKE) get-version

get-version:
	$(eval VERSION := $(shell perl -lne 'print $$1 if m/^\s+s.version.*"(.*)"$$/' CloudMine.podspec))
	$(eval VERSION := 1.7.10)
	@echo ${VERSION}

tag-version: get-version
	git tag -s ${VERSION} -m "version ${VERSION}"

verify-tag: get-version
	git tag --verify ${VERSION}

push-tag-to-origin: get-version
	git push origin $VERSION

lint:
	pod --verbose lib lint
	pod --verbose spec lint

stage-next-release: bump-patch
	git commit -m"bump to ${VERSION}" CloudMine.podspec
	git push origin master

cocoapods-push: lint
	pod trunk push CloudMine.podspec
	pod trunk add-owner CloudMine tech@cloudmine.me

create-signatures: get-version
	curl https://github.com/cloudmine/CloudMineSDK-iOS/archive/${VERSION}.tar.gz -o CloudMineSDK-iOS-${VERSION}.tar.gz 1>/dev/null 2>&1
	curl https://github.com/cloudmine/CloudMineSDK-iOS/archive/${VERSION}.zip -o CloudMineSDK-iOS-${VERSION}.zip 1>/dev/null 2>&1
	gpg --armor --detach-sign CloudMineSDK-iOS-${VERSION}.tar.gz
	gpg --verify CloudMineSDK-iOS-${VERSION}.tar.gz.asc CloudMineSDK-iOS-${VERSION}.tar.gz
	-@rm -f CloudMineSDK-iOS-${VERSION}.tar.gz
	gpg --armor --detach-sign CloudMineSDK-iOS-${VERSION}.zip
	gpg --verify CloudMineSDK-iOS-${VERSION}.zip.asc CloudMineSDK-iOS-${VERSION}.zip
	-@rm -f CloudMineSDK-iOS-${VERSION}.zip

# only for the brave...
release: get-version lint tag-version verify-tag push-origin cocoapods-push create-signatures stage-next-release

