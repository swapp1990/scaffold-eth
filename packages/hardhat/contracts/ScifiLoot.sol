pragma solidity >=0.6.0 <0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LootMetadataSvg.sol";

contract ScifiLoot is ERC721, Ownable {
	using Counters for Counters.Counter;
  	Counters.Counter private _tokenIds;

	string[] categories = [
		"WEAPON",
		"PILL",
		"VEHICLE",
		"DEFFENSE"
	];
	
	struct ScifiLoot {
		uint256 tokenId;
		uint256 alienId;
		string alienName;
		uint256 category; 
		bool exists;
	}

	mapping (uint256 => ScifiLoot) public lootItems;
	mapping (uint256 => bool) public deadAliens;

	event LootMinted(uint256 tokenId, uint256 rand);

	constructor() public ERC721("ScifiLoot", "SFL") {

  	}

	function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

	function mintLoot(uint256 alienId, string memory alienName)
		public
		returns (uint256) {
			require(deadAliens[alienId] == false, "Already minted!");
			_tokenIds.increment();
			uint256 id = _tokenIds.current();
     		_mint(msg.sender, id);
			ScifiLoot storage loot = lootItems[id];
			loot.tokenId = id;
			loot.alienId = alienId;
			loot.alienName = alienName;
			loot.exists = true;
			deadAliens[alienId] = true;

			uint256 rand = random(string(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) )));
			uint256 catIdx = rand % categories.length;

			loot.category = catIdx;

			emit LootMinted(_tokenIds.current(), rand);
			return id;
		}
	
	function tokenURI(uint256 id) public view override returns (string memory) {
		require(_exists(id), "not exist");
		ScifiLoot storage a = lootItems[id];
		return LootMetadataSvg.tokenURI( ownerOf(id), id, a.alienName, categories[a.category] );
	}
}