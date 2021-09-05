
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
	uint private maxWinCount;

	struct Alien {
		uint256 tokenId;
		string name;
		uint256 wonCount;
		uint256 baseProbs;
		bool isDead;
		bool exists;
	}

	mapping (uint256 => Alien) public aliens;
	mapping (address => uint256[]) public player2deadAliens;
	mapping (address => uint256) public player2wins;

	event PlayerWon(uint256 tokenId, uint256 probs, uint256 buff);
	event AlienWon(uint256 tokenId, uint256 probs, uint256 buff);

	constructor() public ERC721("Alien", "ALN") {
		maxWinCount = 20;
  	}

	function mintAlien(string memory name, uint256 baseProbs)
		public
		returns (uint256) {
			_tokenIds.increment();
			uint256 id = _tokenIds.current();
     		_mint(msg.sender, id);
			lastTokenId = id;
			Alien storage alien = aliens[id];
			alien.tokenId = id;
			alien.name = name;
			alien.baseProbs = baseProbs;
			alien.exists = true;
			return id; 
		}

	function fightAlien(uint256 id, uint256 clientRandom) public returns(uint256) {
		uint256 rand100 = getRandom(clientRandom);
		Alien storage alien = aliens[id];
		uint256 remainProbs = 100 - alien.baseProbs;
		uint256 additionalBuff = getBuffValue(alien.wonCount, remainProbs);
		
		if(rand100 > alien.baseProbs + additionalBuff) {
			player2wins[msg.sender] = player2wins[msg.sender]+1;
			player2deadAliens[msg.sender].push(id);
			alien.isDead = true;
			emit PlayerWon(id, alien.baseProbs, additionalBuff);
		} else {
			alien.wonCount = alien.wonCount+1;
			emit AlienWon(id, alien.baseProbs, additionalBuff);
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

	function getRandomWin(uint256 clientRandom, uint256 probs) public view returns (string memory) {
		uint256 rand = random(string(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), clientRandom )));
		uint256 rand100 = rand % 100;
		if(rand100 < probs) {
			return "Won";
		} else {
			return "Loss";
		}
	}

	function getBuffValue(uint256 wonCount, uint256 remainProbs) public view returns (uint256) {
		uint256 additionalBuff = (100 * wonCount)/20;
		if(additionalBuff > 100) {
			additionalBuff = 99;
		}
		uint256 additionalBuffFinal = additionalBuff * remainProbs;
		additionalBuffFinal = (additionalBuffFinal - (additionalBuffFinal % 100))/100;

		// additionalBuff = remainProbs * additionalBuff / remainProbs;
		return additionalBuffFinal;
	}

}