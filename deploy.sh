
# normal version
npx hardhat run --network bsctestnet scripts/deployToken.ts
npx hardhat verify --network bsctestnet --constructor-args TokenConstructorArguments.js 0x0Ba2070376fd2dDc3eBDc3D7E6C4bC7304e9F9ba

# proxy version
#[0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7,0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3,0x6EFF4835385b8D683431290356eE668193D18Efe,0xcF2370872F7628b3e41c3A6e30b5BA9cfE95CdF9,0x7A260df520bEFe9217EB546a3232f4Df11138423]
npx hardhat run --network bsctestnet scripts/deployProxyLIFEGAME.ts
npx hardhat verify --network bsctestnet 0x40c1b06e5d853bff4bf52d78c75e88b6c50da051

# update
npx hardhat run --network bsctestnet scripts/updateProxyLIFEGAME.ts

#-> Proxy address: 0x9F631a07B9ccd5CAA38b1A93B705DDf03dEa6ea2
#npx hardhat verify --network bsctestnet 0xb1fD03c099f7C17aA105d6dC3ABB185e58cFfd82 
#npx hardhat run --network bsctestnet scripts/updateProxyLIFEGAME.ts
