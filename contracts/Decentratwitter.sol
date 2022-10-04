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

    function loadPost(string memory _postHash) external{
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

    function tipPostOwner(uint256 _id) external payable {
        //make sure id is valid
        require(_id > 0 && _id <= postCount, "invalid post ID");
        //fetch the post
        Post memory _post = posts[_id];
        require(_post.author != msg.sender,"Cannot tip your own post");
        //pay the author by sending them eth
        _post.author.transfer(msg.value);
        //increment the tip amount
        _post.tipAmount += msg.value; 
        // L += R => L = L + R
        //update the image
        emit PostTipped(_id, _post.hash, _post.tipAmount, _post.author);
    }

    function getAllPosts() external view returns(Post[] memory _posts){
        _posts = new Post[](postCount); //(postCount) is the length of memory array
        //for loop through the array
        for (uint256 i = 0; i< _posts.length; i++){
            _posts[i] = posts[i + 1];
        }
        // [post2, post3, 0]
        //  0          1      2
    }
    //Fetches all of user's NFTs
    function getMyNfts() external view returns(uint256[] memory _ids){
        _ids = new uint256[] (balanceOf(msg.sender));
        // [balance1, balance2, balance3]
        uint256 currentIndex; //1 => 2
        uint256 _tokenCount= tokenCount;
        for(uint256 i = 0; i <_tokenCount; i++){
            if(ownerOf(i + 1)== msg.sender){
                _ids[currentIndex] = i +1;
                currentIndex++;
            }
        }
    }
}
