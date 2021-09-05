
pragma solidity >=0.6.0 <0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./AlienMetadataSvg.sol";

contract Alien is ERC721, Ownable  {
	using SafeMath for uint256;
	using Counters for Counters.Counter;
  	Counters.Counter private _tokenIds;
	uint public lastTokenId;

	struct Alien {
		uint256 tokenId;
		string name;
		uint256 wonCount;
		bool isDead;
		bool exists;
	}

	mapping (uint256 => Alien) public aliens;
	mapping (address => uint256[]) public player2deadAliens;
	mapping (address => uint256) public player2wins;

	event PlayerWon(uint256 tokenId);
	event AlienWon(uint256 tokenId);

	constructor() public ERC721("Alien", "ALN") {

  	}

	function mintAlien(string memory name)
		public
		returns (uint256) {
			_tokenIds.increment();
			uint256 id = _tokenIds.current();
     		_mint(msg.sender, id);
			lastTokenId = id;
			Alien storage alien = aliens[id];
			alien.tokenId = id;
			alien.name = name;
			alien.exists = true;
			return id; 
		}

	function fightAlien(uint256 id, uint256 clientRandom, uint256 probs) public returns(uint256) {
		uint256 rand100 = getRandom(clientRandom);
		if(rand100 < probs) {
			player2wins[msg.sender] = player2wins[msg.sender]+1;
			player2deadAliens[msg.sender].push(id);
			Alien storage alien = aliens[id];
			alien.isDead = true;

			emit PlayerWon(id);
		} else {
			Alien storage alien = aliens[id];
			alien.wonCount = alien.wonCount+1;
			emit AlienWon(id);
		}
		
		return 2;
	}
	
	function tokenURI(uint256 id) public view override returns (string memory) {
		require(_exists(id), "not exist");
		Alien storage a = aliens[id];
		return AlienMetadataSvg.tokenURI( ownerOf(id), id, a.name, a.wonCount );
	}

	function getKilledAliens(address player) public view returns (uint256[] memory aliens) {
		return player2deadAliens[player];
	}

	function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

	function getRandom(uint256 clientRandom) public view returns (uint256) {
		uint256 rand = random(string(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), clientRandom )));
		uint256 catIdx = rand % 100;
		return catIdx;
	}

}