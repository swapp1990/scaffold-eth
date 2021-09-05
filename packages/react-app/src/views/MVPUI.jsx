import { Button, Card, DatePicker, Divider, Input, List, Progress, Slider, Spin, Switch, Row, Col, Space } from "antd";
import React, { useEffect, useState } from "react";
import { ReactComponent as CardEx } from "../card_ex.svg";
import { useContractReader } from "../hooks";

export default function MVPUI({
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  price,
  tx,
  readContracts,
  writeContracts,
}) {
  const balance = useContractReader(readContracts, "Player", "balanceOf", [address]);
  const [imgSrc, setImgSrc] = useState(null);
  const [tokenIdx, setTokenIdx] = useState(0);
  const [playerName, setPlayerName] = useState("");
  const [playerNft, setPlayerNft] = useState(null);
  const [walletLoot, setWalletLoot] = useState([]);
  const [aliens, setAliens] = useState([]);
  const [alienSelected, setAlienSelected] = useState(null);
  const [canMint, setCanMint] = useState(null);
  const [aliensDefeated, setAliensDefeated] = useState(0);

  const init = async () => {
    updateProfile();
    updateWallet();
    updateGameScreen();

    addEventListener("ScifiLoot", "LootMinted", onLootMinted);
    addEventListener("Player", "PlayerCreated", onPlayerCreated);
    addEventListener("Alien", "PlayerWon", onPlayerWon);
    addEventListener("Alien", "AlienWon", onAlienWon);
  };

  async function getRandom() {
    const clientRandom = Math.floor(Math.random() * 100);
    const rand = await readContracts.Alien.getRandom(clientRandom);
    console.log("RANDOM ", Number(rand));
  }

  async function updateProfile() {
    const tokenId = await readContracts.Player.getTokenId(address);
    if (tokenId.toNumber() == 0) return;
    const tokenURI = await readContracts.Player.tokenURI(tokenId);
    const jsonManifestString = atob(tokenURI.substring(29));
    // console.log({ jsonManifestString });
    try {
      const jsonManifest = JSON.parse(jsonManifestString);
      console.log("jsonManifest", jsonManifest);
      setPlayerNft({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
    } catch (e) {
      console.log(e);
    }
  }

  async function updateWallet() {
    const balanceLoot = await readContracts.ScifiLoot.balanceOf(address);
    console.log(balanceLoot.toNumber());
    const walletLootUpdate = [];
    for (let tokenIndex = 0; tokenIndex < balanceLoot; tokenIndex++) {
      try {
        console.log("GEtting token index", tokenIndex);
        const tokenId = await readContracts.ScifiLoot.tokenOfOwnerByIndex(address, tokenIndex);
        console.log("tokenId", tokenId);
        const tokenURI = await readContracts.ScifiLoot.tokenURI(tokenId);
        const jsonManifestString = atob(tokenURI.substring(29));
        try {
          const jsonManifest = JSON.parse(jsonManifestString);
          //   console.log("jsonManifest", jsonManifest);
          walletLootUpdate.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
        } catch (e) {
          console.log(e);
        }
      } catch (e) {
        console.log(e);
      }
    }
    setWalletLoot(walletLootUpdate.reverse());
  }

  async function updateGameScreen() {
    const aliensMinted = await readContracts.Alien.lastTokenId();
    let killedAliens = await readContracts.Alien.getKilledAliens(address);
    // console.log({ deadAliens });
    killedAliens = killedAliens.map(d => d.toNumber());
    console.log({ killedAliens });
    setCanMint(false);
    killedAliens.forEach(async id => {
      const isLootMinted = await readContracts.ScifiLoot.deadAliens(id);
      if (!isLootMinted) {
        setCanMint(true);
        const tokenURI = await readContracts["Alien"].tokenURI(id);
        const jsonManifestString = atob(tokenURI.substring(29));
        try {
          const jsonManifest = JSON.parse(jsonManifestString);
          //   console.log("jsonManifest", jsonManifest);
          setAlienSelected({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
        } catch (e) {
          console.log(e);
        }
      }
    });
    const aliensUpdate = [];
    for (let tokenId = 1; tokenId <= aliensMinted; tokenId++) {
      try {
        if (!killedAliens.includes(tokenId)) {
          //   console.log("alien tokenId", tokenId);
          const alien = await readContracts.Alien.aliens(tokenId);
          console.log({ alien });
          if (alien.isDead) continue;
          const tokenURI = await readContracts["Alien"].tokenURI(tokenId);
          const jsonManifestString = atob(tokenURI.substring(29));
          try {
            const jsonManifest = JSON.parse(jsonManifestString);
            //   console.log("jsonManifest", jsonManifest);
            aliensUpdate.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
          } catch (e) {
            console.log(e);
          }
        }
      } catch (e) {
        console.log(e);
      }
    }
    // console.log(aliensUpdate);
    setAliens(aliensUpdate);

    const player_wins = (await readContracts.Alien.player2wins(address)).toNumber();
    console.log({ player_wins });
    setAliensDefeated(player_wins);
  }

  const addEventListener = async (contractName, eventName, callback) => {
    await readContracts[contractName].removeListener(eventName);
    readContracts[contractName].on(eventName, (...args) => {
      let eventBlockNum = args[args.length - 1].blockNumber;
      console.log(eventName);
      if (eventBlockNum >= localProvider._lastBlockNumber - 1) {
        let msg = args.pop().args;
        callback(msg);
      }
    });
  };

  function onLootMinted(msg) {
    console.log("onLootMinted ");
    updateGameScreen();
    updateWallet();
    setAlienSelected(null);
  }

  function onPlayerCreated(msg) {
    console.log("onPlayerCreated", msg);
  }

  function onPlayerWon(msg) {
    console.log("onPlayerWon", msg);
    updateGameScreen();
  }

  function onAlienWon(msg) {
    console.log("onAlienWon", msg);
    updateGameScreen();
  }

  useEffect(() => {
    if (readContracts && readContracts.Player) {
      init();
    }
  }, [readContracts]);
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
  const atob = input => {
    let str = input.replace(/=+$/, "");
    let output = "";

    if (str.length % 4 == 1) {
      throw new Error("'atob' failed: The string to be decoded is not correctly encoded.");
    }
    for (
      let bc = 0, bs = 0, buffer, i = 0;
      (buffer = str.charAt(i++));
      ~buffer && ((bs = bc % 4 ? bs * 64 + buffer : buffer), bc++ % 4)
        ? (output += String.fromCharCode(255 & (bs >> ((-2 * bc) & 6))))
        : 0
    ) {
      buffer = chars.indexOf(buffer);
    }

    return output;
  };

  const createPlayer = async () => {
    console.log({ playerName });
    if (playerName == "") return;
    const result = await tx(writeContracts.Player.mintYourPlayer(playerName));
    updateProfile();
  };

  function alienChosen(idx) {
    console.log("alienChosen ", idx);
    let foundAlien = aliens.find(a => a.id == idx);
    if (foundAlien) {
      setAlienSelected(foundAlien);
    }
  }

  function getSelectedAlienName() {
    return alienSelected.name;
  }

  async function fightAlien() {
    const clientRandom = Math.floor(Math.random() * 100);
    const probOfWin = 50;
    const result = await tx(writeContracts.Alien.fightAlien(alienSelected.id, clientRandom, probOfWin));
    // const dropAmount = await readContracts.Alien.fightAlien(alienSelected);
    // console.log(dropAmount);
    // setDropAmount(dropAmount);
  }

  async function mintLoot() {
    if (!alienSelected) {
      console.log("No alien selected!");
      return;
    }
    const result = await tx(writeContracts.ScifiLoot.mintLoot(alienSelected.id, alienSelected.name));
    console.log(result);
  }

  return (
    <>
      {!playerNft && (
        <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
          <>
            <Space>
              <Input
                placeholder="Player Name"
                onChange={e => {
                  e.target.value ? setPlayerName(e.target.value) : null;
                }}
              />
              <Button
                type={"primary"}
                onClick={() => {
                  createPlayer();
                }}
              >
                CREATE PLAYER
              </Button>
              {/* <Button
                type={"primary"}
                onClick={() => {
                  getRandom();
                }}
              >
                Random
              </Button> */}
            </Space>
          </>
        </div>
      )}
      {playerNft && (
        <div style={{ width: 820, paddingBottom: 256, marginLeft: 128 }}>
          <>
            <Space>
              <Space direction="vertical">
                <Card
                  style={{ width: 450 }}
                  title={
                    <div>
                      <span style={{ fontSize: 18, marginRight: 8 }}>{playerNft.name}</span>
                    </div>
                  }
                >
                  {/* <a href={"https://opensea.io/assets/"+(readContracts && readContracts.YourCollectible && readContracts.YourCollectible.address)+"/"+item.id} target="_blank">
                        	
                        </a> */}
                  <img src={playerNft.image} />
                  {/* <div>{item.description}</div> */}
                </Card>
                <Card title="Wallet">
                  <List
                    grid={{ gutter: 16, column: 2 }}
                    dataSource={walletLoot}
                    renderItem={item => (
                      <List.Item>
                        <Card title={item.name}>
                          <img style={{ width: 150 }} src={item.image} />
                        </Card>
                      </List.Item>
                    )}
                  />
                </Card>
              </Space>
              <Space align="baseline">
                <Card style={{ width: 750, height: 750 }} title="Game Screen">
                  <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
                    <>
                      {!canMint && (
                        <Card title="Which alien do you choose to fight?">
                          <div>Aliens Defeated: {aliensDefeated}</div>
                          {alienSelected && <span>Chosen Alien: {alienSelected.alienName}</span>}
                          <List
                            grid={{ gutter: 16, column: 3 }}
                            dataSource={aliens}
                            renderItem={(item, idx) => (
                              <List.Item>
                                <div onClick={() => alienChosen(item.id)}>
                                  <Card hoverable bordered title={item.name}>
                                    <img style={{ width: 150 }} src={item.image} />
                                  </Card>
                                </div>
                              </List.Item>
                            )}
                          />
                          {alienSelected && (
                            <Button type={"primary"} onClick={() => fightAlien()}>
                              Fight Alien
                            </Button>
                          )}
                        </Card>
                      )}
                      {canMint && (
                        <Card title="You won the fight! Grab your loot!">
                          <Button type={"primary"} onClick={() => mintLoot()}>
                            Mint Loot
                          </Button>
                        </Card>
                      )}
                    </>
                  </div>
                </Card>
              </Space>
            </Space>
          </>
        </div>
      )}
    </>
  );
}
