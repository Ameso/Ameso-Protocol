const Governor = artifacts.require("Governor.sol");
const nWorkToken = artifacts.require("nWorkToken.sol");
const Treasury = artifacts.require("Treasury.sol");
const NWorkApp = artifacts.require("Treasury.sol");

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

contract("Governor", async addresses => {
    const [admin, user1, user2, user3, user4, _] = addresses;
    let nWorkInstance = null;
    let governor = null;
    let treasury = null;
    let nWorkApp = null;

    // number of tokens to give to devs
    const devAmount = 250000000;

    // number of tokens to give to treasury
    const treasuryAmount = 750000000;

    let totalSupply = devAmount + treasuryAmount;

    it('Can deploy nWorkToken', async () => {
        let canMintTime = (parseInt(Date.now()/1000, 10)) + 1;
        nWorkInstance = await nWorkToken.new(user1, user2, devAmount, treasuryAmount, canMintTime);
    });

    it('Can deploy treasury', async () => {
        // The treasury contract needs the governance contract... So first set the initial admin to the admin address.
        // Then use pendingAdmin to set the governor contract afterwards.
        treasury = await Treasury.new(admin);
    });

    it('Can deploy nWorkApp', async () => {
        nWorkApp = await NWorkApp.new(treasury.address);
    });

    it('Can deploy governance contract', async () => {
        governor = await Governor.new(treasury.address, nWorkInstance.address, nWorkApp.address);
    });

    it('Governance contract has the correct quorum: 30million', async () => {
        let quorum = await governor.quorumVotes();

        assert(quorum.toString() === "30000000", "Incorrect quorum amount: " + quorum.toString());
    });

    it('Governance contract has the correct proposal threshold', async () => {
        let threshold = await governor.proposalThreshold();

        assert(threshold.toString() === "500000", "Incorrect threshold: " + threshold.toString());
    });

    it('Test governance voting feature by changing admin for treasury to governance contract', async () => {
        // set the treasury's new admin to the governance contract

        // not proper way to do it, should raise an error
        await shouldThrow(treasury.setPendingAdmin(user1, {from:treasury.address}));
        await shouldThrow(treasury.setPendingAdmin(user1, {from:admin}));

        // the governor needs to vote to approve

    });
});