const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("Decentratwitter", function () {
  let decentratwitter, deployer, user1, user2, users;
  let URI = "SampleURI";
  let postHash = "SampleHash";

  beforeEach(async () => {
    //get signers from development accounts
    [deployer, user1, user2, ...users] = await ethers.getSigners();
    const DecentratwitterFactory = await ethers.getContract("DecentraTwitter");
    decentratwitter = DecentratwitterFactory.deploy();
    await decentratwitter.connect(user1).mint(URI);
  });

  describe("Deployment", async () => {
    it("Should track name and symbol", async () => {
      const nftName = "Decentratwitter";
      const nftSymbol = "Dapp";
      expect(await decentratwitter.name()).to.equal(nftName);
      expect(await decentratwitter.symbol()).to.equal(nftSymbol);
    });
  });
  describe("Minting NFTs", async () => {
    it("Should track each minted NFT", async () => {
      expect(await decentratwitter.tokenCount()).to.equal(1);
      expect(await decentratwitter.balanceOf(user1.address)).to.equal(1); //From ERC721 contract, shows this how NFTs this particular acct owns
      expect(await decentratwitter.tokenURI(1)).to.equal(URI);
      //user2 mints an NFT
      await decentratwitter.connect(user2).mint(URI);
      expect(await decentratwitter.tokenCount()).to.equal(2);
      expect(await decentratwitter.balanceOf(user2.address)).to.equal(1); //From ERC721 contract, shows this how NFTs this particular acct owns
      expect(await decentratwitter.tokenURI(2)).to.equal(URI);
    });
  });
  describe("Setting profiles", async () => {
    it("Should allow users to select which NFT they own to represent their profiles", async () => {
      await decentratwitter.connect(user1).mint(URI); //user1 minted ANOTHER NFT
      //by default the users profile is set to their last minted NFT
      expect(await decentratwitter.profiles(user1.address)).to.equal(2); //calling profiles function/mapping
      //user1 set profile to first minted NFT
      await decentratwitter.connect(user1).setProfile(1);
      expect(await decentratwitter.profiles(user1.address)).to.equal(1);
      //Failed case
      //user tries to set their profile to nft number 2 owned by user 1
      await expect(
        decentratwitter.connect(user2).setProfile(2) //user1 owns NFT number 2
      ).to.be.revertedWith(
        "Must own the NFT you want to select as your profile"
      );
    });
    describe("Tipping post", async () => {
      it("Should allow users to tip posts and track each posts tip amount", async () => {
        await decentratwitter.connect(user1).uploadPost(postHash); //user1 uploads a post
        //tracks user1 balance before their post get tipped
        const initAuthorBalance = await ethers.provider.getBalance(
          user1.address
        );
        const tipAmount = await ethers.utils.parseEther("1"); //tip amount = 1 ether and converting to wei
        //user2 tips user1's post
        //emits event with args
        await expect(
          decentratwitter.connect(user2).tipPostOwner(1, { value: tipAmount })
        )
          .to.emit(decentratwitter, "PostTipped")
          .withArgs(1, postHash, tipAmount, user1.address);

        //Check that tipAmount has been updated from struct
        const post = await decentratwitter.posts(1); //refers to posts struct
        expect(post.tipAmount).to.equal(tipAmount);
        //check user1 received funds
        const finalAuthorBalance = await ethers.provider.getBalance(
          user1.address
        );
        expect(finalAuthorBalance).to.equal(initAuthorBalance.add(tipAmount)); //make sure to use "add" instead of + (javascript issues)
        //fail case #1
        //user2 tries to tip a post that does not exist
        await expect(
          decentratwitter.connect(user2.address).tipPostOwner(2)
        ).to.be.revertedWith("Invalid post id");
        //fail case #2
        //user1 tries to tip their own post
        await expect(
          decentratwitter.connect(user1).tipPostOwner(1)
        ).to.be.revertedWith("Cannot tip your own post");
      });
    });
  });
});
