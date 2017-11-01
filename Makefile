FRAMEWORK_NAME = DVR

default: framework

clean:
	rm -rf Carthage
	rm -rf $(FRAMEWORK_NAME).framework.zip

framework:
	carthage build --no-skip-current
	carthage archive $(FRAMEWORK_NAME)

.PHONY: clean framework
