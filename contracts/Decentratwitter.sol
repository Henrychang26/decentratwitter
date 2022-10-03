//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Decentratwitter is ERC721URIStorage {

//State Variables
uint256 public tokenCount;
uint256 public postCount;

//Mapping
mapping (uint256 => Post) public posts;
mapping (address => uint256) public profiles;

struct Post{
    uint256 id;
    string hash;
    uint256 tipAmount;
    address payable author;
}

//Events
event PostCreated(uint256 id, string hash, uint256 tipAmount, address payable author);
event PostTipped(uint256 id, string hash, uint256 tipAmount, address payable author);

    constructor() ERC721("Decentratwitter", "DAPP") {} //("Name", "Symbol")


    function mint(string memory _tokenURI) external returns(uint256){
        tokenCount++; //starts adding to token count
        _safeMint(msg.sender, tokenCount); //_safeMint function comes from ERC721 contract
        _setTokenURI(tokenCount, _tokenURI); //_tokenURI is the actual content of NFT/metadata
        setProfile(tokenCount); //automatically sets the last minted NFT as profile
        return (tokenCount); //returns the ID of newly minted token
    }

    function setProfile(uint256 _id) public {
        require(ownerOf(_id) == msg.sender, "Must own the NFT you want to select as your profile"); //ownerOf() is from ERC721

        profiles[msg.sender] = _id; //mapping address of the NFT owner to NFT id
    }

    function uploadPost(string memory _postHash) external{
        //checks that owners has an NFT
        require(balanceOf(msg.sender) > 0, "Must own a decentratwitter to post");
        // Make sure the post hash exists
        require(bytes(_postHash).length > 0, "Cannot pass an empty hash");
        //Increment post count
        tokenCount++;
        //Add post to the contract
        posts[postCount] = Post(postCount, _postHash, 0, payable(msg.sender));
        emit PostCreated(postCount, _postHash, 0, payable(msg.sender));
    }
}
