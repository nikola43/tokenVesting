import {ethers} from 'hardhat'

async function main(): Promise<string> {
    const [deployer] = await ethers.getSigners()
    if (deployer === undefined) throw new Error('Deployer is undefined.')

    //["0x2D99ABD9008Dc933ff5c0CD271B88309593aB921","0x5498BB86BC934c8D34FDA08E81D444153d0D06aD","0x6EFF4835385b8D683431290356eE668193D18Efe","0xd235eD438FB2D6Bd428F5AEdF67bc8AB03bcFB96","0x09f33F64aAADf6A02956C9732b25d42DD9c2d4bC","0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"]
    const MidasTokenGenerator = await ethers.getContractFactory('MidasTokenGenerator')
    const args = [
        "0x2D99ABD9008Dc933ff5c0CD271B88309593aB921",
        "0x5498BB86BC934c8D34FDA08E81D444153d0D06aD",
        "0x6EFF4835385b8D683431290356eE668193D18Efe",
        "0xd235eD438FB2D6Bd428F5AEdF67bc8AB03bcFB96",
        "0x09f33F64aAADf6A02956C9732b25d42DD9c2d4bC",
        "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",
    ]
    const MidasTokenGenerator_Deployed = await MidasTokenGenerator.deploy(
        args
    )
    return MidasTokenGenerator_Deployed.address;
}

main()
    .then((r: string) => {
        console.log(r);
        return r;
    })
    .catch(error => {
        console.error(error)
        process.exit(1)
    })