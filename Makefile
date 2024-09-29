include .env

install:; forge install $(filter-out $@,$(MAKECMDGOALS)) --no-commit

fork:; forge test --fork-url $(SEPOLIA_RPC)

push:; git push origin master

test:
	forge clean
	forge test

mt:
	forge test --match-test $(filter-out $@,$(MAKECMDGOALS)) -vvvv

# Command to capture output in file with name same as %
# run: 		make mt-test_name
# *USAGE* 	Error will be returned in CLI as this is primarily used for failing tests.
#			
mt-%:
	@mkdir -p ./test/logs/
	@mkdir -p ./test/logs/fail/
	@mkdir -p ./test/logs/success/
	@forge test --match-test $* -vvvv > ./test/temp_output.txt 2>&1; \
	EXIT_CODE=$$?; \
	if [ $$EXIT_CODE -ne 0 ]; then \
		echo "\nTimestamp: $$(date '+%Y-%m-%d %H:%M:%S')" >> ./test/temp_output.txt; \
		mv ./test/temp_output.txt ./test/logs/fail/$*.txt; \
		echo "Test failed. Log saved in ./test/logs/fail/$*.txt"; \
	else \
		echo "\nTimestamp: $$(date '+%Y-%m-%d %H:%M:%S')" >> ./test/temp_output.txt; \
		mv ./test/temp_output.txt ./test/logs/success/$*.txt; \
		echo "Test passed. Log saved in ./test/logs/success/$*.txt"; \
	fi

debug:
	forge test --debug $(filter-out $@,$(MAKECMDGOALS)) -vvvv

# Command to get detailed coverage report.
report:
	forge coverage --report debug >debug.txt
	python3 debug_refiner.py

summary:; forge coverage --report summary >summary.txt

deploy-anvil:
	forge script script/DeployMerkleAirdrop.s.sol:DeployMerkleAirdrop --rpc-url $(ANVIL_RPC)
	
%:
	@