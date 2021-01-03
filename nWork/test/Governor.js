const Governor = artifacts.require("Governor.sol");
const nWorkToken = artifacts.require("nWorkToken.sol");

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
    let governor = null;

    it('Can deploy governance contract', async () => {
        governor = Governor.new();
        assert(true);
    });
});