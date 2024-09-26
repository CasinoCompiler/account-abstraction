include .env

install:; forge install $(filter-out $@,$(MAKECMDGOALS)) --no-commit

fork:; forge test --fork-url $(SEPOLIA_RPC)

push:; git push origin master

test:
	forge clean
	forge test

mt:
	forge test --match-test $(filter-out $@,$(MAKECMDGOALS)) -vvvv

mtxt:
	forge test --match-test $(filter-out $@,$(MAKECMDGOALS)) -vvvv >test.txt

report:
	forge coverage --report debug >debug.txt
	python3 debug_refiner.py

summary:; forge coverage --report summary >summary.txt

deploy-anvil:
	forge script script/DeployMerkleAirdrop.s.sol:DeployMerkleAirdrop --rpc-url $(ANVIL_RPC)
	
%:
	@