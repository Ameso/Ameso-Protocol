const MultiSigWallet = artifacts.require("MultiSigWallet.sol");

async function shouldThrow(promise) {
    try {
        await promise;
        assert(true);
    }
    catch (err) {
        return;
    }
    assert(false, "The contract did not throw.");
}    

contract("MultiSigWallet", async addresses => {
    const [admin, user1, user2, user3, user4, _] = addresses;
    let multisigwallet = null;

    it('Multi Sig Wallet check valid requirements', async () => {
        await shouldThrow(MultiSigWallet.new([admin], 3));
        await shouldThrow(MultiSigWallet.new([], 0));
        await shouldThrow(MultiSigWallet.new([admin, user1, user2], 0));
    });

    it('Multi Sig Wallet cannot have null addresses as owner', async () => {
        await shouldThrow(MultiSigWallet.new([0], 1));
        await shouldThrow(MultiSigWallet.new([admin, user1, 0], 2));
    });

    it('Multi Sig Wallet cannot have repeat addresses as owner', async () => {
        await shouldThrow(MultiSigWallet.new([admin, admin, user1], 2));
    });

    it('Multi Sig Wallet successfully created', async () => {
        multisigwallet = await MultiSigWallet.new([admin, user1, user2], 2);
        assert(true);
    });

    it('Multi Sig adding owners work', async () => {
        // shouldn't be able to addOwner directly
        await shouldThrow(multisigwallet.addOwner(user3, {from: admin}));

        // test should be working from contract address
        let addOwnerData = multisigwallet.contract.methods.addOwner(user3).encodeABI();
        let result = await multisigwallet.submitTransaction(multisigwallet.address, 0, addOwnerData, {from: admin});
        let transId = result.receipt.logs[0].args.transactionId.toString();
        assert(transId === "0", "Invalid transaction id");

        let count = await multisigwallet.getTransactionCount(true, false);
        assert(count.toString() === "1", "Invalid number of pending transactions: " + count.toString());

        let confCount = await multisigwallet.getConfirmationCount(parseInt(transId));
        assert(confCount.toString() === "1", "Invalid number of confirmations: " + confCount.toString());
        let badConfResult = await multisigwallet.isConfirmed(transId);
        assert(!badConfResult, "Wrong confirmation status");
        
        // need user1/user2 to confirm transaction
        await multisigwallet.confirmTransaction(transId, {from: user1});
        confCount = await multisigwallet.getConfirmationCount(parseInt(transId));
        assert(confCount.toString() === "2", "Invalid number of confirmations: " + confCount.toString());

        let confResult = await multisigwallet.isConfirmed(transId);
        assert(confResult, "Confirmed");

        // execute transaction. should have multiple quorum now
        await multisigwallet.executeTransaction(transId, {from: user2});
        let ownerResults = await multisigwallet.getOwners();

        let numSame = 0;
        let correctOwners = [admin, user1, user2, user3];
        for(let i=0; i<ownerResults.length; i++){
            if(correctOwners.includes(ownerResults[i])){
                numSame++;
            }
        }

        assert(numSame === 4, "Invalid owners: " + numSame.toString());
    });

    it('Change the requirement', async () => {
        // can only be executed by wallet, so need encode abi and have majority
        let reqData = multisigwallet.contract.methods.changeRequirement(3).encodeABI();
        let result = await multisigwallet.submitTransaction(multisigwallet.address, 0, reqData);
        let transId = result.receipt.logs[0].args.transactionId.toString();
        assert(transId === "1", "invalid transaction id: " + transId);

        await multisigwallet.confirmTransaction(transId, {from: user1});
        let confCount;
        confCount = await multisigwallet.getConfirmationCount(parseInt(transId));
        assert(confCount.toString() === "2", "Invalid number of confirmations: " + confCount.toString());

        let res = await multisigwallet.required();
        assert(res.toString() === "3", "ConfirmTransaction should have executed tx once requirement is met, returned: " + res.toString())

        // once we change the requirement and met quorum, isConfirmed will be checking with the new requirement.
        // since we moved requirement from 2 -> 3 votes, the previous transaction to changeRequirements successfully executed with 2.
        // checking with isConfirmed will return false because it cannot be possibly executed again because it now requires 3 votes.
        let confResult = await multisigwallet.isConfirmed(transId);
        assert(!confResult, "Confirmed: " + confResult);
    });
});