%_test.rb: .PHONY
	ruby $@

test: test/repository_test.rb

setup:
	git submodule update --init

.PHONY:
