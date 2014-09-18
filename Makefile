%_test.rb: .PHONY
	ruby $@

test: test/repository_test.rb test/payload_test.rb test/api_test.rb

setup:
	git submodule update --init

.PHONY:
